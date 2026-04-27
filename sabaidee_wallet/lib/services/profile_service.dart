// services/profile_service.dart
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/app_constants.dart';
import 'api_client.dart'; // ✅ ໃຊ້ ApiClient ແທນ http ໂດຍກົງ
import 'package:http_parser/http_parser.dart';

class ProfileModel {
  final String? name;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? profileImage;

  ProfileModel({
    this.name,
    this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      profileImage: json['profileImage'],
    );
  }
}

class ProfileService {
  // ✅ ລຶບ _getToken() ອອກ — ApiClient ຈັດການໃຫ້ໝົດ
  // ✅ ລຶບ _baseUrl / _avatarUrl ແບບ static string ອອກ — ໃຊ້ constants ໂດຍກົງ

  // ── GET /api/profile/me ─────────────────────────────────────────
  static Future<ProfileModel?> getProfile() async {
    try {
      final res = await ApiClient.instance.get(AppConstants.profileMe);

      print('📥 [ProfileService] GET ${res.statusCode}: ${res.data}');

      if (res.success && res.data?['data'] != null) {
        return ProfileModel.fromJson(res.data['data']);
      }

      // ✅ 401 → ApiClient ຈັດການ clear session ໃຫ້ແລ້ວ
      print('⚠️ [ProfileService] getProfile failed: ${res.message}');
      return null;
    } catch (e) {
      print('❌ [ProfileService] getProfile: $e');
      return null;
    }
  }

  // ── PUT /api/profile/me ─────────────────────────────────────────
  static Future<bool> updateProfile({
    String? name,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final body = {
        if (name != null) 'name': name,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
      };

      if (body.isEmpty) {
        print('⚠️ [ProfileService] PUT → ບໍ່ມີຂໍ້ມູນທີ່ຈະອັບເດດ');
        return false;
      }

      // ✅ ໃຊ້ ApiClient.put() → ມີ timeout + 401 handler ອັດຕະໂນມັດ
      final res = await ApiClient.instance.put(AppConstants.profileMe, body);

      print('📥 [ProfileService] PUT ${res.statusCode}: ${res.data}');
      return res.success;
    } catch (e) {
      print('❌ [ProfileService] updateProfile: $e');
      return false;
    }
  }

  // ── POST /api/profile/avatar ────────────────────────────────────
  // ⚠️ MultipartRequest ໃຊ້ http ໂດຍກົງ (ApiClient ບໍ່ຮອງຮັບ multipart)
  // ✅ ແຕ່ເພີ່ມ timeout ດ້ວຍ .timeout()
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final token = await ApiClient.instance.getAuthToken();
      if (token == null) {
        print('❌ [ProfileService] AVATAR → token null');
        return null;
      }

      // ✅ ตรวจนามสกุลไฟล์ แล้วกำหนด MIME type ตรงๆ
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg', // default
      };

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.profileAvatar}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: MediaType.parse(mimeType), // ✅ บังคับ MIME type
        ),
      );

      // ✅ ใหม่ — เพิ่ม timeout เป็น 120 วินาที สำหรับ upload
      const uploadTimeout = Duration(seconds: 120);
      final streamed = await request.send().timeout(uploadTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(uploadTimeout);

      print(
        '📥 [ProfileService] AVATAR ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['profileImage'] as String?;
      }
      return null;
    } on TimeoutException {
      print('❌ [ProfileService] AVATAR → Upload timeout');
      return null;
    } on SocketException {
      print('❌ [ProfileService] AVATAR → ບໍ່ມີ Internet');
      return null;
    } catch (e) {
      print('❌ [ProfileService] uploadAvatar: $e');
      return null;
    }
  }
}
