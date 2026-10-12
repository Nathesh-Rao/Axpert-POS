import 'dart:convert';

import 'package:flutter/services.dart';

import '../errors/data_source_failure.dart';
import '../result/result.dart';
import 'data_source.dart';

typedef MockJsonAssetLoader = Future<String> Function(String assetPath);
typedef MockJsonDecoder<T> = T Function(Object? json);

class MockJsonDataSource<T> implements DataSource<T> {
  MockJsonDataSource({
    required this.assetPath,
    required this.decode,
    MockJsonAssetLoader? loadAsset,
  }) : _loadAsset = loadAsset ?? _loadFromBundle;

  final String assetPath;
  final MockJsonDecoder<T> decode;
  final MockJsonAssetLoader _loadAsset;

  static Future<String> _loadFromBundle(String assetPath) {
    return rootBundle.loadString(assetPath);
  }

  @override
  Future<Result<T>> read() async {
    try {
      final json = await _loadAsset(assetPath);
      return Result.success(decode(jsonDecode(json)));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        DataSourceFailure(
          message: 'Mock JSON data could not be loaded.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
