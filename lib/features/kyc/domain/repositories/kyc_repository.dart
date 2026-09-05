import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/kyc_entity.dart';

abstract class KycRepository {
  Future<Either<Failure, KycEntity>> submitTier1Kyc({
    required String idType,
    required String idNumber,
  });

  Future<Either<Failure, Map<String, String>>> createNinjaHostedSession({
    required String idType,
    required String idNumber,
  });
}
