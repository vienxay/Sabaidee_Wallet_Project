import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  bool _loading = false;
  String? _error;
  DecodedInvoiceModel? _decoded;
  LaoQRInfo? _laoQRInfo;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceCtrl.text = widget.invoice!;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _processInput(widget.invoice!),
      );
    }
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _amountSatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _processInput(String raw) async {
    final input = raw.trim();
    if (input.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final type = detectQRType(input);

    if (type == QRType.laoQR) {
      setState(() {
        _laoQRInfo = LaoQRInfo.fromRaw(input);
        _loading = false;
      });
    } else {
      final res = await PaymentService.instance.decodeInvoice(input);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _decoded = res.data;
          if (_decoded!.amountSats > 0) {
            _amountSatsCtrl.text = _decoded!.amountSats.toString();
          }
        } else {
          _error = res.message.isNotEmpty ? res.message : 'Invoice ບໍ່ຖືກຕ້ອງ';
        }
      });
    }
  }

  Future<void> _pay() async {
    if (_decoded == null) return;

    int sats = _decoded!.amountSats;
    if (sats <= 0) {
      sats = int.tryParse(_amountSatsCtrl.text.trim()) ?? 0;
    }

    if (sats <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນ sats ທີ່ຖືກຕ້ອງ');
      return;
    }

    setState(() => _loading = true);
    final res = await PaymentService.instance.pay(
      paymentRequest: _invoiceCtrl.text.trim(),
      memo: _decoded!.description,
      amountSats: _decoded!.amountSats == 0 ? sats : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess?.call();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentSuccessSheet(
          senderName: 'Sabaidee Wallet',
          receiverName: _decoded!.description.isNotEmpty
              ? _decoded!.description
              : 'Unknown Merchant',
          amountLAK: _decoded!.amountLAK.toDouble(),
          amountSats: sats,
          memo: _decoded!.description,
        ),
      );
    } else {
      _handleError(res);
    }
  }

  void _handleError(dynamic res) {
    PaymentErrorDialog.show(
      context,
      errorInfo: PaymentErrorInfo.fromApiResponse({
        'message': res.message,
        'requireKYC': res.requireKYC,
      }),
      onRetry: () => _processInput(_invoiceCtrl.text),
      onGoToKYC: () => Navigator.pushNamed(context, '/kyc'),
    );
  }

  void _reset() => setState(() {
    _decoded = null;
    _laoQRInfo = null;
    _error = null;
    _invoiceCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    if (_loading && _decoded == null && _laoQRInfo == null) {
      return _buildLoading();
    }

    if (_laoQRInfo != null) {
      return LaoQRPaySheet(
        qrInfo: _laoQRInfo!,
        wallet: widget.wallet,
        onSuccess: widget.onSuccess,
        onCancel: _reset,
      );
    }

    return _decoded != null ? _buildConfirmScreen() : _buildInvoiceInput();
  }

  Widget _buildLoading() => Container(
    height: 250,
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
  );

  Widget _buildInvoiceInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Text(
            'ຈ່າຍເງິນ (Lightning / LAO QR)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _invoiceCtrl,
            decoration: InputDecoration(
              hintText: 'ວາງ Invoice ຫຼື Scan QR Code',
              prefixIcon: const Icon(Icons.bolt, color: Colors.orange),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final code = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                  if (code != null) _processInput(code);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => _processInput(val),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmScreen() {
    final formatCurrency = NumberFormat("#,##0", "en_US");

    final double amountLak = _decoded?.amountLAK.toDouble() ?? 0.0;
    final int amountSats = _decoded?.amountSats ?? 0;
    final String description = _decoded?.description ?? 'Unknown Merchant';

    final String balanceStr = widget.wallet != null
        ? formatCurrency.format(widget.wallet!.balanceLAK)
        : '0';

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, size: 28, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '$balanceStr LAK',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Enter Amount',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatCurrency.format(amountLak)} LAK',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sats ${formatCurrency.format(amountSats)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (amountSats == 0) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TextField(
                      controller: _amountSatsCtrl,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'ປ້ອນຈຳນວນ Sats',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.bolt, color: Colors.orange, size: 56),
          const SizedBox(height: 16),
          Text(
            'Pay to Wallet of Sabaidee Wallet user:\n$description',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _loading ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ຈ່າຍ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
