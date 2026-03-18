// lib/services/storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  // Singleton Pattern
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  // ✅ FIXED FOR v10: ລຶບ aOptions ີ່ deprecated ອກ
  // ຊ້ default security ທີ່ດີທີ່ສຸດສຳລັບ Android (Android Keystore)
  final _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // groupId: 'group.com.yourapp.shared', // ເປີດໃຊ້ຖ້າຕ້ອງການ App Groups ໃນ iOS
    ),
    // webOptions: const WebOptions(), // ເປີດໃຊ້ຖ້າຮັນເທິງ Web
  );

  // ✅ ໃຊ້ AppConstants — single source of truth
  static const _keyToken = AppConstants.tokenKey;
  static const _keyUser = AppConstants.userKey;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_prefs != null) return; // ✅ ກັນ init ຊ້ຳ
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ StorageService initialized');
  }

  // ── Token (Secure Storage) ────────────────────────────────────────────────
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

  // ── User (Shared Preferences) ─────────────────────────────────────────────
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
      await clearUser(); // ✅ ລົບຂໍ້ມູນເສຍຫາຍ ປ້ອງກັນ Crash
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

  // ── Clear All ─────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    // ✅ ລໍຖ້າທັງສອງຢ່າງໃຫ້ສຳເລັດແບບ Parallel
    await Future.wait([clearToken(), clearUser()]);
    debugPrint('🧹 All storage cleared');
  }

  // ── Generic Utilities ─────────────────────────────────────────────────────
  Future<void> setString(String key, String value) async {
    if (key.isEmpty) {
      throw Exception('Storage key cannot be empty');
    }
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
