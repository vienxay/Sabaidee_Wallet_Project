// lib/services/kyc_service.dart
// ✅ ຕົງກັບ kycController.js ຂອງທ່ານ 100%:
//    GET  /api/kyc         → getKYCStatus  → res.kyc.status
//    POST /api/kyc/submit  → submitKYC     → fields: fullName,idNumber,idType,dateOfBirth,phone,address
//                                          → files:  idFront, idBack, selfie

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/kyc_model.dart';
import '../models/kyc_status.dart';
import 'storage_service.dart';

class KycService {
  // ✅ ແກ້ IP ຕາມ environment
  static const _base = 'http://10.0.2.2:5000/api/kyc';
  // Android emulator → 10.0.2.2
  // iOS simulator    → localhost
  // Real device      → IP ຂອງ PC ເຊັ່ນ 192.168.1.x

  static Future<String?> _token() async => StorageService.instance.getToken();

  // ─────────────────────────────────────────────────────────────────────────
  // POST /api/kyc/submit  →  submitKYC()
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitKyc({
    required KycModel data,
  }) async {
    try {
      final token = await _token();
      if (token == null)
        return {'success': false, 'message': 'ກະລຸນາ login ກ່ອນ'};

      if (!data.uploadComplete) {
        return {'success': false, 'message': 'ຕ້ອງອັບໂຫລດຮູບໃຫ້ຄົບ 3 ໃບ'};
      }

      final request = http.MultipartRequest('POST', Uri.parse('$_base/submit'));
      request.headers['Authorization'] = 'Bearer $token';

      // ✅ fields ຕາມ kycController.submitKYC:
      //    fullName, idNumber, idType, dateOfBirth, phone, address
      request.fields.addAll(data.toFields());

      // ✅ files ຕາມ kycController: req.files?.idFront, idBack, selfie
      request.files.add(
        await http.MultipartFile.fromPath('idFront', data.idFront!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('idBack', data.idBack!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('selfie', data.selfie!.path),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        // ✅ kycController response: { success, message, kyc: { status, submittedAt } }
        return {
          'success': true,
          'message': body['message'],
          'kycStatus': body['kyc']?['status'] ?? 'submitted',
        };
      }

      // 400 = KYC verified ແລ້ວ / ຂໍ້ມູນບໍ່ຄົບ
      // 409 = idNumber ຊ້ຳ
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
  // GET /api/kyc  →  getKYCStatus()
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkMyStatus() async {
    try {
      final token = await _token();
      if (token == null) return {'success': false, 'message': 'ບໍ່ມີ token'};

      final res = await http
          .get(
            Uri.parse(_base), // ✅ GET /api/kyc — ບໍ່ແມ່ນ /status
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        // ✅ kycController response:
        //    ຖ້າບໍ່ມີ record → { success: true, kyc: { status: 'pending', message: '...' } }
        //    ຖ້າມີ record    → { success: true, kyc: { status, fullName, submittedAt, verifiedAt, ... } }
        final kycData = body['kyc'] as Map<String, dynamic>?;
        final rawStatus = kycData?['status'] as String?;

        // 'pending' ຈາກ backend = ຍັງບໍ່ submit → map ເປັນ KycStatus.none
        final status = KycStatusX.fromString(rawStatus);

        return {
          'success': true,
          'kycStatus': rawStatus,
          'status': status, // KycStatus enum
          'fullName': kycData?['fullName'],
          'submittedAt': kycData?['submittedAt'],
          'verifiedAt': kycData?['verifiedAt'],
          'rejectedReason': kycData?['rejectedReason'],
          'dailyLimitSats': kycData?['limit']?['dailyLimitSats'],
          'monthlyLimitSats': kycData?['limit']?['monthlyLimitSats'],
        };
      }
      return {'success': false, 'message': body['message'] ?? 'ຜິດພາດ'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
