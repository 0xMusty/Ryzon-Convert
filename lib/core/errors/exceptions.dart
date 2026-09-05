class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({this.message = 'Server error occurred', this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Network connectivity error'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Cache error'});
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}
