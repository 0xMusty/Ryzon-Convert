import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_session_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/signup_usecase.dart';
import '../features/kyc/data/datasources/kyc_remote_datasource.dart';
import '../features/kyc/data/repositories/kyc_repository_impl.dart';
import '../features/kyc/domain/repositories/kyc_repository.dart';
import '../features/kyc/domain/usecases/submit_kyc_usecase.dart';

// Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Auth Data Sources & Repositories
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceSupabase();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

// Auth Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getSessionUseCaseProvider = Provider<GetSessionUseCase>((ref) {
  return GetSessionUseCase(ref.watch(authRepositoryProvider));
});

// KYC Data Sources, Repositories & Use Cases
final kycRemoteDataSourceProvider = Provider<KycRemoteDataSource>((ref) {
  return KycRemoteDataSourceLive();
});

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepositoryImpl(remoteDataSource: ref.watch(kycRemoteDataSourceProvider));
});

final submitKycUseCaseProvider = Provider<SubmitKycUseCase>((ref) {
  return SubmitKycUseCase(ref.watch(kycRepositoryProvider));
});
