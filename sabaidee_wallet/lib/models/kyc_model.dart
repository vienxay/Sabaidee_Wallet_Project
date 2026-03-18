// lib/models/kyc_model.dart
import 'dart:io';

class KycModel {
  // ── ຂໍ້ມູນຕາມ backend ──────────────────────────────────────────────────────
  String fullName;
  String idNumber;
  String idType;
  DateTime? dateOfBirth;
  String phone;
  String address;

  // ── ຂໍ້ມູນສ່ວນຕົວເພີ່ມເຕີມ ─────────────────────────────────────────────────
  String laoName;
  String placeOfBirth;
  String gender;

  // ── Passport-specific ──────────────────────────────────────────────────────
  DateTime? expiryDate;

  // ── ຮູບ 3 ໄຟລ ─────────────────────────────────────────────────────────────
  File? idFront;
  File? idBack;
  File? selfie;

  // ── Consent ────────────────────────────────────────────────────────────────
  bool consentData;
  bool consentPdpa;

  // ── AML ────────────────────────────────────────────────────────────────────
  bool isPep;
  String fundSource;

  KycModel({
    this.fullName = '',
    this.idNumber = '',
    this.idType = 'passport',
    this.dateOfBirth,
    this.phone = '',
    this.address = '',
    this.laoName = '',
    this.placeOfBirth = '',
    this.gender = '',
    this.expiryDate,
    this.idFront,
    this.idBack,
    this.selfie,
    this.consentData = false,
    this.consentPdpa = false,
    this.isPep = false,
    this.fundSource = 'ເງິນເດືອນ',
  });

  // ── Aliases (backward compat ກັບ step files) ───────────────────────────────
  DateTime? get dob => dateOfBirth;
  set dob(DateTime? v) => dateOfBirth = v;

  String get passportNumber => idNumber;
  set passportNumber(String v) => idNumber = v;

  // ── Helpers ────────────────────────────────────────────────────────────────
  String fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/'
            '${d.year}';

  String get dobFormatted => fmtDate(dateOfBirth);
  String get expiryFormatted => fmtDate(expiryDate);

  bool get isPassportExpiringSoon {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now().add(const Duration(days: 180)));
  }

  bool get uploadComplete =>
      idFront != null && idBack != null && selfie != null;

  String get idTypeLabel => idType == 'passport' ? 'Passport' : 'ບັດປະຊາຊົນ';

  Map<String, String> toFields() => {
    'fullName': fullName,
    'idNumber': idNumber,
    'idType': idType,
    'dateOfBirth': dateOfBirth?.toIso8601String() ?? '',
    'expiryDate': expiryDate?.toIso8601String() ?? '',
    'phone': phone,
    'address': address,
    'laoName': laoName,
    'placeOfBirth': placeOfBirth,
    'gender': gender,
    'isPep': isPep.toString(),
    'fundSource': fundSource,
    'consentData': consentData.toString(),
    'consentPdpa': consentPdpa.toString(),
  };
}
