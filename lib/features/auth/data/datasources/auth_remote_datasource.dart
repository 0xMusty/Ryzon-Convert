import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  });

  Future<({UserModel user, String token})> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });

  Future<String> sendOtp({
    required String email,
    required String purpose, // 'REGISTRATION' or 'PASSWORD_RESET'
  });

  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
    required String purpose,
  });

  Future<bool> setPin({
    required String userId,
    required String pinCode,
  });

  Future<bool> verifyPin({
    required String userId,
    required String pinCode,
  });

  Future<bool> requestPasswordReset({
    required String email,
  });

  Future<bool> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });
}

class AuthRemoteDataSourceSupabase implements AuthRemoteDataSource {
  final SupabaseClient? _client;

  AuthRemoteDataSourceSupabase({SupabaseClient? client}) : _client = client;

  SupabaseClient get supabaseClient => _client ?? Supabase.instance.client;

  @override
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        throw const ServerException(message: 'Authentication failed: No active session');
      }

      final profileData = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userModel = UserModel(
        id: user.id,
        email: user.email ?? email,
        phone: profileData?['phone_number'] as String? ?? user.phone ?? '',
        firstName: profileData?['first_name'] as String? ?? user.userMetadata?['first_name'] as String? ?? '',
        lastName: profileData?['last_name'] as String? ?? user.userMetadata?['last_name'] as String? ?? '',
        isKycVerified: profileData?['is_kyc_verified'] as bool? ?? false,
        kycTier: (profileData?['kyc_tier'] as int? ?? 0) == 1 ? 'Tier 1' : 'Tier 0',
      );

      return (user: userModel, token: session.accessToken);
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<({UserModel user, String token})> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phone,
        },
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        throw const ServerException(message: 'User registration failed');
      }

      // Generate initial registration OTP in database
      await sendOtp(email: email, purpose: 'REGISTRATION');

      final userModel = UserModel(
        id: user.id,
        email: user.email ?? email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        isKycVerified: false,
        kycTier: 'Tier 0',
      );

      final token = session?.accessToken ?? 'session_pending_otp';

      return (user: userModel, token: token);
    } on AuthException catch (e) {
      // If user is already created in Supabase Auth, proceed to OTP generation
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('rate limit')) {
        await sendOtp(email: email, purpose: 'REGISTRATION');
        final userModel = UserModel(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          phone: phone,
          firstName: firstName,
          lastName: lastName,
          isKycVerified: false,
          kycTier: 'Tier 0',
        );
        return (user: userModel, token: 'session_pending_otp');
      }
      throw ServerException(message: e.message);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<String> sendOtp({
    required String email,
    required String purpose,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Try calling database RPC generate_email_otp
    try {
      final dynamic result = await supabaseClient.rpc(
        'generate_email_otp',
        params: {
          'p_email': cleanEmail,
          'p_purpose': purpose,
        },
      );
      final String? generatedOtp = result?.toString();
      if (generatedOtp != null && generatedOtp.isNotEmpty) {
        return generatedOtp;
      }
    } catch (_) {
      // Fallback if RPC function is unavailable
    }

    // 2. Direct database insertion into email_otps table
    try {
      // Mark existing unused OTPs for this email & purpose as used
      await supabaseClient
          .from('email_otps')
          .update({'is_used': true})
          .eq('email', cleanEmail)
          .eq('purpose', purpose)
          .eq('is_used', false);

      // Generate random 6-digit numeric OTP (100000 - 999999)
      final String otpCode = (100000 + Random().nextInt(900000)).toString();

      await supabaseClient.from('email_otps').insert({
        'email': cleanEmail,
        'otp_code': otpCode,
        'purpose': purpose,
        'expires_at': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
        'is_used': false,
        'attempts': 0,
      });

      return otpCode;
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
    required String purpose,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otpCode.trim();

    // 1. Try database RPC verify_email_otp
    try {
      final dynamic result = await supabaseClient.rpc(
        'verify_email_otp',
        params: {
          'p_email': cleanEmail,
          'p_otp_code': cleanOtp,
          'p_purpose': purpose,
        },
      );

      if (result == true) {
        return true;
      }
      // RPC returned false — OTP didn't match or expired
      throw const ServerException(message: 'Incorrect or expired OTP code. Please check and try again.');
    } on ServerException {
      rethrow;
    } catch (_) {
      // Fallback if RPC function is unavailable
    }

    // 2. Direct table verification fallback
    try {
      // First check if an OTP exists (used or expired)
      final expiredRecords = await supabaseClient
          .from('email_otps')
          .select()
          .eq('email', cleanEmail)
          .eq('purpose', purpose)
          .order('created_at', ascending: false)
          .limit(1);

      if (expiredRecords.isEmpty) {
        throw const ServerException(message: 'No OTP found for this email. Please request a new code.');
      }

      final latest = expiredRecords.first;
      final isUsed = latest['is_used'] as bool? ?? false;
      final expiresAt = DateTime.tryParse(latest['expires_at'] as String? ?? '');
      final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc());

      if (isUsed) {
        throw const ServerException(message: 'This OTP has already been used. Please request a new one.');
      }
      if (isExpired) {
        throw const ServerException(message: 'OTP has expired. Please request a new code.');
      }

      // Now check valid (unused, unexpired) records
      final records = await supabaseClient
          .from('email_otps')
          .select()
          .eq('email', cleanEmail)
          .eq('purpose', purpose)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (records.isEmpty) {
        throw const ServerException(message: 'OTP has expired. Please request a new code.');
      }

      final record = records.first;
      final storedOtp = record['otp_code'] as String?;
      final recordId = record['id'];

      if (storedOtp == cleanOtp) {
        await supabaseClient
            .from('email_otps')
            .update({'is_used': true})
            .eq('id', recordId);
        return true;
      } else {
        throw const ServerException(message: 'Incorrect OTP code. Please double-check and try again.');
      }
    } on AuthException catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    } on PostgrestException catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<bool> setPin({
    required String userId,
    required String pinCode,
  }) async {
    try {
      final bool success = await supabaseClient.rpc(
        'set_user_pin',
        params: {
          'p_user_id': userId,
          'p_pin_code': pinCode,
        },
      );
      return success;
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<bool> verifyPin({
    required String userId,
    required String pinCode,
  }) async {
    try {
      final result = await supabaseClient.rpc(
        'verify_user_pin',
        params: {
          'p_user_id': userId,
          'p_pin_code': pinCode,
        },
      );

      // RPC returns a map with success/message, or a plain bool
      if (result is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(result);
        final bool isSuccess = data['success'] as bool? ?? false;
        if (!isSuccess) {
          throw const ServerException(message: 'Incorrect PIN. Please try again.');
        }
        return true;
      } else if (result == true) {
        return true;
      } else {
        throw const ServerException(message: 'Incorrect PIN. Please try again.');
      }
    } on AuthException catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    } on PostgrestException catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    try {
      await sendOtp(email: email, purpose: 'PASSWORD_RESET');
      return true;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  @override
  Future<bool> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final bool isOtpValid = await supabaseClient.rpc(
        'reset_password_with_otp',
        params: {
          'p_email': email,
          'p_otp_code': otpCode,
        },
      );

      if (!isOtpValid) {
        throw const ServerException(message: 'Invalid or expired password reset OTP');
      }

      return true;
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: _cleanErrorMessage(e));
    }
  }

  String _cleanErrorMessage(Object error) {
    final str = error.toString();

    // Strip common Dart/exception prefixes
    String clean = str
        .replaceAll('Instance of \'ServerException\'', '')
        .replaceAll('Instance of \'AuthException\'', '')
        .replaceAll('Instance of \'PostgrestException\'', '')
        .replaceAll('ServerException: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('PostgrestException: ', '')
        .replaceAll('Exception: ', '')
        .trim();

    if (clean.isEmpty || clean.startsWith('Instance of')) {
      return 'Something went wrong. Please try again.';
    }

    // Map common Supabase / Postgres error codes to friendly messages
    final lower = clean.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email not verified')) {
      return 'Your email is not verified. Please check your inbox.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('network') || lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (lower.contains('permission denied') ||
        lower.contains('not authorized')) {
      return 'You do not have permission to perform this action.';
    }

    return clean;
  }
}
