// ─── lao_qr_pay_sheet.dart ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/payment_service.dart';
import '../payment/payment_success_screen.dart';
import 'qr_utils.dart';

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
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  int _todaySpent = 0;
  int _dailyLimit = 2000000;
  bool _limitLoaded = false;

  static const _quickAmounts = ['10000', '20000', '50000', '100000'];

  @override
  void initState() {
    super.initState();
    _loadLimit();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLimit() async {
    final result = await PaymentService.instance.getLaoQRLimitStatus();
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _todaySpent = result.data!.todaySpent;
        _dailyLimit = result.data!.dailyLimit;
        _limitLoaded = true;
      });
    } else {
      setState(() => _limitLoaded = true);
    }
  }

  int get _remaining => _dailyLimit - _todaySpent;

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  // ─── Pay ──────────────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    setState(() => _loading = true);

    final result = await PaymentService.instance.payLaoQR(
      amountLAK: amount,
      merchantName: widget.qrInfo.merchantName,
      bank: widget.qrInfo.bank,
      qrRaw: widget.qrInfo.raw,
      description: 'LAO QR Payment',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      localNav.pop();
      widget.onSuccess?.call();
      if (!mounted) return;
      showModalBottomSheet(
        context: rootNav.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentSuccessSheet(
          senderName: 'Sabaidee Wallet',
          receiverName: widget.qrInfo.merchantName,
          amountLAK: amount.toDouble(),
          amountSats: 0,
          closeToHome: true,
        ),
      );
    } else if (result.requireKYC) {
      _showKycDialog(result.message.isNotEmpty ? result.message : 'ເກີນວົງເງິນ — ຕ້ອງຢືນຢັນ KYC');
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(result.message.isNotEmpty ? result.message : 'ເກີດຂໍ້ຜິດພາດ'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Orange Header ──
          _buildHeader(),

          // ── Body ──
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Daily limit bar ──
                    if (_limitLoaded) ...[
                      _buildLimitBar(),
                      const SizedBox(height: 20),
                    ],

                    // ── Amount field ──
                    _buildLabel('ຈຳນວນເງິນ (LAK)', required: true),
                    const SizedBox(height: 8),
                    _buildAmountField(),
                    const SizedBox(height: 12),

                    // ── Quick chips ──
                    _buildQuickChips(),
                    const SizedBox(height: 28),

                    // ── ສົ່ງເງິນ button ──
                    _buildPayButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Orange Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8820C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // ── Title + close ──
          Row(
            children: [
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'ຈ່າຍ QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 20),

          // ── ຈາກ ──
          _buildPartyRow(
            label: 'ຈາກບັນຊີ',
            name: 'Sabaidee Wallet',
            account: 'ສາບາຍດີ Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),

          // ── Divider + arrow ──
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── ຫາ (Merchant) ──
          _buildPartyRow(
            label: 'ທາບັນຊີ',
            name: widget.qrInfo.merchantName,
            account: widget.qrInfo.bank,
            icon: Icons.store_mall_directory_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow({
    required String label,
    required String name,
    required String account,
    required IconData icon,
    String? avatarUrl,
  }) => Row(
    children: [
      // Avatar
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: avatarUrl != null
            ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
            : Icon(icon, color: const Color(0xFFE8820C), size: 24),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            account,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ],
  );

  // ── Limit Bar ────────────────────────────────────────────────────────────
  Widget _buildLimitBar() {
    final progress = (_todaySpent / _dailyLimit).clamp(0.0, 1.0);
    final isNear = progress >= 0.8;
    final barColor = isNear ? const Color(0xFFEF4444) : const Color(0xFFE8820C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ວົງເງິນຄົງເຫຼືອວັນນີ້',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _fmt(_remaining),
                    style: TextStyle(
                      color: isNear
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE8820C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${_fmt(_dailyLimit)} ກີບ',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ── Form fields ──────────────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      children: required
          ? [
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFE8820C)),
              ),
            ]
          : [],
    ),
  );

  Widget _buildAmountField() => TextFormField(
    controller: _amountCtrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A),
    ),
    decoration: InputDecoration(
      hintText: 'ປ້ອນຈຳນວນເງິນ',
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixText: 'LAK  ',
      prefixStyle: const TextStyle(
        color: Color(0xFFE8820C),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8820C), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ຈຳນວນເງິນ';
      final n = int.tryParse(v.replaceAll(',', ''));
      if (n == null || n < 1000) return 'ຕ້ອງຢ່າງໜ້ອຍ 1,000 ກີບ';
      return null;
    },
    onChanged: (_) => setState(() {}),
  );

  Widget _buildQuickChips() => Wrap(
    spacing: 8,
    children: _quickAmounts.map((amt) {
      final isSelected = _amountCtrl.text == amt;
      return GestureDetector(
        onTap: () => setState(() => _amountCtrl.text = amt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8820C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE8820C)
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            '${int.parse(amt) ~/ 1000}k ກີບ',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildPayButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: _loading ? null : _pay,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8820C),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE8820C).withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Text(
              'ສົ່ງເງິນ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );

  // ── KYC required dialog ──────────────────────────────────────────────────
  void _showKycDialog(String message) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFE8820C)),
            SizedBox(width: 8),
            Text('ຕ້ອງຢືນຢັນ KYC'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              localNav.pop();
              rootNav.pushNamed('/kyc');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8820C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ຢືນຢັນ KYC'),
          ),
        ],
      ),
    );
  }
}
