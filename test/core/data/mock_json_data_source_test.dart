import 'package:pos_application/core/data/data_source.dart';
import 'package:pos_application/core/data/mock_json_data_source.dart';
import 'package:pos_application/core/errors/data_source_failure.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock JSON source decodes deterministic asset content', () async {
    final source = MockJsonDataSource<FixtureDto>(
      assetPath: 'assets/mock/test/fixture.json',
      decode: FixtureDto.fromJson,
      loadAsset: _loadFixture,
    );

    final Result<FixtureDto> result = await source.read();

    final FixtureDto decoded = result.fold(
      onSuccess: (value) => value,
      onFailure: (failure) => fail(failure.message),
    );

    expect(source, isA<DataSource<FixtureDto>>());
    expect(decoded.id, 'fixture-1');
    expect(decoded.label, 'Deterministic fixture');
  });

  test('mock JSON source returns a typed failure for invalid JSON', () async {
    final source = MockJsonDataSource<FixtureDto>(
      assetPath: 'assets/mock/test/invalid.json',
      decode: FixtureDto.fromJson,
      loadAsset: _loadInvalidJson,
    );

    final result = await source.read();

    result.fold(
      onSuccess: (_) => fail('Expected invalid JSON to fail.'),
      onFailure: (failure) {
        expect(failure, isA<DataSourceFailure>());
        expect(failure.cause, isA<FormatException>());
      },
    );
  });

  test(
    'mock JSON source returns a typed failure when asset loading fails',
    () async {
      final source = MockJsonDataSource<FixtureDto>(
        assetPath: 'assets/mock/test/missing.json',
        decode: FixtureDto.fromJson,
        loadAsset: _loadMissingAsset,
      );

      final result = await source.read();

      result.fold(
        onSuccess: (_) => fail('Expected asset loading to fail.'),
        onFailure: (failure) {
          expect(failure, isA<DataSourceFailure>());
          expect(failure.cause, isA<StateError>());
        },
      );
    },
  );
}

Future<String> _loadFixture(String _) async {
  return '{"id":"fixture-1","label":"Deterministic fixture"}';
}

Future<String> _loadInvalidJson(String _) async => '{invalid json';

Future<String> _loadMissingAsset(String _) async {
  throw StateError('Fixture asset not found.');
}

class FixtureDto {
  const FixtureDto({required this.id, required this.label});

  factory FixtureDto.fromJson(Object? json) {
    final values = Map<String, Object?>.from(json! as Map);
    return FixtureDto(
      id: values['id']! as String,
      label: values['label']! as String,
    );
  }

  final String id;
  final String label;
}
