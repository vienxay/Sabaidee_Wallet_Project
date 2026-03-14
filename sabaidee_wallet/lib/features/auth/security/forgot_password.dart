import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sabaidee_wallet/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ForgotPasswordService {
  // ✅ ໃຊ້ AppConstants — ບໍ່ hardcode IP
  static String get _baseUrl => '${AppConstants.apiBaseUrl}/api/auth';

  // ✅ SSL bypass ສະເພາະ debug mode
  http.Client _createClient() {
    if (kDebugMode) {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return IOClient(httpClient);
    }
    return http.Client(); // ✅ Production: normal SSL
  }

  // ✅ Helper: parse JSON response safely
  Map<String, dynamic> _parseResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Server error (${response.statusCode})');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('ຂໍ້ມູນຈາກ Server ບໍ່ຖືກຕ້ອງ');
    }
  }

  /// POST /api/auth/forgot-password
  Future<void> sendOtp({required String email}) async {
    final client = _createClient();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15)); // ✅ timeout

      final data = _parseResponse(response); // ✅ safe parse
      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'ເກີດຂໍ້ຜິດພາດ');
      }
    } on SocketException {
      throw Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້');
    } on TimeoutException {
      // ✅ handle timeout
      throw Exception('ການເຊື່ອມຕໍ່ໝົດເວລາ — ກະລຸນາລອງໃໝ່');
    } finally {
      client.close();
    }
  }

  /// POST /api/auth/verify-otp
  Future<bool> verifyOtp({required String email, required String otp}) async {
    final client = _createClient();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15)); // ✅ timeout

      final data = _parseResponse(response);
      if (response.statusCode == 200) {
        return data['verified'] == true;
      }
      throw Exception(data['message'] ?? 'OTP ບໍ່ຖືກຕ້ອງ');
    } on SocketException {
      throw Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້');
    } on TimeoutException {
      throw Exception('ການເຊື່ອມຕໍ່ໝົດເວລາ — ກະລຸນາລອງໃໝ່');
    } finally {
      client.close();
    }
  }

  /// POST /api/auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final client = _createClient();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15)); // ✅ timeout

      final data = _parseResponse(response);
      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'ບໍ່ສາມາດຣີເຊັດລະຫັດຜ່ານໄດ້');
      }
    } on SocketException {
      throw Exception('ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້');
    } on TimeoutException {
      throw Exception('ການເຊື່ອມຕໍ່ໝົດເວລາ — ກະລຸນາລອງໃໝ່');
    } finally {
      client.close();
    }
  }

  // ✅ reuse sendOtp (ຄືເດີມ — ຖືກຕ້ອງແລ້ວ)
  Future<void> resendOtp({required String email}) => sendOtp(email: email);
}
