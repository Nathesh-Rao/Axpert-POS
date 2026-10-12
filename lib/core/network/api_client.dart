import '../result/result.dart';
import 'api_request.dart';
import 'api_response.dart';

abstract interface class ApiClient {
  Future<Result<ApiResponse>> send(ApiRequest request);
}
