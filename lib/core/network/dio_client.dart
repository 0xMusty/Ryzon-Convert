import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class DioClient {
  final Dio dio;

  DioClient({required String baseUrl, List<Interceptor>? interceptors})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
            receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
