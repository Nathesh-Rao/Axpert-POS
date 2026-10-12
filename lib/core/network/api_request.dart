import 'api_method.dart';

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.queryParameters = const {},
    this.headers = const {},
    this.body,
  });

  final ApiMethod method;
  final String path;
  final Map<String, Object?> queryParameters;
  final Map<String, Object?> headers;
  final Object? body;
}
