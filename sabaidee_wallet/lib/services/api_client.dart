// lib/services/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'storage_service.dart';

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
  static Duration get uploadTimeout => _uploadTimeout;

  // ✅ Timeout constants
  static const _connectTimeout = Duration(seconds: 20); // POST, PUT, DELETE
  static const _receiveTimeout = Duration(seconds: 20); // GET
  static const _uploadTimeout = Duration(seconds: 60); // File upload

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final token = await StorageService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // api_client.dart — ເພີ່ມ method ນີ້ເຂົ້າໄປໃນ class ApiClient
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
          .timeout(_receiveTimeout); // ✅ timeout

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── POST ─────────────────────────────────────────────────────────
  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_connectTimeout);

      return _handleResponse(response, auth: auth); // ✅ ສົ່ງ auth
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
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
          .timeout(_connectTimeout); // ✅ timeout

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
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
          .timeout(_connectTimeout); // ✅ timeout

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່',
      );
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ─── Handle Response ──────────────────────────────────────────────
  ApiResponse _handleResponse(http.Response response, {bool auth = true}) {
    // ✅ clear storage ສະເພາະຕອນ authenticated request ເທົ່ານັ້ນ
    if (response.statusCode == 401 && auth) {
      StorageService.instance.clearAll();
      return ApiResponse(
        success: false,
        message: 'Session ໝົດອາຍຸ ກະລຸນາ login ໃໝ່',
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
