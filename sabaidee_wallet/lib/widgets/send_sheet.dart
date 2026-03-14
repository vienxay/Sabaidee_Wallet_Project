import 'package:flutter/material.dart';
import '../core/core.dart';
import '../models/app_models.dart';
import '../services/payment_service.dart';
import 'payment_success_sheet.dart';

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
  bool _loading = false;
  String? _error;
  DecodedInvoiceModel? _decoded;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _invoiceCtrl.text = widget.invoice!;
    }
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Decode ────────────────────────────────────────────────────────
  Future<void> _decode() async {
    final raw = _invoiceCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'ກະລຸນາໃສ່ Lightning Invoice');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await PaymentService.instance.decodeInvoice(raw);

    if (!mounted) return;
    if (res.success) {
      setState(() {
        _loading = false;
        _decoded = res.data;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  // ─── Step 2: Pay ───────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (_decoded == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await PaymentService.instance.pay(
      paymentRequest: _invoiceCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess?.call(); // refresh home balance
      showModalBottomSheet(
        context: context,
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
    } else if (res.requireKYC) {
      setState(() => _error = 'ຕ້ອງຢືນຢັນ KYC ກ່ອນຈ່າຍຈຳນວນນີ້');
    } else {
      setState(() => _error = res.message);
    }
  }

  void _reset() => setState(() {
    _decoded = null;
    _error = null;
    _invoiceCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$lak LAK',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_decoded != null) ...[
            // ─── Preview ────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_decoded!.amountLAK} LAK',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${_decoded!.amountSats} sats',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.bolt, color: AppColors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              _decoded!.description.isNotEmpty
                  ? _decoded!.description
                  : 'Lightning Payment',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _reset,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'ແກ້ໄຂ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
          ] else ...[
            // ─── Invoice Input ──────────────────────────────────────────────────
            TextField(
              controller: _invoiceCtrl,
              decoration: InputDecoration(
                hintText: 'ວາງ Lightning Invoice (lnbc...)',
                hintStyle: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.bolt, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primary,
                  ),
                  onPressed: () {},
                ),
                errorText: _error,
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _decode,
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
                    : const Text(
                        'Decode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
