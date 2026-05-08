// lib/services/kyc_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/kyc_model.dart';
import '../models/kyc_status.dart';
import 'api_client.dart';

class KycService {
  // ─── GET /api/kyc ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkMyStatus() async {
    try {
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

          // ✅ ຕ້ອງ return 'kyc' object ເຕັມ
          //    KycExistingData.fromJson() ດຶງຂໍ້ມູນຈາກ json['kyc']
          'kyc': kycData,

          // ── ຍັງ return field ດ່ວນໄວ້ໃຊ້ lazy ──
          'fullName': kycData?['fullName'],
          'submittedAt': kycData?['submittedAt'],
          'reviewNote':
              kycData?['reviewNote'], // ✅ ແກ້: ເຄີຍໃຊ້ 'rejectedReason'
        };
      }

      return {'success': false, 'message': res.message};
    } catch (e) {
      debugPrint('[KycService] ❌ checkMyStatus error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── POST /api/kyc/submit ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitKyc({
    required KycModel data,
  }) async {
    try {
      final token = await ApiClient.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'ກະລຸນາ login ກ່ອນ'};
      }

      // ✅ re-submit ໂດຍບໍ່ມີຮູບໃໝ່ = ໃຊ້ຮູບເກົ່າ (server ຈະ keep idFrontUrl ເກົ່າໄວ້)
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.kycSubmit}',
      );
      debugPrint('[KycService] POST → $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      request.fields.addAll(data.toFields());

      // ✅ ຖ້າ passportScan == null (re-submit ໂດຍບໍ່ປ່ຽນຮູບ) → ບໍ່ attach file
      if (data.passportScan != null) {
        request.files.add(
          await http.MultipartFile.fromPath('idFront', data.passportScan!.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);

      debugPrint('[KycService] status: ${res.statusCode}');
      debugPrint('[KycService] body:   ${res.body}');

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 || res.statusCode == 201) {
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

  // ─── GET /api/kyc/list?status=  (Admin) ───────────────────────────────────
  static Future<Map<String, dynamic>> adminListKyc({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final query = [
        if (status != null) 'status=$status',
        'page=$page',
        'limit=$limit',
      ].join('&');

      final res = await ApiClient.instance.get(
        '${AppConstants.kycList}?$query',
      );

      if (res.success && res.data != null) {
        return {'success': true, ...res.data as Map<String, dynamic>};
      }
      return {'success': false, 'message': res.message};
    } catch (e) {
      debugPrint('[KycService] ❌ adminListKyc error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── PUT /api/kyc/verify/:userId  (Admin) ─────────────────────────────────
  static Future<Map<String, dynamic>> adminReviewKyc({
    required String userId,
    required String status, // 'verified' | 'rejected'
    String? reviewNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        if (reviewNote != null && reviewNote.isNotEmpty)
          'reviewNote': reviewNote,
      };

      final res = await ApiClient.instance.put(
        '${AppConstants.kycVerify}/$userId',
        body, // positional argument
      );

      if (res.success && res.data != null) {
        return {'success': true, ...res.data as Map<String, dynamic>};
      }
      return {'success': false, 'message': res.message};
    } catch (e) {
      debugPrint('[KycService] ❌ adminReviewKyc error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
