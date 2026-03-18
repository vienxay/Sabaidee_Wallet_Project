// payment_bottom_sheet.dart
// ✅ ໃຊ້ http ^1.6.0 + flutter_secure_storage
// ✅ ດຶງ token ອັດຕະໂນມັດ — ບໍ່ຕ້ອງ pass authToken
// ✅ Dialog error ເດັງຂ້າງເທິງທຸກ layer
// ✅ ngrok-skip-browser-warning header

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'payment_error_dialog.dart';

const String _baseUrl =
    'https://unpluralized-membranophonic-saniya.ngrok-free.dev';

class PaymentBottomSheet extends StatefulWidget {
  final String paymentRequest;
  final int amountSats;
  final String description;

  const PaymentBottomSheet({
    super.key,
    required this.paymentRequest,
    required this.amountSats,
    required this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required String paymentRequest,
    required int amountSats,
    required String description,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(
        paymentRequest: paymentRequest,
        amountSats: amountSats,
        description: description,
      ),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  bool _isLoading = false;

  Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  Future<void> _handleSend() async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final localNav = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      // 1. ດຶງ token
      final token = await _getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        localNav.pop();
        await PaymentErrorDialog.show(
          rootNav.context,
          errorInfo: const PaymentErrorInfo(
            type: PaymentErrorType.general,
            message: 'Session ໝົດອາຍຸ ກະລຸນາ Login ໃໝ່',
          ),
          onRetry: () =>
              rootNav.pushNamedAndRemoveUntil('/login', (_) => false),
        );
        return;
      }

      // 2. Call API ✅ ເພີ່ມ ngrok-skip-browser-warning
      final res = await http.post(
        Uri.parse('$_baseUrl/api/payment/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true', // ✅ ແກ້ ngrok warning
        },
        body: jsonEncode({
          'paymentRequest': widget.paymentRequest,
          'amount': widget.amountSats,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.statusCode == 200 && body['success'] == true) {
        localNav.pop();
        // TODO: ສະແດງ success screen
      } else {
        localNav.pop();
        await PaymentErrorDialog.show(
          rootNav.context,
          errorInfo: PaymentErrorInfo.fromApiResponse(body),
          onRetry: _handleSend,
          onGoToKYC: () => rootNav.pushNamed('/kyc'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      localNav.pop();

      await PaymentErrorDialog.show(
        rootNav.context,
        errorInfo: const PaymentErrorInfo(
          type: PaymentErrorType.network,
          message: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້\nກະລຸນາກວດສອບ internet',
        ),
        onRetry: _handleSend,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ຈຳນວນ (sats)',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            widget.amountSats.toString(),
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'BTC ↑↓',
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 28),
          const SizedBox(height: 4),
          const Text(
            'Lightning Payment',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
