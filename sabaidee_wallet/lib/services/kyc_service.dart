// lib/services/kyc_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/kyc_model.dart';
import '../models/kyc_status.dart';
import 'storage_service.dart';

class KycService {
  static const _base = 'http://10.0.2.2:5000/api/kyc';

  static Future<String?> _token() async => StorageService.instance.getToken();

  // ─────────────────────────────────────────────────────────────────────────
  // POST /api/kyc/submit
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitKyc({
    required KycModel data,
  }) async {
    try {
      final token = await _token();
      if (token == null) {
        return {'success': false, 'message': 'ກະລຸນາ login ກ່ອນ'};
      }

      if (data.passportScan == null) {
        return {'success': false, 'message': 'ກະລຸນາອັບໂຫລດຮູບ passport'};
      }

      final request = http.MultipartRequest('POST', Uri.parse('$_base/submit'));
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ fields ຕົງກັບ backend: dob, consentData ຢູ່ໃນ toFields() ແລ້ວ
      request.fields.addAll(data.toFields());

      // ✅ backend ຕ້ອງການ idFront + selfie
      //    ສົ່ງ passportScan ດຽວກັນທັງ 2 field
      request.files.add(
        await http.MultipartFile.fromPath('idFront', data.passportScan!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('selfie', data.passportScan!.path),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);
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
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET /api/kyc
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkMyStatus() async {
    try {
      final token = await _token();
      if (token == null) return {'success': false, 'message': 'ບໍ່ມີ token'};

      final res = await http
          .get(Uri.parse(_base), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final kycData = body['kyc'] as Map<String, dynamic>?;
        final rawStatus =
            kycData?['status'] as String? ?? body['kycStatus'] as String?;
        final status = KycStatusX.fromString(rawStatus);

        return {
          'success': true,
          'kycStatus': rawStatus,
          'status': status,
          'fullName': kycData?['fullName'],
          'submittedAt': kycData?['submittedAt'],
          'verifiedAt': kycData?['verifiedAt'],
          'rejectedReason': kycData?['reviewNote'],
        };
      }
      return {'success': false, 'message': body['message'] ?? 'ຜິດພາດ'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
