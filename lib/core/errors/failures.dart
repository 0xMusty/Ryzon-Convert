import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failure. Please check your internet.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local cached data.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class KycRequiredFailure extends Failure {
  const KycRequiredFailure([super.message = 'NIN/BVN verification (Tier 1) is required to perform this transaction.']);
}

class LimitExceededFailure extends Failure {
  const LimitExceededFailure(super.message);
}
