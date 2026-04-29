import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'kyc_gate_service.dart';
import 'storage_service.dart'; // ✅ ເພີ່ມ
import '../models/kyc_status.dart';

class DailyLimitService {
  DailyLimitService._();
  static final instance = DailyLimitService._();

  // ✅ ວົງເງິນຕາມ KYC status
  static const int limitUnverified = 2000000; // 2 ລ້ານ/ມື້
  static const int limitVerified = 100000000; // 100 ລ້ານ/ມື້

  // ✅ key ແຍກຕາມ userId — ແຕ່ລະ user ມີວົງເງິນຂອງຕົນເອງ
  Future<String> _keySpent() async {
    final userId = await _getUserId();
    return 'lao_qr_daily_spent_$userId';
  }

  Future<String> _keyDate() async {
    final userId = await _getUserId();
    return 'lao_qr_daily_date_$userId';
  }

  // ✅ ດຶງ userId ຈາກ JWT token
  Future<String> _getUserId() async {
    try {
      final token = await StorageService.instance.getToken();
      if (token == null) return 'guest';

      final parts = token.split('.');
      if (parts.length != 3) return 'guest';

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload['id'] as String? ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  // ✅ ດຶງ limit ຕາມ KYC status
  Future<int> getDailyLimit() async {
    final status = await KycGateService.instance.getStatus();
    return status.isVerified ? limitVerified : limitUnverified;
  }

  Future<int> getTodaySpent() async {
    final prefs = await SharedPreferences.getInstance();
    final keySpent = await _keySpent();
    final keyDate = await _keyDate();
    final savedDate = prefs.getString(keyDate) ?? '';
    final today = _todayStr();

    // ✅ ຂຶ້ນວັນໃໝ່ → reset ວົງເງິນ
    if (savedDate != today) {
      await prefs.setString(keyDate, today);
      await prefs.setInt(keySpent, 0);
      return 0;
    }
    return prefs.getInt(keySpent) ?? 0;
  }

  Future<LimitCheckResult> canPay(int amountLAK) async {
    final spent = await getTodaySpent();
    final limit = await getDailyLimit();
    final remaining = limit - spent;

    return LimitCheckResult(
      allowed: amountLAK <= remaining,
      todaySpent: spent,
      remaining: remaining,
      requested: amountLAK,
      dailyLimit: limit,
    );
  }

  Future<void> recordPayment(int amountLAK) async {
    final prefs = await SharedPreferences.getInstance();
    final keySpent = await _keySpent();
    final keyDate = await _keyDate();
    final today = _todayStr();

    await prefs.setString(keyDate, today);
    final current = prefs.getInt(keySpent) ?? 0;
    await prefs.setInt(keySpent, current + amountLAK);
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
  final int dailyLimit;

  const LimitCheckResult({
    required this.allowed,
    required this.todaySpent,
    required this.remaining,
    required this.requested,
    required this.dailyLimit,
  });

  int get exceeded => requested - remaining;

  String get remainingFormatted => _fmt(remaining);
  String get todaySpentFormatted => _fmt(todaySpent);
  String get limitFormatted => _fmt(dailyLimit);

  static String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
