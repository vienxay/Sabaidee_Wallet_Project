import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/app_constants.dart';
import 'api_client.dart';
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    name: json['name'],
    lastName: json['lastName'],
    email: json['email'],
    phone: json['phone'],
    dateOfBirth: json['dateOfBirth'],
    gender: json['gender'],
    profileImage: json['profileImage'],
  );
}

class ProfileService {
  // ── GET /api/profile/me ─────────────────────────────────────────
  static Future<ProfileModel?> getProfile() async {
    try {
      final res = await ApiClient.instance.get(AppConstants.profileMe);
      if (res.success && res.data?['data'] != null) {
        return ProfileModel.fromJson(res.data!['data']);
      }
      return null;
    } catch (e) {
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
      if (body.isEmpty) return false;

      final res = await ApiClient.instance.put(AppConstants.profileMe, body);
      return res.success;
    } catch (e) {
      return false;
    }
  }

  // ── POST /api/profile/avatar ────────────────────────────────────
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final token = await ApiClient.instance.getAuthToken();
      if (token == null) return null;

      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
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
          contentType: MediaType.parse(mimeType),
        ),
      );

      const uploadTimeout = Duration(seconds: 120);
      final streamed = await request.send().timeout(uploadTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(uploadTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']['profileImage'] as String?;
      }
      return null;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } catch (e) {
      return null;
    }
  }
}
