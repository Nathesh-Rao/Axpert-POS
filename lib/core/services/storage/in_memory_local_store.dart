import 'dart:convert';

import 'local_store.dart';

/// Test and fallback implementation. Round-trips through JSON text so it
/// behaves like the real store (no shared mutable objects).
class InMemoryLocalStore implements LocalStore {
  InMemoryLocalStore([Map<String, String>? initial])
    : _data = Map<String, String>.of(initial ?? const <String, String>{});

  final Map<String, String> _data;

  @override
  Future<Object?> read(String key) async {
    final text = _data[key];
    return text == null ? null : jsonDecode(text);
  }

  @override
  Future<void> write(String key, Object? json) async {
    _data[key] = jsonEncode(json);
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> has(String key) async => _data.containsKey(key);
}
