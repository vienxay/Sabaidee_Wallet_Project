import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Base HTTP client — inject token ອັດຕະໂນມັດ + handle errors
/// ──────────────────────────────────────────────────────────────────────────────
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final String _base = AppConstants.apiBaseUrl;

  // ─── Headers ────────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── GET ────────────────────────────────────────────────────────────────────
  Future<ApiResponse> get(String path, {bool auth = true}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: await _headers(auth: auth))
          .timeout(const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      return _parse(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  // ─── POST ───────────────────────────────────────────────────────────────────
  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      return _parse(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  // ─── PUT ────────────────────────────────────────────────────────────────────
  Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      return _parse(res);
    } catch (e) {
      return ApiResponse.networkError(e.toString());
    }
  }

  // ─── Parse ──────────────────────────────────────────────────────────────────
  ApiResponse _parse(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ApiResponse(
        statusCode: res.statusCode,
        success: data['success'] == true,
        data: data,
        message: data['message'] as String? ?? '',
      );
    } catch (_) {
      return ApiResponse(
        statusCode: res.statusCode,
        success: false,
        message: 'ບໍ່ສາມາດອ່ານຂໍ້ມູນໄດ້',
      );
    }
  }
}

/// Wrapper ສຳລັບ response ທຸກ endpoint
class ApiResponse {
  final int statusCode;
  final bool success;
  final Map<String, dynamic>? data;
  final String message;

  const ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.message = '',
  });

  factory ApiResponse.networkError(String msg) => ApiResponse(
    statusCode: 0,
    success: false,
    message: 'Network error: $msg',
  );

  bool get isUnauthorized => statusCode == 401;
}
