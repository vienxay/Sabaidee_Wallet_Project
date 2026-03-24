import 'package:shared_preferences/shared_preferences.dart';
import 'kyc_gate_service.dart'; // ✅ import KycGateService
import '../models/kyc_status.dart';

class DailyLimitService {
  DailyLimitService._();
  static final instance = DailyLimitService._();

  // ✅ ວົງເງິນຕາມ KYC status
  static const int limitUnverified = 2000000; // 2 ລ້ານ/ມື້ (ບໍ່ຜ່ານ KYC)
  static const int limitVerified = 100000000; // 100 ລ້ານ/ມື້ (ຜ່ານ KYC)

  static const _keySpent = 'lao_qr_daily_spent';
  static const _keyDate = 'lao_qr_daily_date';

  // ✅ ດຶງ limit ຕາມ KYC status ປັດຈຸບັນ
  // ✅ ໃໝ່ — ໃຊ້ getStatus() ທີ່ມີຢູ່ແລ້ວ
  Future<int> getDailyLimit() async {
    final status = await KycGateService.instance.getStatus();
    return status.isVerified ? limitVerified : limitUnverified;
  }

  Future<int> getTodaySpent() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate) ?? '';
    final today = _todayStr();

    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keySpent, 0);
      return 0;
    }

    return prefs.getInt(_keySpent) ?? 0;
  }

  Future<LimitCheckResult> canPay(int amountLAK) async {
    final spent = await getTodaySpent();
    final limit = await getDailyLimit(); // ✅ ດຶງ dynamic limit
    final remaining = limit - spent;

    if (amountLAK > remaining) {
      return LimitCheckResult(
        allowed: false,
        todaySpent: spent,
        remaining: remaining,
        requested: amountLAK,
        dailyLimit: limit, // ✅ ສົ່ງ limit ທີ່ໃຊ້ຈິງ
      );
    }

    return LimitCheckResult(
      allowed: true,
      todaySpent: spent,
      remaining: remaining,
      requested: amountLAK,
      dailyLimit: limit,
    );
  }

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

class LimitCheckResult {
  final bool allowed;
  final int todaySpent;
  final int remaining;
  final int requested;
  final int dailyLimit; // ✅ ໃໝ່

  const LimitCheckResult({
    required this.allowed,
    required this.todaySpent,
    required this.remaining,
    required this.requested,
    required this.dailyLimit, // ✅ ໃໝ່
  });

  int get exceeded => requested - remaining;

  String get remainingFormatted => _fmt(remaining);
  String get todaySpentFormatted => _fmt(todaySpent);
  String get limitFormatted => _fmt(dailyLimit); // ✅ dynamic

  static String _fmt(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
