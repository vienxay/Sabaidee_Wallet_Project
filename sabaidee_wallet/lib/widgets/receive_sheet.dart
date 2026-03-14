import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/core.dart';
import '../models/app_models.dart';
import '../services/wallet_service.dart';

class ReceiveSheet extends StatefulWidget {
  final WalletModel? wallet;
  const ReceiveSheet({super.key, this.wallet});
  @override
  State<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<ReceiveSheet> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  String? _invoice;
  String? _paymentHash;
  String? _error;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    final sats = int.tryParse(_amountCtrl.text.trim());
    if (sats == null || sats <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນ sats ທີ່ຖືກຕ້ອງ');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await WalletService.instance.createTopUpInvoice(
      amountSats: sats,
    );

    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _loading = false;
        _invoice = res.data!['paymentRequest'] as String?;
        _paymentHash = res.data!['paymentHash'] as String?;
      });
      _startPolling();
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  // ─── Poll ທຸກ 5 ວິ ກວດວ່າໄດ້ຮັບເງິນ ──────────────────────────────────────
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_paymentHash == null) return;
      // TODO: ເອີ້ນ TransactionService.instance.checkPaymentStatus(_paymentHash!)
      // ຖ້າ paid → ປິດ sheet + refresh home
    });
  }

  void _copyInvoice() {
    if (_invoice == null) return;
    Clipboard.setData(ClipboardData(text: _invoice!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ສຳເນົາ Invoice ແລ້ວ'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sats = widget.wallet?.balanceSats ?? 0;
    final lak = widget.wallet?.balanceLAK ?? 0;

    return Container(
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Receive',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance
          Text(
            '$sats Sats',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            '$lak LAK',
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),

          if (_invoice == null) ...[
            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'ຈຳນວນ sats (ເຊັ່ນ: 1000)',
                hintStyle: const TextStyle(color: AppColors.textGrey),
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
          ] else ...[
            // QR
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 156,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _copyInvoice,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${_invoice!.substring(0, 20)}...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'ລໍຖ້າການຈ່າຍ...',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : (_invoice == null ? _createInvoice : _copyInvoice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  : Text(
                      _invoice == null ? 'Create Invoice' : 'ສຳເນົາ Invoice',
                      style: const TextStyle(
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
  }
}
