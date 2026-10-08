import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/core/services/storage/local_store_seeder.dart';
import 'package:pos_application/core/services/storage/shared_prefs_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _roundTrip(LocalStore store) async {
  expect(await store.has('k'), isFalse);
  expect(await store.read('k'), isNull);
  await store.write('k', <String, dynamic>{
    'a': 1,
    'b': <dynamic>['x', true],
  });
  expect(await store.has('k'), isTrue);
  expect(await store.read('k'), <String, dynamic>{
    'a': 1,
    'b': <dynamic>['x', true],
  });
  await store.write('n', 8561);
  expect(await store.read('n'), 8561);
  await store.remove('k');
  expect(await store.has('k'), isFalse);
}

void main() {
  test('in-memory store round trip', () => _roundTrip(InMemoryLocalStore()));

  test('shared_preferences store round trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await _roundTrip(SharedPrefsLocalStore(prefs));
  });

  test('shared_preferences store ignores corrupt JSON', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'bad': '{oops'});
    final store = SharedPrefsLocalStore(await SharedPreferences.getInstance());
    expect(await store.read('bad'), isNull);
  });

  test('seeding writes only when the key is missing', () async {
    final store = InMemoryLocalStore();
    expect(await LocalStoreSeeder.seedIfMissing(store, 'x', 1), 1);
    expect(await LocalStoreSeeder.seedIfMissing(store, 'x', 2), 1);
    expect(await store.read('x'), 1);
  });
}
