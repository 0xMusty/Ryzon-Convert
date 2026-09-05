import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/kyc_entity.dart';
import '../repositories/kyc_repository.dart';

class SubmitKycParams extends Equatable {
  final String idType; // 'NIN' or 'BVN'
  final String idNumber;

  const SubmitKycParams({required this.idType, required this.idNumber});

  @override
  List<Object?> get props => [idType, idNumber];
}

class SubmitKycUseCase implements UseCase<KycEntity, SubmitKycParams> {
  final KycRepository repository;

  SubmitKycUseCase(this.repository);

  @override
  Future<Either<Failure, KycEntity>> call(SubmitKycParams params) {
    return repository.submitTier1Kyc(
      idType: params.idType,
      idNumber: params.idNumber,
    );
  }
}
