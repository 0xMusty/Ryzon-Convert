import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../di/injection.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final getSession = ref.read(getSessionUseCaseProvider);
    final res = await getSession(NoParams());

    res.fold(
      (failure) => state = state.copyWith(isLoading: false),
      (user) => state = state.copyWith(user: user, isLoading: false),
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final loginUseCase = ref.read(loginUseCaseProvider);
    final res = await loginUseCase(LoginParams(email: email, password: password));

    return res.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(user: user, isLoading: false, clearError: true);
        return true;
      },
    );
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final signupUseCase = ref.read(signupUseCaseProvider);
    final res = await signupUseCase(
      SignupParams(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      ),
    );

    return res.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(user: user, isLoading: false, clearError: true);
        return true;
      },
    );
  }

  Future<bool> sendOtp({
    required String email,
    required String purpose,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      await remoteDs.sendOtp(email: email, purpose: purpose);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
    required String purpose,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final isValid = await remoteDs.verifyOtp(
        email: email,
        otpCode: otpCode,
        purpose: purpose,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return isValid;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> setPin({
    required String userId,
    required String pinCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final ok = await remoteDs.setPin(userId: userId, pinCode: pinCode);
      state = state.copyWith(isLoading: false, clearError: true);
      return ok;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyPin({
    required String userId,
    required String pinCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final ok = await remoteDs.verifyPin(userId: userId, pinCode: pinCode);
      state = state.copyWith(isLoading: false, clearError: true);
      return ok;
    } catch (e) {
      final String msg = e is ServerException ? e.message : e.toString().replaceAll('ServerException: ', '').replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase(NoParams());
    state = state.copyWith(clearUser: true, clearError: true);
  }

  Future<void> updateUserKycStatus({required bool isVerified, required String tier}) async {
    if (state.user != null) {
      final updatedEntity = state.user!.copyWith(
        isKycVerified: isVerified,
        kycTier: tier,
      );
      state = state.copyWith(user: updatedEntity);
      try {
        final userModel = UserModel.fromEntity(updatedEntity);
        final localDs = ref.read(authLocalDataSourceProvider);
        await localDs.saveUserSession(userModel);
      } catch (_) {}
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
