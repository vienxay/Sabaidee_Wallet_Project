// ─── lao_qr_pay_sheet.dart ───────────────────────────────────────────────────
// ໜ້າຈໍປ້ອນຈຳນວນເງິນສຳລັບ LAO QR (Demo Mode)
// • ວົງເງິນ 2,000,000 ກີບ/ມື້
// • ເກີນວົງເງິນ → KYC (ເທື່ອດຽວ)

import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../payment/payment_success_screen.dart';
import 'qr_utils.dart';
import '../../services/daily_limit_service.dart';

class LaoQRPaySheet extends StatefulWidget {
  final LaoQRInfo qrInfo;
  final WalletModel? wallet;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const LaoQRPaySheet({
    super.key,
    required this.qrInfo,
    this.wallet,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<LaoQRPaySheet> createState() => _LaoQRPaySheetState();
}

class _LaoQRPaySheetState extends State<LaoQRPaySheet> {
  final _amountCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // ── ຍອດໃຊ້ວັນນີ້ (load ເວລາ init) ──
  int _todaySpent = 0;
  bool _limitLoaded = false;

  static const _quickAmounts = ['10000', '20000', '50000', '100000'];

  @override
  void initState() {
    super.initState();
    _loadTodaySpent();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // ─── Load ຍອດວັນນີ້ ──────────────────────────────────────────────────────
  Future<void> _loadTodaySpent() async {
    final spent = await DailyLimitService.instance.getTodaySpent();
    if (!mounted) return;
    setState(() {
      _todaySpent = spent;
      _limitLoaded = true;
    });
  }

  int get _remaining => DailyLimitService.dailyLimitLAK - _todaySpent;

  // ─── Demo Pay ──────────────────────────────────────────────────────────────
  Future<void> _pay() async {
    final amount = int.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນເງິນທີ່ຖືກຕ້ອງ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // ── ກວດ daily limit ──
    final check = await DailyLimitService.instance.canPay(amount);

    if (!mounted) return;

    if (!check.allowed) {
      setState(() => _loading = false);
      await _showLimitExceededDialog(check);
      return;
    }

    // ── Demo: ຈຳລອງການສົ່ງ ──
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // ── ບັນທຶກຍອດ ──
    await DailyLimitService.instance.recordPayment(amount);

    setState(() => _loading = false);

    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    localNav.pop();
    widget.onSuccess?.call();

    showModalBottomSheet(
      context: rootNav.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSuccessSheet(
        senderName: 'Sabaidee wallet',
        receiverName: widget.qrInfo.merchantName,
        amountLAK: amount.toDouble(),
        amountSats: 0,
      ),
    );
  }

  // ─── Dialog ເກີນວົງເງິນ → KYC ───────────────────────────────────────────
  Future<void> _showLimitExceededDialog(LimitCheckResult check) async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ໄອຄອນ ──
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // ── ຫົວຂໍ້ ──
              const Text(
                'ເກີນວົງເງິນຕໍ່ມື້',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // ── ລາຍລະອຽດ ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _limitRow(
                      'ຍອດໃຊ້ວັນນີ້',
                      '${check.todaySpentFormatted} ກີບ',
                      Colors.white60,
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    _limitRow(
                      'ວົງເງິນຄົງເຫຼືອ',
                      '${check.remainingFormatted} ກີບ',
                      const Color(0xFFFFB300),
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    _limitRow(
                      'ຈຳນວນທີ່ຕ້ອງການ',
                      '${_fmt(check.requested)} ກີບ',
                      const Color(0xFFFF5252),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'ເພື່ອຍົກລະດັບວົງເງິນ ກະລຸນາຢືນຢັນຕົວຕົນ (KYC)\n'
                'ທຳຄັ້ງດຽວ — ໃຊ້ໄດ້ຕະຫຼອດ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ── ປຸ່ມ ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // ປິດ dialog
                    localNav.pop(); // ປິດ sheet
                    rootNav.pushNamed('/kyc');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.black87,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ຢືນຢັນຕົວຕົນ (KYC)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'ຍົກເລີກ',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _limitRow(String label, String value, Color valueColor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  static String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 20),
            _buildMerchantInfo(),
            const SizedBox(height: 8),
            _buildDemoBadge(),
            const SizedBox(height: 16),

            // ── Daily limit bar ──
            if (_limitLoaded) _buildLimitBar(),
            const SizedBox(height: 20),

            _buildAmountInput(),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Daily Limit Progress Bar ───────────────────────────────────────────────
  Widget _buildLimitBar() {
    final progress = (_todaySpent / DailyLimitService.dailyLimitLAK).clamp(
      0.0,
      1.0,
    );
    final isNearLimit = progress >= 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ວົງເງິນຄົງເຫຼືອວັນນີ້',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _fmt(_remaining),
                    style: TextStyle(
                      color: isNearLimit
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB300),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${_fmt(DailyLimitService.dailyLimitLAK)} ກີບ',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(
              isNearLimit ? const Color(0xFFFF5252) : const Color(0xFFFFB300),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Sub-widgets ───────────────────────────────────────────────────────────
  Widget _buildHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildMerchantInfo() => Column(
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
        ),
        child: const Icon(Icons.qr_code_2, color: Color(0xFFFFB300), size: 36),
      ),
      const SizedBox(height: 12),
      Text(
        widget.qrInfo.merchantName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.qrInfo.bank,
          style: const TextStyle(color: Color(0xFFFFB300), fontSize: 12),
        ),
      ),
    ],
  );

  Widget _buildDemoBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.withOpacity(0.4)),
    ),
    child: const Text(
      '⚠️ Demo Mode — ບໍ່ເຊື່ອມຕໍ່ LAPNET',
      style: TextStyle(color: Colors.orange, fontSize: 11),
    ),
  );

  Widget _buildAmountInput() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text(
          'ຈຳນວນເງິນ (ກີບ)',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: '0',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const Text(
          'LAK',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts
              .map(
                (amt) => _QuickAmountChip(
                  label: _quickLabel(amt),
                  onTap: () {
                    _amountCtrl.text = amt;
                    setState(() => _error = null);
                  },
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _buildButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _loading ? null : widget.onCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'ຍົກເລີກ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white60,
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: _loading ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.black87, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ສົ່ງເງິນ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ],
  );

  String _quickLabel(String amt) {
    final n = int.parse(amt);
    return n >= 1000 ? '${n ~/ 1000}k' : amt;
  }
}

// ─── Quick Amount Chip ────────────────────────────────────────────────────────
class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFFFB300), fontSize: 13),
      ),
    ),
  );
}
