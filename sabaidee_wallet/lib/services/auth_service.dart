// lib/services/auth_service.dart
// lib/services/auth_service.dart
import 'dart:convert';
import '../core/app_constants.dart';
import '../models/app_models.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  // ✅ ດຶງ token (public method)
  Future<String?> getToken() async {
    return StorageService.instance.getToken();
  }

  // ແທນທີ່ _token() ເກົ່າ
  Future<String?> _token() async => getToken();

  // ─── Register ──────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String walletName,
    required String email,
    required String password,
  }) async {
    final res = await _api.post(AppConstants.authRegister, {
      'walletName': walletName,
      'email': email,
      'password': password,
    }, auth: false);

    if (res.success && res.data != null) {
      return AuthResult.success(UserModel.fromJson(res.data!['user']));
    }

    throw Exception(
      res.message.isNotEmpty ? res.message : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່',
    );
  }

  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post(AppConstants.authLogin, {
      'email': email,
      'password': password,
    }, auth: false);

    if (res.success && res.data != null) {
      await _saveSession(res.data!);
      return AuthResult.success(UserModel.fromJson(res.data!['user']));
    }

    throw Exception(
      res.message.isNotEmpty ? res.message : 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',
    );
  }

  // ─── isLoggedIn ─────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await StorageService.instance.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        await StorageService.instance.clearAll();
        return false;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) {
        await StorageService.instance.clearAll();
        return false;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      if (DateTime.now().isAfter(expiry)) {
        await StorageService.instance.clearAll();
        return false;
      }

      // ✅ JWT valid → return true ເລີຍ ບໍ່ຕ້ອງ call API ຊ້ຳ
      return true;
    } catch (_) {
      await StorageService.instance.clearAll();
      return false;
    }
  }

  // ─── Get Me ────────────────────────────────────────────────────────────────
  // Future<UserModel?> getMe() async {
  //   final res = await _api.get(AppConstants.authMe);
  //   if (res.success && res.data?['user'] != null) {
  //     return UserModel.fromJson(res.data!['user']);
  //   }
  //   return null;
  // }

  Future<UserModel?> getMe() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return null;

      final res = await _api.get(AppConstants.authMe);

      // ✅ ແກ້ໄຂ: ຖ້າ 401 ຕ້ອງ clear token ແລະ return null
      if (res.statusCode == 401) {
        debugPrint('🔑 Token expired/invalid - clearing...');
        await StorageService.instance.clearAll();
        return null;
      }

      if (res.success && res.data?['user'] != null) {
        return UserModel.fromJson(res.data!['user']);
      }
      return null;
    } catch (e) {
      debugPrint('❌ getMe error: $e');
      return null;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post(AppConstants.authLogout, {});
    } catch (_) {}
    await StorageService.instance.clearAll();
  }

  // ─── Forgot Password ───────────────────────────────────────────────────────
  Future<ServiceResult> forgotPassword(String email) async {
    final res = await _api.post(AppConstants.authForgotPass, {
      'email': email,
    }, auth: false);
    return ServiceResult(success: res.success, message: res.message);
  }

  // ─── Verify OTP ────────────────────────────────────────────────────────────
  Future<ServiceResult> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final res = await _api.post(AppConstants.authVerifyOtp, {
      'email': email,
      'otp': otp,
    }, auth: false);
    return ServiceResult(success: res.success, message: res.message);
  }

  // ─── Reset Password ────────────────────────────────────────────────────────
  Future<ServiceResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _api.post(AppConstants.authResetPass, {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    }, auth: false);
    return ServiceResult(success: res.success, message: res.message);
  }

  // ─── Save Session ──────────────────────────────────────────────────────────
  Future<void> _saveSession(Map<String, dynamic> data) async {
    if (data['token'] != null) {
      await StorageService.instance.saveToken(data['token']);
    }
    if (data['user'] != null) {
      await StorageService.instance.saveUser(UserModel.fromJson(data['user']));
    }
  }
}

// ─── Result Types ─────────────────────────────────────────────────────────────
class AuthResult {
  final bool success;
  final UserModel? user;
  final String message;

  const AuthResult._({required this.success, this.user, this.message = ''});

  factory AuthResult.success(UserModel user) =>
      AuthResult._(success: true, user: user);
  factory AuthResult.failure(String msg) =>
      AuthResult._(success: false, message: msg);
}

class ServiceResult {
  final bool success;
  final String message;
  const ServiceResult({required this.success, required this.message});
}
