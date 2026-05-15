// ຈັດການ Local Storage 2 ຊັ້ນ:
//   FlutterSecureStorage → token (encrypt ດ້ວຍ Android Keystore / iOS Keychain)
//   SharedPreferences    → user data (ຂໍ້ມູນ user ທົ່ວໄປ ບໍ່ sensitive)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_constants.dart';
import '../models/app_models.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  // token ເກັບໃນ secure storage — encrypt ດ້ວຍ hardware security
  // iOS: Keychain (first_unlock_this_device = unlock ເທື່ອດຽວຕໍ່ restart)
  // Android: Android Keystore
  final _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _keyToken = AppConstants.tokenKey;
  static const _keyUser  = AppConstants.userKey;

  // ─── Initialize ──────────────────────────────────────────────────────────
  // ຕ້ອງ call ໃນ main() ກ່ອນ runApp
  Future<void> init() async {
    if (_prefs != null) return; // ກັນ init ຊ້ຳ
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ StorageService initialized');
  }

  // ─── Token (FlutterSecureStorage) ────────────────────────────────────────
  // token ຕ້ອງໃຊ້ secure storage ເພາະ JWT ທີ່ລັກໄດ້ = ເຂົ້າ account ໄດ້ທັນທີ

  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _keyToken, value: token);
      debugPrint('🔐 Token saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
      throw Exception('ບໍ່ສາມາດບັນທຶກ token ດ້');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _keyToken);
    } catch (e) {
      debugPrint('❌ Error reading token: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _keyToken);
      debugPrint('🔐 Token cleared');
    } catch (e) {
      debugPrint('❌ Error clearing token: $e');
    }
  }

  // ─── User (SharedPreferences) ────────────────────────────────────────────
  // user data ເກັບ JSON string ໃນ SharedPreferences (ບໍ່ sensitive)

  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      debugPrint('👤 User saved: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      throw Exception('ບໍ່ສາມາດບັນທຶກຂໍ້ມູນຜູ້ໃຊ້ໄດ້');
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyUser);
      if (raw == null || raw.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(raw));
    } on FormatException catch (e) {
      debugPrint('❌ Error parsing user JSON: $e');
      await clearUser(); // ລົບຂໍ້ມູນທີ່ເສຍຫາຍ ກັນ crash
      return null;
    } catch (e) {
      debugPrint('❌ Error reading user: $e');
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      debugPrint('👤 User cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user: $e');
    }
  }

  // ─── Clear All ────────────────────────────────────────────────────────────
  // ເອີ້ນຕອນ logout ຫຼື 401 — clear token + user ພ້ອມກັນ (parallel)
  Future<void> clearAll() async {
    debugPrint('⚠️ clearAll() called from:');
    debugPrintStack(label: 'clearAll stack');
    await Future.wait([clearToken(), clearUser()]);
    debugPrint('🧹 All storage cleared');
  }

  // ─── Generic Utilities ───────────────────────────────────────────────────
  Future<void> setString(String key, String value) async {
    if (key.isEmpty) throw Exception('Storage key cannot be empty');
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ Error setting $key: $e');
      throw Exception('ບໍ່ສາມາດບັນທຶກຂໍ້ມູນໄດ້');
    }
  }

  Future<String?> getString(String key) async {
    if (key.isEmpty) return null;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('❌ Error getting $key: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    if (key.isEmpty) return;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Error removing $key: $e');
    }
  }
}
