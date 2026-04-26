// lib/services/kyc_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/kyc_model.dart';
import '../models/kyc_status.dart';
import 'api_client.dart'; // ✅ ໃຊ້ ApiClient

class KycService {
  // ─── GET /api/kyc ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkMyStatus() async {
    try {
      // ✅ ໃຊ້ ApiClient.get() → ມີ timeout + 401 handler ອັດຕະໂນມັດ
      final res = await ApiClient.instance.get(AppConstants.kycStatus);

      debugPrint('[KycService] GET ${res.statusCode}: ${res.data}');

      if (res.success && res.data != null) {
        final body = res.data as Map<String, dynamic>;
        final kycData = body['kyc'] as Map<String, dynamic>?;
        final rawStatus =
            kycData?['status'] as String? ?? body['kycStatus'] as String?;
        final kycStatus = KycStatusX.fromString(rawStatus);

        return {
          'success': true,
          'kycStatus': rawStatus,
          'status': kycStatus,
          'fullName': kycData?['fullName'],
          'submittedAt': kycData?['submittedAt'],
          'verifiedAt': kycData?['verifiedAt'],
          'rejectedReason': kycData?['reviewNote'],
        };
      }

      // ✅ 401 → ApiClient ຈັດການ clear session ໃຫ້ແລ້ວ
      return {'success': false, 'message': res.message};
    } catch (e) {
      debugPrint('[KycService] ❌ checkMyStatus error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── POST /api/kyc/submit ──────────────────────────────────────────
  // ⚠️ MultipartRequest ໃຊ້ http ໂດຍກົງ (ApiClient ບໍ່ຮອງຮັບ multipart)
  // ✅ ແຕ່ເພີ່ມ timeout 30 ວິ ແລະ SocketException handler
  static Future<Map<String, dynamic>> submitKyc({
    required KycModel data,
  }) async {
    try {
      // ✅ ດຶງ token ຜ່ານ ApiClient
      final token = await ApiClient.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('[KycService] ❌ token null');
        return {'success': false, 'message': 'ກະລຸນາ login ກ່ອນ'};
      }

      if (data.passportScan == null) {
        return {'success': false, 'message': 'ກະລຸນາອັບໂຫລດຮູບ passport'};
      }

      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.kycSubmit}',
      );
      debugPrint('[KycService] POST → $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      request.fields.addAll(data.toFields());
      request.files.add(
        await http.MultipartFile.fromPath('idFront', data.passportScan!.path),
      );

      // ✅ timeout 30 ວິ (ໃຫ້ file upload ພໍ)
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);

      debugPrint('[KycService] status: ${res.statusCode}');
      debugPrint('[KycService] body:   ${res.body}');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'],
          'kycStatus': body['kycStatus'] ?? 'pending',
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'ເກີດຂໍ້ຜິດພາດ',
        'code': res.statusCode,
      };
    } on TimeoutException {
      debugPrint('[KycService] ❌ submitKyc → Timeout');
      return {
        'success': false,
        'message': 'ການເຊື່ອມຕໍ່ໃຊ້ເວລາດົນເກີນ ກະລຸນາລອງໃໝ່',
      };
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server'};
    } catch (e) {
      debugPrint('[KycService] ❌ submitKyc error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
