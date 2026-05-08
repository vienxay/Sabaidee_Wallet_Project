// lib/models/kyc_status.dart
// ✅ ຕົງກັບ KYC model status values ຈິງ:
//    none      = ຍັງບໍ່ submit (Flutter-only, backend ບໍ່ມີ record)
//    submitted = ສົ່ງແລ້ວ ລໍ admin ກວດ
//    verified  = admin approve ແລ້ວ
//    rejected  = admin reject

enum KycStatus {
  none, // ຍັງບໍ່ submit
  submitted, // ✅ ສົ່ງແລ້ວ ລໍຖ້າ (backend ໃຊ້ 'submitted' ບໍ່ແມ່ນ 'pending')
  verified, // ✅ ຜ່ານ
  rejected, // ຖືກປະຕິເສດ
}

extension KycStatusX on KycStatus {
  bool get isVerified => this == KycStatus.verified;
  bool get isSubmitted => this == KycStatus.submitted;
  bool get isRejected => this == KycStatus.rejected;
  bool get canSubmit => this == KycStatus.none || this == KycStatus.rejected;

  String get label {
    switch (this) {
      case KycStatus.none:
        return 'ຍັງບໍ່ໄດ້ຢືນຢັນ';
      case KycStatus.submitted:
        return 'ລໍຖ້າກວດສອບ';
      case KycStatus.verified:
        return 'ຜ່ານການຢືນຢັນ ✓';
      case KycStatus.rejected:
        return 'ຖືກປະຕິເສດ';
    }
  }

  // ── Map string ຈາກ backend ──────────────────────────────────────────────
  // backend getKYCStatus ສົ່ງ 'pending' ເມື່ອບໍ່ມີ record → map ເປັນ none
  static KycStatus fromString(String? s) {
    switch (s) {
      case 'submitted':
        return KycStatus.submitted;
      case 'verified':
        return KycStatus.verified;
      case 'rejected':
        return KycStatus.rejected;
      case 'pending':
        return KycStatus.none; // backend default "ຍັງບໍ່ submit"
      default:
        return KycStatus.none;
    }
  }

  // ── kycStatus field ໃນ User model (sync ຫລັງ admin action) ───────────────
  // User.kycStatus: 'pending' | 'verified' | 'rejected'
  static KycStatus fromUserStatus(String? s) {
    switch (s) {
      case 'verified':
        return KycStatus.verified;
      case 'rejected':
        return KycStatus.rejected;
      case 'pending':
        return KycStatus.submitted; // User pending = KYC submitted
      default:
        return KycStatus.none;
    }
  }
}
