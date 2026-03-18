// lib/services/kyc_gate_service.dart
// ✅ ໃຊ້ StorageService.instance.setString/getString ແທນ SharedPreferences ໂດຍກົງ
//    ໃຫ້ consistent ກັບ storage pattern ຂອງທ່ານ

import 'package:flutter/material.dart';
import '../models/kyc_status.dart';
import 'kyc_service.dart';
import 'storage_service.dart'; // ✅ ໃຊ້ StorageService ຂອງທ່ານ

const double kKycDailyLimit = 5_000_000; // LAK — ແກ້ຕາມຕ້ອງການ
const _kStatus = 'kyc_status'; // key ໃນ SharedPreferences

class KycGateService {
  KycGateService._();
  static final instance = KycGateService._();

  // ── Read / Write ───────────────────────────────────────────────────────────
  Future<KycStatus> getStatus() async {
    final raw = await StorageService.instance.getString(_kStatus);
    return KycStatusX.fromString(raw);
  }

  Future<void> saveStatus(KycStatus s) async =>
      StorageService.instance.setString(_kStatus, s.name);

  Future<void> clearStatus() async => StorageService.instance.remove(_kStatus);

  // ── Sync ຈາກ backend ─────────────────────────────────────────────────────
  // ເອີ້ນໃນ main() ຫລັງ login ທຸກຄັ້ງ
  Future<void> syncFromBackend() async {
    final res = await KycService.checkMyStatus(); // GET /api/kyc
    if (res['success'] == true) {
      final status = res['status'] as KycStatus;
      await saveStatus(status);
    }
  }

  // ── Gate ───────────────────────────────────────────────────────────────────
  /// ກວດສອບ KYC ກ່ອນຈ່າຍ
  /// Returns true = ດຳເນີນການໄດ້, false = ຕ້ອງ KYC ກ່ອນ
  Future<bool> checkAndGate({
    required BuildContext context,
    required double amount,
    required VoidCallback onKycCompleted,
  }) async {
    if (amount <= kKycDailyLimit) return true; // ຍອດຕ່ຳ → ຜ່ານ

    final status = await getStatus();

    if (status.isVerified) return true; // ✅ KYC ຜ່ານ → ຜ່ານ

    if (status.isSubmitted) {
      _showSubmittedDialog(context); // ລໍ admin approve
      return false;
    }

    // none / rejected → ນຳໄປ KYC
    _showKycSheet(context, amount: amount, onKycCompleted: onKycCompleted);
    return false;
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  void _showSubmittedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFBA7517),
              size: 22,
            ),
            SizedBox(width: 10),
            Text('ລໍຖ້າການຢືນຢັນ'),
          ],
        ),
        content: const Text(
          'ທີມງານກຳລັງກວດສອບ KYC ຂອງທ່ານ\nກະລຸນາລໍຖ້າ 1–3 ວັນທຳການ\nທ່ານຈະໄດ້ຮັບ SMS ຫລັງການຢືນຢັນ',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ຮັບຊາບ',
              style: TextStyle(color: Color(0xFF1D9E75)),
            ),
          ),
        ],
      ),
    );
  }

  void _showKycSheet(
    BuildContext context, {
    required double amount,
    required VoidCallback onKycCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _KycRequiredSheet(
        amount: amount,
        onStartKyc: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            '/kyc',
            arguments: KycRouteArgs(onCompleted: onKycCompleted),
          );
        },
      ),
    );
  }
}

// ─── Route Args ───────────────────────────────────────────────────────────────
class KycRouteArgs {
  final VoidCallback? onCompleted;
  const KycRouteArgs({this.onCompleted});
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────
class _KycRequiredSheet extends StatelessWidget {
  final double amount;
  final VoidCallback onStartKyc;
  const _KycRequiredSheet({required this.amount, required this.onStartKyc});

  String _fmt(double v) =>
      '₭ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF1D9E75),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ຕ້ອງຢືນຢັນຕົວຕົນ (KYC)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2420),
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow('ຍອດທີ່ຈ່າຍ', _fmt(amount), warn: true),
            const SizedBox(height: 6),
            _InfoRow('ວົງເງິນໂດຍບໍ່ KYC', _fmt(kKycDailyLimit), warn: false),
            const SizedBox(height: 16),
            const Text(
              'ເມື່ອ KYC ຜ່ານ ທ່ານຈະໂອນໄດ້ໂດຍບໍ່ຈຳກັດ\nແລະ ບໍ່ຕ້ອງ KYC ອີກ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8C87),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onStartKyc,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ເລີ່ມຢືນຢັນຕົວຕົນ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ຍົກເລີກ',
                  style: TextStyle(color: Color(0xFF7A8C87)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool warn;
  const _InfoRow(this.label, this.value, {required this.warn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFAEEDA) : const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(10),
        border: warn
            ? null
            : Border.all(color: const Color(0xFFE0E5E3), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: warn ? const Color(0xFF854F0B) : const Color(0xFF7A8C87),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: warn ? const Color(0xFF854F0B) : const Color(0xFF1A2420),
            ),
          ),
        ],
      ),
    );
  }
}
