import 'package:pos_application/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('development config enables mock data without a backend URL', () {
    const config = DevelopmentAppConfig();

    expect(config.environment, AppEnvironment.development);
    expect(config.mockDataEnabled, isTrue);
    expect(config.apiBaseUrl, isNull);
  });
}
