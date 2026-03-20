// lib/models/kyc_model.dart
import 'dart:io';

class KycModel {
  String fullName;
  String gender; // 'male' | 'female' | 'other' — UI value
  DateTime? dateOfBirth;
  String nationality;
  String email;
  String passportNumber;
  DateTime? expiryDate;
  File? passportScan;

  KycModel({
    this.fullName = '',
    this.gender = '',
    this.dateOfBirth,
    this.nationality = '',
    this.email = '',
    this.passportNumber = '',
    this.expiryDate,
    this.passportScan,
  });

  // ── ແປ gender → M / F ຕາມ Schema ─────────────────────────────────────────
  String get genderCode {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'M';
      case 'female':
        return 'F';
      default:
        return 'M'; // fallback
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/'
            '${d.year}';

  String get dobFormatted => fmtDate(dateOfBirth);
  String get expiryFormatted => fmtDate(expiryDate);

  bool get uploadComplete => passportScan != null;

  Map<String, String> toFields() => {
    'fullName': fullName,
    'gender': genderCode, // ✅ M / F ຕາມ Schema
    'dob': dateOfBirth?.toIso8601String() ?? '',
    'nationality': nationality, // ✅ ເພີ່ມຕາມ Schema
    'email': email,
    'passportNumber': passportNumber,
    'expiryDate': expiryDate?.toIso8601String() ?? '',
    'consentData': 'true',
  };
}
