import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class StorageService {
  static late final SharedPreferences _prefs;
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static late final Box _cacheBox;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(StorageKeys.cacheBox);
  }

  // ── Secure Storage (tokens) ──────────────────────
  static Future<void> setSecure(String key, String value) async {
    await _secure.write(key: key, value: value);
  }

  static Future<String?> getSecure(String key) async {
    return _secure.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await _secure.delete(key: key);
  }

  static Future<void> clearSecure() async {
    await _secure.deleteAll();
  }

  // ── Token shortcuts ──────────────────────────────
  static Future<void> setToken(String token) async {
    await setSecure(StorageKeys.accessToken, token);
  }

  static Future<String?> getToken() async {
    return getSecure(StorageKeys.accessToken);
  }

  static Future<void> clearToken() async {
    await deleteSecure(StorageKeys.accessToken);
  }

  // ── SharedPreferences ────────────────────────────
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // ── Hive Cache ───────────────────────────────────
  static Future<void> cacheData(String key, dynamic data) async {
    final jsonStr = jsonEncode({
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _cacheBox.put(key, jsonStr);
  }

  static T? getCachedData<T>(String key, {int maxAgeMinutes = 30}) {
    final raw = _cacheBox.get(key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw as String);
    final timestamp = decoded['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    if (age > maxAgeMinutes * 60 * 1000) return null;

    return decoded['data'] as T?;
  }

  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }
}
