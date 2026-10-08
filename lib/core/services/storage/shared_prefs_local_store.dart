import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_store.dart';

/// Real implementation (localStorage on web, platform prefs elsewhere).
class SharedPrefsLocalStore implements LocalStore {
  SharedPrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Object?> read(String key) async {
    final text = _prefs.getString(key);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? json) async {
    await _prefs.setString(key, jsonEncode(json));
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<bool> has(String key) async => _prefs.containsKey(key);
}
