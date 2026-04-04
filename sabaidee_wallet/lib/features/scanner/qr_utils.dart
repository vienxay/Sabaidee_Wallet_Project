// ─── qr_utils.dart ──────────────────────────────────────────────────────────
// ປະກອບດ້ວຍ:
//   • QRType enum
//   • detectQRType()
//   • LaoQRInfo model

enum QRType { unknown, lightning, laoQR }

QRType detectQRType(String raw) {
  final trimmed = raw.trim();
  final lower = trimmed.toLowerCase();

  // ── 1. ກວດ Lightning (ຈ່າຍດ້ວຍ Bitcoin) ──
  // ກວດທັງ Invoice (lnbc) ແລະ Address (user@domain)
  final isLnAddress = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(trimmed);
  if (lower.startsWith('lnbc') ||
      lower.startsWith('lightning:') ||
      isLnAddress) {
    return QRType.lightning;
  }

  // ── 2. ກວດ LaoQR ມາດຕະຖານ (ໃຊ້ໄດ້ແທ້ກັບທະນາຄານ) ──
  if (trimmed.startsWith('000201')) {
    return QRType.laoQR;
  }

  // ── 3. ກວດ Keywords ທະນາຄານໃນລາວ ──
  final laoKeywords = [
    'lapnet',
    'bcel',
    'ldb',
    'jdb',
    'mmoney',
    'onepay',
    'one pay',
  ];
  if (laoKeywords.any((key) => lower.contains(key))) {
    return QRType.laoQR;
  }

  // ── 4. ໂຕເດໂມ (Demo Logic) ──
  // ໃຫ້ກວດເປັນອັນສຸດທ້າຍ! ຖ້າບໍ່ແມ່ນ Lightning ແລະ ບໍ່ແມ່ນ Standard LaoQR
  // ແຕ່ເປັນຕົວເລກ 8 ຕົວຂຶ້ນໄປ ຫຼື ຕົວໜັງສືໃຫຍ່ ໃຫ້ສົມມຸດວ່າເປັນ LaoQR (Demo)
  if (RegExp(r'^\d{8,15}$').hasMatch(trimmed) ||
      RegExp(r'^[0-9A-Z]{8,}$').hasMatch(trimmed.toUpperCase())) {
    return QRType.laoQR;
  }

  return QRType.unknown;
}

// ─── LAO QR Info Model ───────────────────────────────────────────────────────
class LaoQRInfo {
  final String raw;
  final String merchantName;
  final String bank;

  const LaoQRInfo({
    required this.raw,
    required this.merchantName,
    required this.bank,
  });

  /// Parse ຊື່ຮ້ານ / ທະນາຄານຈາກ raw QR string
  factory LaoQRInfo.fromRaw(String raw) {
    final lower = raw.toLowerCase();

    String bank = 'ທະນາຄານລາວ';
    String merchant = 'ຮ້ານຄ້າ';

    if (lower.contains('bcel')) {
      bank = 'BCEL';
    } else if (lower.contains('ldb')) {
      bank = 'LDB';
    } else if (lower.contains('jdb')) {
      bank = 'JDB';
    } else if (lower.contains('mmoney')) {
      bank = 'MMONEY';
      merchant = 'M-Money Merchant';
    } else if (raw.startsWith('00020101')) {
      bank = 'LAPNET';
      merchant = 'ຮ້ານຄ້າ (LAPNET QR)';
    }

    return LaoQRInfo(raw: raw, merchantName: merchant, bank: bank);
  }
}
