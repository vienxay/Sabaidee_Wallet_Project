// ─── send_sheet.dart ─────────────────────────────────────────────────────────
// ໜ້າຈໍຫຼັກສຳລັບການສົ່ງເງິນ
// ຈັດການ: QR detection, Lightning invoice input, Lightning confirm

import 'package:flutter/material.dart';
import '../core/core.dart';
import '../models/app_models.dart';
import '../services/payment_service.dart';
import '../features/payment/payment_success_screen.dart';
import '../features/scanner/lao_qr_pay_sheet.dart';
import '../features/scanner/qr_utils.dart';
import '../features/scanner/qr_scanner_screen.dart';
import '../features/payment/payment_error_dialog.dart';

class SendSheet extends StatefulWidget {
  final WalletModel? wallet;
  final String? invoice;
  final VoidCallback? onSuccess;

  const SendSheet({super.key, this.wallet, this.invoice, this.onSuccess});

  @override
  State<SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<SendSheet> {
  final _invoiceCtrl = TextEditingController();
  final _amountSatsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  DecodedInvoiceModel? _decoded;
  LaoQRInfo? _laoQRInfo;
  bool _showBTC = true;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceCtrl.text = widget.invoice!;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleRawInput(widget.invoice!),
      );
    }
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _amountSatsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── ກວດສອບປະເພດ QR ─────────────────────────────────────────────────────
  Future<void> _handleRawInput(String raw) async {
    if (raw.trim().isEmpty) return;
    switch (detectQRType(raw.trim())) {
      case QRType.lightning:
        await _decode(raw);
      case QRType.laoQR:
        setState(() {
          _laoQRInfo = LaoQRInfo.fromRaw(raw.trim());
          _error = null;
        });
      case QRType.unknown:
        await _decode(raw);
    }
  }

  // ─── Decode Lightning Invoice ─────────────────────────────────────────────
  Future<void> _decode([String? raw]) async {
    final input = (raw ?? _invoiceCtrl.text).trim();
    if (input.isEmpty) {
      setState(() => _error = 'ກະລຸນາໃສ່ Lightning Invoice');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await PaymentService.instance.decodeInvoice(input);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _decoded = res.data;
        if (res.data != null && res.data!.amountSats > 0) {
          _amountSatsCtrl.text = res.data!.amountSats.toString();
        }
      } else {
        _error = res.message;
      }
    });
  }

  // ─── Pay Lightning ────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (_decoded == null) return;

    final sats = int.tryParse(_amountSatsCtrl.text.trim());
    if (sats == null || sats <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນ sats ທີ່ຖືກຕ້ອງ');
      return;
    }

    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await PaymentService.instance.pay(
      paymentRequest: _invoiceCtrl.text.trim(),
      memo: _descCtrl.text.trim(),
      amountSats: _decoded!.amountSats == 0 ? sats : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      localNav.pop();
      widget.onSuccess?.call();
      showModalBottomSheet(
        context: rootNav.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentSuccessSheet(
          senderName: 'Sabaidee wallet',
          receiverName: _decoded!.description.isNotEmpty
              ? _decoded!.description
              : 'Unknown',
          amountLAK: _decoded!.amountLAK.toDouble(),
          amountSats: _decoded!.amountSats,
        ),
      );
    } else {
      localNav.pop();
      await PaymentErrorDialog.show(
        rootNav.context,
        errorInfo: PaymentErrorInfo.fromApiResponse({
          'message': res.message,
          'requireKYC': res.requireKYC,
        }),
        onRetry: () => showModalBottomSheet(
          context: rootNav.context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SendSheet(
            wallet: widget.wallet,
            invoice: widget.invoice,
            onSuccess: widget.onSuccess,
          ),
        ),
        onGoToKYC: () => rootNav.pushNamed('/kyc'),
      );
    }
  }

  // ─── Scan QR ──────────────────────────────────────────────────────────────
  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(title: 'ສະແກນ QR'),
      ),
    );
    if (result != null && result.isNotEmpty) {
      _reset(keepInput: true);
      _invoiceCtrl.text = result;
      await _handleRawInput(result);
    }
  }

  // ─── Reset ────────────────────────────────────────────────────────────────
  void _reset({bool keepInput = false}) => setState(() {
    _decoded = null;
    _laoQRInfo = null;
    _error = null;
    _amountSatsCtrl.clear();
    _descCtrl.clear();
    if (!keepInput) _invoiceCtrl.clear();
  });

  String get _convertedAmount {
    final sats = int.tryParse(_amountSatsCtrl.text.trim()) ?? 0;
    if (sats == 0) return '';
    if (_showBTC) {
      final lakRate = (_decoded?.amountSats ?? 0) > 0
          ? (_decoded!.amountLAK / _decoded!.amountSats)
          : 0.0;
      final estimated = lakRate > 0 ? (sats * lakRate).round() : 0;
      return estimated > 0 ? 'about $estimated LAK' : '';
    }
    return '${(sats / 100000000).toStringAsFixed(8)} BTC';
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading && _decoded == null && _laoQRInfo == null) {
      return _buildLoading();
    }
    // LAO QR → delegate ໄປ LaoQRPaySheet
    if (_laoQRInfo != null) {
      return LaoQRPaySheet(
        qrInfo: _laoQRInfo!,
        wallet: widget.wallet,
        onSuccess: widget.onSuccess,
        onCancel: _reset,
      );
    }
    if (_decoded != null) return _buildConfirmScreen();
    return _buildInvoiceInput();
  }

  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoading() => Container(
    height: 200,
    decoration: const BoxDecoration(
      color: Color(0xFF1A1A1A),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: const Center(
      child: CircularProgressIndicator(color: Color(0xFFFFB300)),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInvoiceInput() => Container(
    margin: const EdgeInsets.all(12),
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 28,
    ),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),

        // ── ປຸ່ມສະແກນໃຫຍ່ ──
        GestureDetector(
          onTap: _scanQR,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'ສະແກນ QR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'LAO QR • Lightning Invoice',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Row(
          children: [
            Expanded(child: Divider(color: Colors.grey)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ຫຼື', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _invoiceCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'ວາງ Lightning Invoice (lnbc...)',
            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.bolt, color: AppColors.primary),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () => _handleRawInput(_invoiceCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Decode / ຕໍ່ໄປ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildConfirmScreen() {
    final lak = widget.wallet?.balanceLAK ?? 0;
    final isAmountless = _decoded!.amountSats == 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFFFB300),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$lak LAK',
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ຈຳນວນ (sats)',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountSatsCtrl,
                      enabled: isAmountless,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isAmountless
                            ? const Color(0xFFFFB300)
                            : Colors.white60,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: '0',
                        hintStyle: const TextStyle(color: Colors.white24),
                        suffixIcon: isAmountless
                            ? const Icon(
                                Icons.edit,
                                color: Color(0xFFFFB300),
                                size: 18,
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showBTC = !_showBTC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showBTC ? 'BTC' : 'LAK',
                            style: const TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.swap_vert,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _convertedAmount,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 28),
                    const Text(
                      'ລາຍລະອຽດການຈ່າຍ',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ຂຽນລາຍລະອຽດການຈ່າຍ...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Icon(Icons.bolt, color: Color(0xFFFFB300), size: 32),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _decoded!.description.isNotEmpty
                    ? _decoded!.description
                    : 'Lightning Payment',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _reset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
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
                          : const Text(
                              'Send',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
