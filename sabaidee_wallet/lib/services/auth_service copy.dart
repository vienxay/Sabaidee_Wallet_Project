// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ✅ Parse JSON safely
  Map<String, dynamic> _parseResponse(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${res.statusCode})');
    }
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('ຮູບແບບຂໍ້ມູນຕອບກັບບໍ່ຖືກຕ້ອງ');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<UserModel> register({
    // ✅ return UserModel
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty) throw Exception('ກະລຸນາໃສ່ຊື່'); // ✅ Exception
    _validateEmail(email);
    _validatePassword(password);

    try {
      debugPrint('🚀 Registering: $email');

      final res = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.authRegister}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(
            Duration(milliseconds: AppConstants.receiveTimeoutMs),
          ); // ✅ AppConstants

      final body = _parseResponse(res); // ✅ safe parse

      if (res.statusCode != 201) {
        throw Exception(body['message'] ?? 'ສົ່ງຂໍ້ມູນລົ້ມເຫລວ');
      }

      // ✅ auto-login ຫຼັງ register
      final user = UserModel.fromJson(body['user']);
      await StorageService.instance.saveToken(body['token']);
      await StorageService.instance.saveUser(user);

      debugPrint('✅ Register successful: ${user.email}');
      return user;
    } on SocketException {
      throw Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບ server ໄດ້ ກະລຸນາກວດສອບອິນເຕີເນັດ');
    } on TimeoutException {
      throw Exception('ການເຊື່ອມຕໍ່ໃຊ້ເວລານານເກີນໄປ ກະລຸນາລອງໃໝ່');
    } catch (e) {
      if (e is Exception) rethrow; // ✅ ຢ່າ wrap ຊ້ຳ
      throw Exception('ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    if (password.isEmpty) throw Exception('ກະລຸນາໃສ່ລະຫັດຜ່ານ');

    try {
      debugPrint('🔑 Logging in: $email');

      final res = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.authLogin}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(Duration(milliseconds: AppConstants.receiveTimeoutMs));

      final body = _parseResponse(res);

      if (res.statusCode != 200) {
        throw Exception(body['message'] ?? 'Email ຫຼື Password ບໍ່ຖືກຕ້ອງ');
      }

      final user = UserModel.fromJson(body['user']);
      await StorageService.instance.saveToken(body['token']);
      await StorageService.instance.saveUser(user);

      debugPrint('✅ Login successful: ${user.email}');
      return user;
    } on SocketException {
      throw Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບ server ໄດ້ ກະລຸນາກວດສອບອິນເຕີເນັດ');
    } on TimeoutException {
      throw Exception('ການເຊື່ອມຕໍ່ໃຊ້ເວລານານເກີນໄປ');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await StorageService.instance.clearToken();
      await StorageService.instance.clearUser();
      debugPrint('✅ Logged out');
    } catch (e) {
      debugPrint('Logout error: $e');
      throw Exception('ບໍ່ສາມາດອອກຈາກລະບົບໄດ້');
    }
  }

  // ── Check Auth (with JWT expiry) ──────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await StorageService.instance.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // ✅ decode base64 payload + ກວດ exp
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;

      final exp = payload['exp'] as int?;
      if (exp == null) return false;

      return DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Get Current User ──────────────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    return StorageService.instance.getUser();
  }

  // ── Validation Helpers ────────────────────────────────────────────────────
  void _validateEmail(String email) {
    if (email.trim().isEmpty) throw Exception('ກະລຸນາໃສ່ Email');
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      throw Exception('Email ບໍ່ຖືກຕ້ອງ');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw Exception('Password ຕ້ອງມີຢ່າງນ້ອຍ 6 ຕົວອັກສອນ');
    }
  }
}
