import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/api_transport_failure.dart';
import '../result/result.dart';
import 'api_client.dart';
import 'api_request.dart';
import 'api_response.dart';

class DioApiClient implements ApiClient {
  DioApiClient({required AppConfig config, HttpClientAdapter? adapter})
    : _dio = _createDio(config, adapter);

  final Dio _dio;

  static Dio _createDio(AppConfig config, HttpClientAdapter? adapter) {
    final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl?.toString() ?? ''));
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
    }
    return dio;
  }

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    try {
      final response = await _dio.request<Object?>(
        request.path,
        data: request.body,
        queryParameters: Map<String, dynamic>.from(request.queryParameters),
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: Map<String, dynamic>.from(request.headers),
        ),
      );

      return Result.success(
        ApiResponse(
          data: response.data,
          statusCode: response.statusCode,
          headers: response.headers.map,
        ),
      );
    } on DioException catch (error, stackTrace) {
      return Result.failure(
        ApiTransportFailure(
          message: 'The HTTP transport request failed.',
          statusCode: error.response?.statusCode,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(
        ApiTransportFailure(
          message: 'The HTTP transport request could not be completed.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
