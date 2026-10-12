import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/errors/api_transport_failure.dart';
import 'package:pos_application/core/network/api_client.dart';
import 'package:pos_application/core/network/api_method.dart';
import 'package:pos_application/core/network/api_request.dart';
import 'package:pos_application/core/network/api_response.dart';
import 'package:pos_application/core/network/dio_api_client.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioApiClient', () {
    test(
      'sends a generic request and returns transport response data',
      () async {
        final adapter = _FakeHttpClientAdapter(
          body: '{"transport":"ok"}',
          statusCode: 200,
        );
        final client = DioApiClient(config: _testConfig, adapter: adapter);
        final ApiRequest request = const ApiRequest(
          method: ApiMethod.get,
          path: '/',
          queryParameters: {'check': 'transport'},
          headers: {'x-test-header': 'present'},
        );

        final Result<ApiResponse> result = await client.send(request);

        final response = result.fold(
          onSuccess: (value) => value,
          onFailure: (failure) => fail(failure.message),
        );

        expect(client, isA<ApiClient>());
        expect(response.statusCode, 200);
        expect(response.data, {'transport': 'ok'});
        expect(adapter.lastRequestOptions?.method, 'GET');
        expect(adapter.lastRequestOptions?.path, '/');
        expect(adapter.lastRequestOptions?.queryParameters, {
          'check': 'transport',
        });
        expect(adapter.lastRequestOptions?.headers['x-test-header'], 'present');
      },
    );

    test(
      'translates Dio HTTP errors without business interpretation',
      () async {
        final adapter = _FakeHttpClientAdapter(
          body: 'temporarily unavailable',
          statusCode: 503,
          contentType: 'text/plain',
        );
        final client = DioApiClient(config: _testConfig, adapter: adapter);

        final result = await client.send(
          const ApiRequest(method: ApiMethod.get, path: '/'),
        );

        result.fold(
          onSuccess: (_) =>
              fail('Expected the HTTP error to become a failure.'),
          onFailure: (failure) {
            expect(failure, isA<ApiTransportFailure>());
            expect((failure as ApiTransportFailure).statusCode, 503);
          },
        );
      },
    );

    test('constructs with an unresolved development base URL', () {
      final client = DioApiClient(config: const DevelopmentAppConfig());

      expect(client, isA<ApiClient>());
    });
  });
}

final _testConfig = DevelopmentAppConfig(
  apiBaseUrl: Uri.parse('https://transport.invalid'),
);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({
    required this.body,
    required this.statusCode,
    this.contentType = 'application/json',
  });

  final String body;
  final int statusCode;
  final String contentType;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
