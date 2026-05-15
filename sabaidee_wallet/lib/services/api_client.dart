// HTTP Client ກາງ — ທຸກ service ໃຊ້ instance ດຽວກັນນີ້
// ຈັດການ: headers, timeout, 401 auto-logout, error messages ພາສາລາວ
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../core/navigator_key.dart';
import 'storage_service.dart';

// ໂຄງສ້າງຜົນລັບ HTTP — ທຸກ method return type ນີ້
class ApiResponse {
  final bool success;
  final dynamic data;
  final String message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message = '',
    this.statusCode,
  });
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // timeout ດຶງຈາກ AppConstants — single source of truth
  static Duration get uploadTimeout => AppConstants.uploadTimeout;

  static const _connectTimeout = AppConstants.connectTimeout;
  static const _receiveTimeout = AppConstants.receiveTimeout;

  // ─── Error → ຂໍ້ຄວາມພາສາລາວ ──────────────────────────────────────
  // ກວດ exception type ແລ້ວ return ຂໍ້ຄວາມທີ່ user ເຂົ້າໃຈໄດ້
  static ApiResponse _errResponse(Object e) {
    if (e is TimeoutException) {
      return ApiResponse(success: false, message: 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່');
    }
    if (e is HandshakeException) {
      // SSL handshake ລົ້ມເຫລວ — ອາດຍ້ອນ ngrok URL ໝົດອາຍຸ
      return ApiResponse(success: false, message: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້ ກະລຸນາລອງໃໝ່');
    }
    if (e is SocketException) {
      return ApiResponse(success: false, message: 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ');
    }
    return ApiResponse(success: false, message: 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່');
  }

  // ສ້າງ headers ມາດຕະຖານ — ຕໍ່ JWT token ຖ້າ auth = true
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final token = await StorageService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true', // bypass ngrok browser warning popup
    };
  }

  Future<String?> getAuthToken() async {
    return await StorageService.instance.getToken();
  }

  // ─── GET ──────────────────────────────────────────────────────────
  Future<ApiResponse> get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(_receiveTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _errResponse(e);
    }
  }

  // ─── POST ─────────────────────────────────────────────────────────
  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true, // auth = false ສຳລັບ login/register (ບໍ່ມີ token ຍັງ)
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_connectTimeout);
      return _handleResponse(response, auth: auth);
    } catch (e) {
      return _errResponse(e);
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────────
  Future<ApiResponse> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _errResponse(e);
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────
  Future<ApiResponse> delete(String path) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(_connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      return _errResponse(e);
    }
  }

  // ─── Handle Response ──────────────────────────────────────────────
  ApiResponse _handleResponse(http.Response response, {bool auth = true}) {
    // 401 = token ໝົດອາຍຸ → clear session ແລ້ວ redirect login ທັນທີ
    if (response.statusCode == 401 && auth) {
      StorageService.instance.clearAll();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
          arguments: 'session_expired',
        );
      });

      return ApiResponse(
        success: false,
        message: 'session_expired',
        statusCode: 401,
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: body,
        message: body['message'] ?? '',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    }
  }
}
