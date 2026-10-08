import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 12 product images resolve through rootBundle', () async {
    for (var i = 0; i < 12; i++) {
      final data = await rootBundle.load('assets/products/$i.png');
      expect(data.lengthInBytes, greaterThan(0), reason: '$i.png');
    }
  });
}
