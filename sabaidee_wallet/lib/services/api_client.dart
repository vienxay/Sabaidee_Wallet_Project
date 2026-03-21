// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import 'storage_service.dart'; // ✅ import ໃຫ້ຖືກຕ້ອງ

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

  // ✅ ດຶງ headers ພ້ອມ token
  Future<Map<String, String>> _headers() async {
    final token = await StorageService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // ✅ GET request
  Future<ApiResponse> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: await _headers(),
      );

      // ✅ Handle 401
      if (response.statusCode == 401) {
        await StorageService.instance.clearAll();
        return ApiResponse(
          success: false,
          message: 'Session ໝົດອາຍຸ ກະລຸນາ login ໃໝ່',
          statusCode: 401,
        );
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ✅ POST request
  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final headers = await _headers();
      if (!auth) {
        headers.remove('Authorization');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}$path'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 401 && auth) {
        await StorageService.instance.clearAll();
        return ApiResponse(
          success: false,
          message: 'Session ໝົດອາຍຸ ກະລຸນາ login ໃໝ່',
          statusCode: 401,
        );
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // ✅ Handle response (private method)
  ApiResponse _handleResponse(http.Response response) {
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
