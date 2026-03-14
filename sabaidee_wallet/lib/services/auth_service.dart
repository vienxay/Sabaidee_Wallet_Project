import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  // ─── Register ──────────────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String walletName, // ✅ ປ່ຽນຈາກ name → walletName ໃຫ້ຊັດເຈນ
    required String email,
    required String password,
  }) async {
    final res = await _api.post(AppConstants.authRegister, {
      'walletName': walletName,
      'email': email,
      'password': password,
    }, auth: false);

    if (res.success && res.data != null) {
      // ✅ Register ສຳເລັດ → ບໍ່ຕ້ອງ Save Session ຍ້ອນ Navigate ໄປ /login ຢູ່ດີ
      // await _saveSession(res.data!); ← ລຶບອອກ
      return AuthResult.success(UserModel.fromJson(res.data!['user']));
    }

    // ✅ ແກ້ຫຼັກ: Throw Exception ບໍ່ແມ່ນ String
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

    // ✅ ສອດຄ່ອງກັນ: Login ກໍ Throw ເໝືອນກັນ
    throw Exception(
      res.message.isNotEmpty ? res.message : 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',
    );
  }

  // ─── isLoggedIn ─────────────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) return false;

    // ✅ ກວດ JWT Expiry ໂດຍບໍ່ຕ້ອງ Call API
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Decode Payload (Base64)
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return false;

      // ✅ ກວດວ່າ Token ຍັງບໍ່ໝົດອາຍຸ
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false; // Token ຮູບແບບຜິດ → ຖືວ່າ Logged Out
    }
  }

  // ─── Get Me ────────────────────────────────────────────────────────────────
  Future<UserModel?> getMe() async {
    final res = await _api.get(AppConstants.authMe);
    if (res.success && res.data?['user'] != null) {
      return UserModel.fromJson(res.data!['user']);
    }
    return null;
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post(AppConstants.authLogout, {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
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
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString(AppConstants.tokenKey, data['token']);
    }
    if (data['user'] != null) {
      await prefs.setString(AppConstants.userKey, jsonEncode(data['user']));
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
