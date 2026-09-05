import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../custom_numeric_keypad.dart';
import '../pin_code_field.dart';

class ForgotPinOtpModal extends ConsumerStatefulWidget {
  const ForgotPinOtpModal({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const ForgotPinOtpModal(),
    );
  }

  @override
  ConsumerState<ForgotPinOtpModal> createState() => _ForgotPinOtpModalState();
}

class _ForgotPinOtpModalState extends ConsumerState<ForgotPinOtpModal> {
  int _step = 0; // 0: Request OTP, 1: Enter OTP, 2: New PIN, 3: Confirm PIN
  String _otp = '';
  String _newPin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _isLoading = false;

  int _secondsRemaining = 59;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    if (name.length <= 2) return '${name[0]}***@${parts[1]}';
    return '${name[0]}***${name[name.length - 1]}@${parts[1]}';
  }

  Future<void> _sendOtp() async {
    final user = ref.read(authProvider).user;
    String email = user?.email ?? '';
    if (email.isEmpty) {
      email = Supabase.instance.client.auth.currentUser?.email ?? '';
    }

    if (email.isEmpty) {
      setState(() => _errorMessage = 'User email not found. Please log in again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final sent = await ref.read(authProvider.notifier).sendOtp(
          email: email,
          purpose: 'PIN_RESET',
        );
    setState(() {
      _isLoading = false;
      if (sent) {
        _step = 1;
        _startTimer();
      } else {
        _errorMessage = ref.read(authProvider).errorMessage ??
            'Failed to send OTP. Please try again.';
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) return;
    final user = ref.read(authProvider).user;
    String email = user?.email ?? '';
    if (email.isEmpty) {
      email = Supabase.instance.client.auth.currentUser?.email ?? '';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final isValid = await ref.read(authProvider.notifier).verifyOtp(
          email: email,
          otpCode: _otp,
          purpose: 'PIN_RESET',
        );

    setState(() {
      _isLoading = false;
      if (isValid) {
        _step = 2; // Advance to New PIN step
      } else {
      _errorMessage = ref.read(authProvider).errorMessage ??
              'Incorrect OTP code. Please double-check and try again.';
      }
    });
  }

  Future<void> _saveNewPin() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _errorMessage = 'PINs do not match. Try confirming again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final user = ref.read(authProvider).user;
    final userId = user?.id ?? '';
    final success = await ref.read(authProvider.notifier).setPin(
          userId: userId,
          pinCode: _newPin,
        );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      setState(() {
        _errorMessage = ref.read(authProvider).errorMessage ??
            'Failed to reset PIN. Please try again.';
      });
    }
  }

  void _showSuccessDialog() {
    // Capture the navigator that owns PinSettingsScreen (root nav)
    final rootNav = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            SizedBox(height: 12),
            Text(
              'PIN Reset Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your new 4-digit transaction PIN has been updated in the database.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);     // close dialog
                Navigator.pop(ctx);     // close bottom sheet (modal)
                rootNav.pop();          // close PinSettingsScreen → back to Settings
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _onDigitPressed(String digit) {
    setState(() {
      _errorMessage = '';
      if (_step == 1) {
        if (_otp.length < 6) _otp += digit;
        if (_otp.length == 6) _verifyOtp();
      } else if (_step == 2) {
        if (_newPin.length < 4) _newPin += digit;
        if (_newPin.length == 4) _step = 3;
      } else if (_step == 3) {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) _saveNewPin();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      if (_step == 1 && _otp.isNotEmpty) {
        _otp = _otp.substring(0, _otp.length - 1);
      } else if (_step == 2 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 3 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final email = user?.email ?? 'your email';

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle(email),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (_step == 0) ...[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Send OTP Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ] else ...[
            if (_step == 1)
              PinCodeField(
                pin: _otp,
                length: 6,
                isObscured: false,
              )
            else if (_step == 2)
              PinCodeField(
                pin: _newPin,
                length: 4,
                isObscured: true,
              )
            else
              PinCodeField(
                pin: _confirmPin,
                length: 4,
                isObscured: true,
              ),

            if (_step == 1) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive code? ",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: _secondsRemaining == 0 ? _sendOtp : null,
                    child: Text(
                      _secondsRemaining > 0 ? 'Resend in ${_secondsRemaining}s' : 'Resend Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _secondsRemaining == 0 ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],

            const SizedBox(height: 20),

            CustomNumericKeypad(
              onDigitPressed: _onDigitPressed,
              onBackspacePressed: _onBackspace,
              showSubmitButton: false,
            ),
          ],
        ],
      ),
    );
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Reset Transaction PIN';
      case 1:
        return 'Enter 6-Digit OTP';
      case 2:
        return 'Enter New PIN';
      case 3:
        return 'Confirm New PIN';
      default:
        return '';
    }
  }

  String _subtitle(String email) {
    switch (_step) {
      case 0:
        return 'We will send a 6-digit verification code to ${_maskEmail(email)}';
      case 1:
        return 'Enter the 6-digit code sent to ${_maskEmail(email)}';
      case 2:
        return 'Create a new 4-digit security PIN';
      case 3:
        return 'Re-enter your new 4-digit security PIN';
      default:
        return '';
    }
  }
}
