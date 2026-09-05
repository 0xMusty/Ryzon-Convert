import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di/injection.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/usecases/submit_kyc_usecase.dart';

class KycState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const KycState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  KycState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class KycNotifier extends StateNotifier<KycState> {
  final Ref ref;

  KycNotifier(this.ref) : super(const KycState());

  Future<bool> submitTier1Kyc({
    required String idType,
    required String idNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    final submitUseCase = ref.read(submitKycUseCaseProvider);
    final res = await submitUseCase(SubmitKycParams(idType: idType, idNumber: idNumber));

    return res.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (kycEntity) async {
        state = state.copyWith(isLoading: false, isSuccess: true, clearError: true);
        // Update global auth user state to Tier 1 Verified
        await ref.read(authProvider.notifier).updateUserKycStatus(
              isVerified: true,
              tier: kycEntity.tier,
            );
        return true;
      },
    );
  }

  Future<Map<String, String>?> startNinjaHostedSession({
    required String idType,
    required String idNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    final repository = ref.read(kycRepositoryProvider);
    final res = await repository.createNinjaHostedSession(idType: idType, idNumber: idNumber);

    return res.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return null;
      },
      (sessionData) {
        state = state.copyWith(isLoading: false, clearError: true);
        return sessionData;
      },
    );
  }
}

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref);
});
