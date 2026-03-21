// ─── qr_utils.dart ──────────────────────────────────────────────────────────
// ປະກອບດ້ວຍ:
//   • QRType enum
//   • detectQRType()
//   • LaoQRInfo model

enum QRType { unknown, lightning, laoQR }

/// ກວດສອບປະເພດຂອງ QR string
QRType detectQRType(String raw) {
  final trimmed = raw.trim();
  final lower = trimmed.toLowerCase();

  // ── Lightning Invoice ──
  if (lower.startsWith('lnbc') || lower.startsWith('lightning:')) {
    return QRType.lightning;
  }

  // ── LAO QR / EMV / LAPNET ──
  if (trimmed.startsWith('00020101') ||
      lower.contains('lapnet') ||
      lower.contains('bcel') ||
      lower.contains('ldb') ||
      lower.contains('jdb') ||
      lower.contains('mmoney') ||
      RegExp(r'^\d{10,}$').hasMatch(trimmed)) {
    return QRType.laoQR;
  }

  // ── ໂຄດສັ້ນ + ຕົວເລກ/ຕົວໜັງສືໃຫຍ່ → ສົມມຸດ LAO QR (demo) ──
  if (RegExp(r'^[0-9A-Z]{8,}$').hasMatch(trimmed.toUpperCase())) {
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
