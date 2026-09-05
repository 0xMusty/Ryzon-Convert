import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ryzon/core/errors/failures.dart';
import 'package:ryzon/features/kyc/domain/entities/kyc_entity.dart';
import 'package:ryzon/features/kyc/domain/repositories/kyc_repository.dart';
import 'package:ryzon/features/kyc/domain/usecases/submit_kyc_usecase.dart';

class MockKycRepository implements KycRepository {
  @override
  Future<Either<Failure, KycEntity>> submitTier1Kyc({
    required String idType,
    required String idNumber,
  }) async {
    if (idNumber.length == 11 && idNumber != '00000000000') {
      return right(KycEntity(
        idType: idType,
        idNumber: idNumber,
        isVerified: true,
        tier: 'Tier 1',
        verifiedAt: DateTime.now(),
      ));
    }
    return left(ValidationFailure('$idType verification failed. Must be an 11-digit valid number.'));
  }

  @override
  Future<Either<Failure, Map<String, String>>> createNinjaHostedSession({
    required String idType,
    required String idNumber,
  }) async {
    return right({
      'hosted_url': 'https://sandbox.ninjakyc.com/verify/test_session',
      'session_id': 'test_session',
      'environment': 'sandbox',
    });
  }
}

void main() {
  late SubmitKycUseCase submitKycUseCase;
  late MockKycRepository mockRepository;

  setUp(() {
    mockRepository = MockKycRepository();
    submitKycUseCase = SubmitKycUseCase(mockRepository);
  });

  test('should return KycEntity when submitting valid 11-digit NIN', () async {
    final result = await submitKycUseCase(const SubmitKycParams(idType: 'NIN', idNumber: '12345678901'));
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should succeed'),
      (kyc) {
        expect(kyc.isVerified, true);
        expect(kyc.tier, 'Tier 1');
        expect(kyc.idType, 'NIN');
        expect(kyc.nin, '12345678901');
      },
    );
  });

  test('should return KycEntity when submitting valid 11-digit BVN', () async {
    final result = await submitKycUseCase(const SubmitKycParams(idType: 'BVN', idNumber: '22345678901'));
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should succeed'),
      (kyc) {
        expect(kyc.isVerified, true);
        expect(kyc.tier, 'Tier 1');
        expect(kyc.idType, 'BVN');
        expect(kyc.bvn, '22345678901');
      },
    );
  });

  test('should return ValidationFailure when ID digit count is invalid', () async {
    final result = await submitKycUseCase(const SubmitKycParams(idType: 'NIN', idNumber: '12345'));
    expect(result.isLeft(), true);
  });
}
