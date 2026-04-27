import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  bool _paid = false;
  int _amountSats = 0; // ✅ ເພີ່ມ: preview sats
  int _amountLAK = 0; // ✅ ເພີ່ມ: ເກັບ LAK

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ✅ ແກ້ໄຂ: convert LAK → sats ກ່ອນ createInvoice
  Future<void> _createInvoice() async {
    final lak = int.tryParse(_amountCtrl.text.trim());
    if (lak == null || lak <= 0) {
      setState(() => _error = 'ກະລຸນາໃສ່ຈຳນວນ LAK ທີ່ຖືກຕ້ອງ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ ດຶງ rate ກ່ອນ
    final rateRes = await WalletService.instance.getRate();
    if (!mounted) return;

    if (!rateRes.success || rateRes.data == null) {
      setState(() {
        _loading = false;
        _error = 'ດຶງ rate ບໍ່ສຳເລັດ';
      });
      return;
    }

    final rate = rateRes.data!;
    // ✅ LAK → sats
    final sats = ((lak / rate.btcToLAK) * 100_000_000).round();

    if (sats <= 0) {
      setState(() {
        _loading = false;
        _error = 'ຈຳນວນ LAK ໜ້ອຍເກີນໄປ';
      });
      return;
    }

    final res = await WalletService.instance.createTopUpInvoice(
      amountSats: sats,
      memo: 'TopUp $lak LAK',
    );

    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _loading = false;
        _invoice = res.data!['paymentRequest'] as String?;
        _paymentHash = res.data!['paymentHash'] as String?;
        _amountSats = sats;
        _amountLAK = lak;
      });
      _startPolling();
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_paymentHash == null) return;
      final res = await WalletService.instance.checkPaymentStatus(
        paymentHash: _paymentHash!,
      );
      if (!mounted) return;
      if (res.success && res.data?['paid'] == true) {
        _pollTimer?.cancel();
        setState(() => _paid = true);
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context, true);
      }
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

  // ✅ ເພີ່ມ: update preview ຂະນະ user ໃສ່
  Future<void> _onAmountChanged(String val) async {
    final lak = int.tryParse(val) ?? 0;
    if (lak <= 0) {
      setState(() => _amountSats = 0);
      return;
    }
    final rateRes = await WalletService.instance.getRate();
    if (!mounted) return;
    if (rateRes.success && rateRes.data != null) {
      final sats = ((lak / rateRes.data!.btcToLAK) * 100_000_000).round();
      setState(() => _amountSats = sats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceSats = widget.wallet?.balanceSats ?? 0;
    final balanceLAK = widget.wallet?.balanceLAK ?? 0;

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
                'ໜ້າຮັບ',
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

          // ─── Balance ───────────────────────────────────────────────────
          Text(
            '$balanceSats Sats',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            '$balanceLAK LAK',
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),

          // ─── Paid ──────────────────────────────────────────────────────
          if (_paid) ...[
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 12),
            const Text(
              'ຮັບເງິນສຳເລັດ! ✅',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
          ]
          // ─── Input LAK ─────────────────────────────────────────────────
          else if (_invoice == null) ...[
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: _onAmountChanged, // ✅ preview real-time
              decoration: InputDecoration(
                hintText: 'ຈຳນວນ LAK ທີ່ຕ້ອງການ TopUp',
                hintStyle: const TextStyle(color: AppColors.textGrey),
                suffixText: 'LAK', // ✅ ສະແດງ unit
                suffixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                // ✅ preview sats
                helperText: _amountSats > 0 ? '≈ $_amountSats sats' : null,
                helperStyle: const TextStyle(color: AppColors.primary),
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
          ]
          // ─── QR + ລໍຖ້າ ────────────────────────────────────────────────
          else ...[
            // ✅ ສະແດງ amount ທີ່ຈ່າຍ
            Text(
              '$_amountLAK LAK  ≈  $_amountSats sats',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: QrImageView(
                data: _invoice!,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
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

          // ─── Button ────────────────────────────────────────────────────
          if (!_paid)
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
                        _invoice == null ? 'ສ້າງ Invoice' : 'ສຳເນົາ Invoice',
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
