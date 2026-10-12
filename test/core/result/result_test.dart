import 'package:pos_application/core/errors/app_failure.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('fold handles a success value', () {
      const result = Result<int>.success(42);

      final description = result.fold(
        onSuccess: (value) => 'value: $value',
        onFailure: (failure) => 'failure: ${failure.message}',
      );

      expect(description, 'value: 42');
    });

    test('fold handles a failure value', () {
      const failure = UnexpectedFailure(message: 'Unavailable.');
      const result = Result<int>.failure(failure);

      final description = result.fold(
        onSuccess: (value) => 'value: $value',
        onFailure: (error) => 'failure: ${error.message}',
      );

      expect(description, 'failure: Unavailable.');
    });
  });
}
