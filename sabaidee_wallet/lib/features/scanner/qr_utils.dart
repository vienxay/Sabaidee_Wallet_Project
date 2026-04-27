// ─── qr_utils.dart ──────────────────────────────────────────────────────────
// ປະກອບດ້ວຍ:
//   • QRType enum
//   • detectQRType()
//   • LaoQRInfo model

enum QRType { unknown, lightning, lnurl, laoQR } // ✅ ເພີ່ມ lnurl

QRType detectQRType(String raw) {
  final trimmed = raw.trim();
  final lower = trimmed.toLowerCase();

  // ── 1. LNURL (ຕ້ອງກວດກ່ອນ Lightning!) ──────────────────────────────────
  if (lower.startsWith('lnurl')) {
    // ✅ ເພີ່ມ
    return QRType.lnurl;
  }

  // ── 2. Lightning Invoice ຫຼື Lightning Address ───────────────────────────
  final isLnAddress = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(trimmed);

  if (lower.startsWith('lnbc') ||
      lower.startsWith('lightning:') ||
      isLnAddress) {
    return QRType.lightning;
  }

  // ── 3. LAO QR ມາດຕະຖານ ─────────────────────────────────────────────────
  if (trimmed.startsWith('000201')) {
    return QRType.laoQR;
  }

  // ── 4. Keywords ທະນາຄານລາວ ──────────────────────────────────────────────
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

  // ── 5. Demo LaoQR ────────────────────────────────────────────────────────
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
