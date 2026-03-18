// lib/features/payment/payment_screen.dart
//
// ຕົວຢ່າງ: ວິທີໃຊ້ KycGateService ໃນໜ້າ Payment
// ─────────────────────────────────────────────────────────────────────────────
// ✅ Logic ທັງໝົດຢູ່ໃນ KycGateService.checkAndGate()
//    ໜ້ານີ້ພຽງແຕ່ເອີ້ນໃຊ້ — ບໍ່ຕ້ອງຂຽນ logic ເພີ່ມ

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/kyc_gate_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  bool _processing = false;

  double get _amount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  // ── ກົດ "ຈ່າຍ" ─────────────────────────────────────────────────────────────
  Future<void> _onPayTap() async {
    if (_amount <= 0) return;

    // ✅ ໃຊ້ KycGateService — ຈັດການທຸກ case ໃຫ້ອັດຕະໂນມັດ
    //    • ຖ້າ amount ≤ limit    → proceed ທັນທີ (returns true)
    //    • ຖ້າ KYC approved      → proceed ທັນທີ (returns true)
    //    • ຖ້າ KYC pending       → ສະແດງ dialog (returns false)
    //    • ຖ້າ KYC none/rejected → ສະແດງ bottom sheet → ໄປໜ້າ KYC (returns false)
    final canProceed = await KycGateService.instance.checkAndGate(
      context: context,
      amount: _amount,
      onKycCompleted: _proceedPayment, // ← callback ຫລັງ KYC ສຳເລັດ
    );

    if (canProceed) _proceedPayment();
  }

  // ── ດຳເນີນການຈ່າຍຈິງ ───────────────────────────────────────────────────────
  Future<void> _proceedPayment() async {
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    // TODO: ເຊື່ອມ API payment ຂອງທ່ານ
    await Future.delayed(const Duration(seconds: 2)); // simulate API

    if (!mounted) return;
    setState(() => _processing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ຈ່າຍ ₭${_amount.toStringAsFixed(0)} ສຳເລັດ!'),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('ໂອນເງິນ'),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Amount field ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E5E3), width: 0.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ຈຳນວນເງິນ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7A8C87)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2420),
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₭ ',
                      prefixStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75),
                      ),
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Color(0xFFD0D8D5)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Limit notice ───────────────────────────────────────────────
            AnimatedBuilder(
              animation: _amountCtrl,
              builder: (_, __) {
                final over = _amount > kKycDailyLimit;
                if (!over) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFAC775),
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFBA7517),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ຍອດນີ້ເກີນວົງເງິນ — ຕ້ອງຢືນຢັນ KYC ກ່ອນ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF854F0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            // ── Pay button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _amount > 0 && !_processing ? _onPayTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  disabledBackgroundColor: const Color(0xFFB2DDD1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'ຈ່າຍ',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }
}
