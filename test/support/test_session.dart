import 'dart:convert';

import 'package:pos_application/core/security/password_hasher.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/session/data/in_memory_session_repositories.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';

import 'seed/seed_customers.dart';
import 'seed/seed_products.dart';

/// The prototype's store, counter and cashier as a session that is already
/// open (DEC-132): the widget tests and goldens keep their text and pixels.
/// The scope stays empty, so the data layer runs in legacy (unscoped) mode.
const testStoreName = 'MAISON GALAXY - OZONE';
const testCounter = 'C3';
const testCashier = 'MGTCASH3';

const _hasher = PasswordHasher();

AppUser get testUser => const AppUser(
  id: 'test-user',
  username: 'cashier',
  displayName: testCashier,
  role: 'cashier',
);

/// Credential of the user above: username `cashier`, password `secret`.
UserCredential get testCredential {
  const salt = '00112233445566778899aabbccddeeff';
  return UserCredential(
    user: testUser,
    salt: salt,
    passwordHash: _hasher.hash(salt, 'secret'),
    hashAlgo: PasswordHasher.algorithm,
  );
}

List<StoreAccess> get testAccess => const <StoreAccess>[
  StoreAccess(
    store: StoreInfo(
      id: 'test-ozone',
      name: testStoreName,
      currencyCode: 'INR',
    ),
    counters: <CounterInfo>[
      CounterInfo(id: 'test-c3', storeId: 'test-ozone', name: testCounter),
    ],
  ),
  StoreAccess(
    store: StoreInfo(
      id: 'test-central',
      name: 'MAISON GALAXY - CENTRAL',
      currencyCode: 'INR',
    ),
    counters: <CounterInfo>[
      CounterInfo(id: 'test-cc3', storeId: 'test-central', name: testCounter),
    ],
  ),
  StoreAccess(
    store: StoreInfo(
      id: 'test-marina',
      name: 'MAISON GALAXY - MARINA',
      currencyCode: 'INR',
    ),
    counters: <CounterInfo>[
      CounterInfo(id: 'test-mc3', storeId: 'test-marina', name: testCounter),
    ],
  ),
];

ActiveSession testSession() => ActiveSession.fixed(
  user: testUser,
  store: testAccess.first.store,
  counter: testAccess.first.counters.first,
  access: testAccess,
  quickCash: const <String, List<int>>{
    'INR': <int>[100, 500, 2000],
  },
  users: InMemoryUserRepository(
    users: <UserCredential>[testCredential],
    access: <String, List<StoreAccess>>{
      testUser.id: <StoreAccess>[testAccess.first],
    },
  ),
);

/// The legacy catalog and customers in the JSON the LocalStore holds, as the
/// seeding of the first start used to write them.
Map<String, Object> legacyStoreData() => <String, Object>{
  'axpert-products': <Map<String, dynamic>>[
    for (final p in SeedProducts.products()) p.toJson(),
  ],
  'axpert-customers': <Map<String, dynamic>>[
    for (final c in SeedCustomers.customers) c.toJson(),
  ],
};

/// A LocalStore that already holds the legacy catalog and customers.
InMemoryLocalStore legacySeededStore() => InMemoryLocalStore(<String, String>{
  for (final e in legacyStoreData().entries) e.key: jsonEncode(e.value),
});
