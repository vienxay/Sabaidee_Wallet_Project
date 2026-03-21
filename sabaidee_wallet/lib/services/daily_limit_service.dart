// ─── daily_limit_service.dart ────────────────────────────────────────────────
// ຕິດຕາມຍອດໃຊ້ຈ່າຍ LAO QR ຕໍ່ມື້
// • ວົງເງິນສູງສຸດ: 2,000,000 ກີບ/ມື້
// • Reset ອັດຕະໂນມັດທຸກເທື່ອທີ່ວັນປ່ຽນ

import 'package:shared_preferences/shared_preferences.dart';

class DailyLimitService {
  DailyLimitService._();
  static final instance = DailyLimitService._();

  static const int dailyLimitLAK = 2000000; // 2,000,000 ກີບ

  static const _keySpent = 'lao_qr_daily_spent';
  static const _keyDate = 'lao_qr_daily_date';

  // ─── ດຶງຍອດທີ່ໃຊ້ໄປມື້ນີ້ ────────────────────────────────────────────────
  Future<int> getTodaySpent() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate) ?? '';
    final today = _todayStr();

    // ຖ້າວັນປ່ຽນ → reset
    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keySpent, 0);
      return 0;
    }

    return prefs.getInt(_keySpent) ?? 0;
  }

  // ─── ກວດວ່າຈຳນວນທີ່ຈ່າຍໄດ້ຫຼືບໍ່ ──────────────────────────────────────────
  Future<LimitCheckResult> canPay(int amountLAK) async {
    final spent = await getTodaySpent();
    final remaining = dailyLimitLAK - spent;

    if (amountLAK > remaining) {
      return LimitCheckResult(
        allowed: false,
        todaySpent: spent,
        remaining: remaining,
        requested: amountLAK,
      );
    }

    return LimitCheckResult(
      allowed: true,
      todaySpent: spent,
      remaining: remaining,
      requested: amountLAK,
    );
  }

  // ─── ບັນທຶກຍອດຫຼັງຈ່າຍສຳເລັດ ───────────────────────────────────────────────
  Future<void> recordPayment(int amountLAK) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    await prefs.setString(_keyDate, today);
    final current = prefs.getInt(_keySpent) ?? 0;
    await prefs.setInt(_keySpent, current + amountLAK);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────────
class LimitCheckResult {
  final bool allowed;
  final int todaySpent;
  final int remaining;
  final int requested;

  const LimitCheckResult({
    required this.allowed,
    required this.todaySpent,
    required this.remaining,
    required this.requested,
  });

  /// ຈຳນວນທີ່ເກີນວົງເງິນ
  int get exceeded => requested - remaining;

  String get remainingFormatted => _fmt(remaining);
  String get todaySpentFormatted => _fmt(todaySpent);
  String get limitFormatted => _fmt(DailyLimitService.dailyLimitLAK);

  static String _fmt(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
