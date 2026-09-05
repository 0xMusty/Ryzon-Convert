import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/kyc_entity.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_datasource.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remoteDataSource;

  KycRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, KycEntity>> submitTier1Kyc({
    required String idType,
    required String idNumber,
  }) async {
    try {
      final model = await remoteDataSource.submitTier1Kyc(idType: idType, idNumber: idNumber);
      return right(model);
    } on ValidationException catch (e) {
      return left(ValidationFailure(e.message));
    } catch (e) {
      return left(ServerFailure('KYC verification error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> createNinjaHostedSession({
    required String idType,
    required String idNumber,
  }) async {
    try {
      final res = await remoteDataSource.createNinjaHostedSession(idType: idType, idNumber: idNumber);
      return right(res);
    } on ValidationException catch (e) {
      return left(ValidationFailure(e.message));
    } catch (e) {
      return left(ServerFailure('Failed to generate Ninja hosted session: $e'));
    }
  }
}
