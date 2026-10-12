class ApiResponse {
  const ApiResponse({
    required this.data,
    required this.headers,
    this.statusCode,
  });

  final Object? data;
  final int? statusCode;
  final Map<String, List<String>> headers;
}
