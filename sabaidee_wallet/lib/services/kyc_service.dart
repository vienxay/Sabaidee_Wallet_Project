// lib/services/kyc_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/kyc_model.dart';
import '../models/kyc_status.dart';
import 'storage_service.dart';

class KycService {
  // ✅ FIX 1: ໃຊ້ AppConstants ແທນ hardcode URL
  //    ກ່ອນ: 'http://10.0.2.2:5000/api/kyc' ← ໃຊ້ໄດ້ແຕ່ emulator
  //    ຕອນນີ້: ngrok URL ຈາກ AppConstants ← ໃຊ້ໄດ້ທຸກເຄື່ອງ
  static String get _base =>
      '${AppConstants.apiBaseUrl}${AppConstants.kycStatus}';

  static Future<String?> _token() async => StorageService.instance.getToken();

  // ─────────────────────────────────────────────────────────────────────────
  // POST /api/kyc/submit
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitKyc({
    required KycModel data,
  }) async {
    try {
      final token = await _token();

      // ✅ FIX 2: ກວດ token null ແລະ empty ທັງ 2
      if (token == null || token.isEmpty) {
        debugPrint('[KycService] ❌ token is null or empty');
        return {'success': false, 'message': 'ກະລຸນາ login ກ່ອນ'};
      }

      debugPrint('[KycService] ✅ token: ${token.substring(0, 10)}...');

      if (data.passportScan == null) {
        return {'success': false, 'message': 'ກະລຸນາອັບໂຫລດຮູບ passport'};
      }

      // ✅ FIX 3: ໃຊ້ AppConstants.kycSubmit ແທນ hardcode
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.kycSubmit}',
      );
      debugPrint('[KycService] POST → $uri');

      final request = http.MultipartRequest('POST', uri);

      // ✅ FIX 4: ngrok ຕ້ອງການ header ນີ້
      //    ຖ້າບໍ່ໃສ່ ngrok ຈະ return HTML page ແທນ JSON → jsonDecode crash
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(data.toFields());
      debugPrint('[KycService] fields: ${request.fields}');

      // ✅ FIX 5: ສົ່ງແຕ່ idFront ດຽວ — ລຶບ selfie ອອກ
      request.files.add(
        await http.MultipartFile.fromPath('idFront', data.passportScan!.path),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);

      debugPrint('[KycService] status: ${res.statusCode}');
      debugPrint('[KycService] body: ${res.body}');

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
    } on SocketException {
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server'};
    } catch (e) {
      debugPrint('[KycService] ❌ error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET /api/kyc
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkMyStatus() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'ບໍ່ມີ token'};
      }

      final uri = Uri.parse(_base);
      debugPrint('[KycService] GET → $uri');

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              // ✅ ngrok header
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final kycData = body['kyc'] as Map<String, dynamic>?;
        // ✅ rawStatus = String, kycStatus enum ແຍກກັນຊັດເຈນ
        final rawStatus =
            kycData?['status'] as String? ?? body['kycStatus'] as String?;
        final kycStatus = KycStatusX.fromString(rawStatus);

        return {
          'success': true,
          'kycStatus': rawStatus, // String → ໃຊ້ໃນ kyc_gate_service
          'status': kycStatus, // KycStatus enum → ໃຊ້ໃນ UI
          'fullName': kycData?['fullName'],
          'submittedAt': kycData?['submittedAt'],
          'verifiedAt': kycData?['verifiedAt'],
          'rejectedReason': kycData?['reviewNote'],
        };
      }

      return {'success': false, 'message': body['message'] ?? 'ຜິດພາດ'};
    } catch (e) {
      debugPrint('[KycService] ❌ checkMyStatus error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
