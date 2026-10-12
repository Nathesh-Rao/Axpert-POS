import 'package:pos_application/core/errors/app_failure.dart';
import 'package:pos_application/core/errors/data_source_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unexpected failure retains message and cause', () {
    final cause = StateError('underlying error');
    const message = 'Operation failed.';
    final failure = UnexpectedFailure(message: message, cause: cause);

    expect(failure.message, message);
    expect(failure.cause, same(cause));
    expect(failure.toString(), message);
  });

  test('data-source failure retains its source error', () {
    final cause = StateError('asset unavailable');
    final failure = DataSourceFailure(
      message: 'Mock JSON data could not be loaded.',
      cause: cause,
    );

    expect(failure, isA<AppFailure>());
    expect(failure.cause, same(cause));
  });
}
