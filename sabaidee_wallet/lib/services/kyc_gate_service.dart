// lib/services/kyc_gate_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kyc_status.dart';
import 'kyc_service.dart';
import 'storage_service.dart';
import 'daily_limit_service.dart';

const double kKycDailyLimit = 5_000_000;
const _kStatus = 'user_kyc_status_v1';

// ─── Route Args ───────────────────────────────────────────────────────────────
// ✅ ຍ້າຍມາໄວ້ທີ່ນີ້ (single source of truth) — kyc_screen.dart import ຈາກນີ້
class KycRouteArgs {
  final VoidCallback? onCompleted;
  final KycExistingData? existingData; // ✅ ສົ່ງຂໍ້ມູນເກົ່າ ສຳລັບ re-submit
  const KycRouteArgs({this.onCompleted, this.existingData});
}

class KycExistingData {
  final String? fullName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? email;
  final String? passportNumber;
  final DateTime? expiryDate;
  final String? reviewNote;

  const KycExistingData({
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.nationality,
    this.email,
    this.passportNumber,
    this.expiryDate,
    this.reviewNote,
  });

  /// ✅ Parse ຈາກ JSON response ຂອງ GET /api/kyc
  factory KycExistingData.fromJson(Map<String, dynamic> json) {
    final kyc = json['kyc'] as Map<String, dynamic>?;
    if (kyc == null) return const KycExistingData();
    return KycExistingData(
      fullName: kyc['fullName'] as String?,
      gender: kyc['gender'] as String?,
      dateOfBirth: _parseDate(kyc['dob']),
      nationality: kyc['nationality'] as String?,
      email: kyc['email'] as String?,
      passportNumber: kyc['passportNumber'] as String?,
      expiryDate: _parseDate(kyc['expiryDate']),
      reviewNote: kyc['reviewNote'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v as String);
    } catch (_) {
      return null;
    }
  }
}

// ─── KycGateService ───────────────────────────────────────────────────────────
class KycGateService {
  KycGateService._();
  static final instance = KycGateService._();

  // ── Read / Write ──────────────────────────────────────────────────────────
  Future<KycStatus> getStatus() async {
    final raw = await StorageService.instance.getString(_kStatus);
    return KycStatusX.fromString(raw);
  }

  Future<void> saveStatus(KycStatus s) async =>
      StorageService.instance.setString(_kStatus, s.name);

  Future<void> clearStatus() async => StorageService.instance.remove(_kStatus);

  // ── Sync ຈາກ backend ──────────────────────────────────────────────────────
  Future<void> syncFromBackend() async {
    final res = await KycService.checkMyStatus();
    if (res['success'] == true) {
      final rawStatus = res['kycStatus'] as String?;
      if (rawStatus != null) {
        await saveStatus(KycStatusX.fromString(rawStatus));
      }
    }
  }

  // ── Gate ──────────────────────────────────────────────────────────────────
  Future<bool> checkAndGate({
    required BuildContext context,
    required double amount,
    required VoidCallback onKycCompleted,
  }) async {
    final limit = await DailyLimitService.instance.getDailyLimit();
    if (amount <= limit) return true;

    final status = await getStatus();
    if (!context.mounted) return false;

    if (status.isVerified) return true;
    if (status.isSubmitted) {
      _showSubmittedDialog(context);
      return false;
    }

    // ✅ KYC ຖືກ rejected → ສະແດງ sheet ໃຫ້ re-submit ພ້ອມຂໍ້ມູນເກົ່າ
    if (status.isRejected) {
      final existing = await _fetchExistingData();
      if (!context.mounted) return false;
      _showRejectedSheet(
        context,
        amount: amount,
        existing: existing,
        onKycCompleted: onKycCompleted,
      );
      return false;
    }

    // ຍັງບໍ່ເຄີຍ KYC
    _showKycSheet(context, amount: amount, onKycCompleted: onKycCompleted);
    return false;
  }

  // ── Fetch existing KYC data (ສຳລັບ pre-fill) ─────────────────────────────
  Future<KycExistingData?> _fetchExistingData() async {
    try {
      final res = await KycService.checkMyStatus();
      if (res['success'] == true) return KycExistingData.fromJson(res);
    } catch (_) {}
    return null;
  }

  // ── Navigate to KYC screen ────────────────────────────────────────────────
  void _goToKyc(
    BuildContext context, {
    KycExistingData? existing,
    required VoidCallback onKycCompleted,
  }) {
    Navigator.of(context).pushNamed(
      '/kyc',
      arguments: KycRouteArgs(
        onCompleted: onKycCompleted,
        existingData: existing,
      ),
    );
  }

  // ── Dialog: pending ───────────────────────────────────────────────────────
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
          'ທີມງານກຳລັງກວດສອບ KYC ຂອງທ່ານ\n'
          'ກະລຸນາລໍຖ້າ 1–3 ວັນທຳການ\n'
          'ທ່ານຈະໄດ້ຮັບ Email ຫລັງການຢືນຢັນ',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Text(
              'ຮັບຊາບ',
              style: TextStyle(color: Color(0xFF1D9E75)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheet: ຍັງບໍ່ KYC ────────────────────────────────────────────────────
  void _showKycSheet(
    BuildContext context, {
    required double amount,
    required VoidCallback onKycCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _KycRequiredSheet(
        amount: amount,
        onStartKyc: () {
          Navigator.of(sheetCtx).pop();
          Future.microtask(() {
            if (!context.mounted) return;
            _goToKyc(context, onKycCompleted: onKycCompleted);
          });
        },
      ),
    );
  }

  // ✅ Sheet: KYC rejected → ສະແດງ banner ເຫດຜົນ + ປຸ່ມ "ແກ້ໄຂ & ສົ່ງຄືນ"
  void _showRejectedSheet(
    BuildContext context, {
    required double amount,
    KycExistingData? existing,
    required VoidCallback onKycCompleted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _KycRejectedSheet(
        amount: amount,
        reviewNote: existing?.reviewNote,
        onResubmit: () {
          Navigator.of(sheetCtx).pop();
          Future.microtask(() {
            if (!context.mounted) return;
            _goToKyc(
              context,
              existing: existing,
              onKycCompleted: onKycCompleted,
            );
          });
        },
      ),
    );
  }
}

// ─── Sheet: ຍັງບໍ່ KYC ───────────────────────────────────────────────────────
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
            _PrimaryButton(label: 'ເລີ່ມຢືນຢັນຕົວຕົນ', onTap: onStartKyc),
            const SizedBox(height: 10),
            _CancelButton(),
          ],
        ),
      ),
    );
  }
}

// ✅ Sheet: KYC rejected ────────────────────────────────────────────────────────
class _KycRejectedSheet extends StatelessWidget {
  final double amount;
  final String? reviewNote;
  final VoidCallback onResubmit;

  const _KycRejectedSheet({
    required this.amount,
    required this.onResubmit,
    this.reviewNote,
  });

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
            // Icon — ສີແດງ ສຳລັບ rejected
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_outlined,
                color: Color(0xFFD94040),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'KYC ຂອງທ່ານຖືກປະຕິເສດ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2420),
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Banner ສາເຫດ reject
            if (reviewNote != null && reviewNote!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF854F0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reviewNote!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF854F0B),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            _InfoRow('ຍອດທີ່ຈ່າຍ', _fmt(amount), warn: true),
            const SizedBox(height: 6),
            _InfoRow('ວົງເງິນໂດຍບໍ່ KYC', _fmt(kKycDailyLimit), warn: false),
            const SizedBox(height: 16),
            const Text(
              'ແກ້ໄຂຂໍ້ມູນໃຫ້ຖືກຕ້ອງແລ້ວສົ່ງ KYC ຄືນໃໝ່\nເພື່ອໂອນເງິນໄດ້ໂດຍບໍ່ຈຳກັດ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A8C87),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),

            // ✅ ປຸ່ມ re-submit
            _PrimaryButton(label: 'ແກ້ໄຂ & ສົ່ງ KYC ຄືນໃໝ່', onTap: onResubmit),
            const SizedBox(height: 10),
            _CancelButton(),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _CancelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop();
      },
      child: const Text('ຍົກເລີກ', style: TextStyle(color: Color(0xFF7A8C87))),
    ),
  );
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
