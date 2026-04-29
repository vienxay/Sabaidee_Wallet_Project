// ─── lib/features/payment/transfer_confirm_screen.dart ──────────────────────
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'payment_success_screen.dart';
import 'payment_error_dialog.dart';
import '../kyc/kyc_screen.dart';
import '../../services/daily_limit_service.dart';

const String _baseUrl =
    'https://unpluralized-membranophonic-saniya.ngrok-free.dev';

class TransferConfirmScreen extends StatefulWidget {
  final String senderName;
  final String senderAccount;
  final String? senderAvatarUrl;

  final String receiverName;
  final String receiverAccount;
  final String? receiverAvatarUrl;

  final int amountLAK;
  final int feeLAK;
  final String memo;

  const TransferConfirmScreen({
    super.key,
    this.senderName = ' ',
    this.senderAccount = ' ',
    this.senderAvatarUrl,
    this.receiverName = ' ',
    this.receiverAccount = ' ',
    this.receiverAvatarUrl,
    required this.amountLAK,
    this.feeLAK = 0,
    this.memo = '',
  });

  @override
  State<TransferConfirmScreen> createState() => _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends State<TransferConfirmScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Confirm ──────────────────────────────────────────────────────────────
  Future<void> _onConfirm() async {
    setState(() => _loading = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null || !mounted) {
        setState(() => _loading = false);
        return;
      }

      final res = await http.post(
        Uri.parse('$_baseUrl/api/payment/laoqr/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'amountLAK': widget.amountLAK,
          'merchantName': widget.receiverName,
          'description': widget.memo,
        }),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        // ✅ record ການຈ່າຍ — ວົງເງິນຫຼຸດຕາມຈິງ
        await DailyLimitService.instance.recordPayment(widget.amountLAK);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: PaymentSuccessSheet(
                  senderName: widget.senderName,
                  senderAvatarUrl: widget.senderAvatarUrl, // ✅ ສົ່ງຮູບ sender
                  receiverName: widget.receiverName,
                  receiverAvatarUrl:
                      widget.receiverAvatarUrl, // ✅ ສົ່ງຮູບ receiver
                  amountLAK: widget.amountLAK.toDouble(),
                  amountSats: 0,
                  feeLAK: widget.feeLAK,
                  memo: widget.memo,
                  closeToHome: true,
                ),
              ),
            ),
          ),
        );
      } else {
        final errorInfo = PaymentErrorInfo.fromApiResponse(body);
        await PaymentErrorDialog.show(
          context,
          errorInfo: errorInfo,
          onGoToKYC: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KycScreen()),
          ),
          onRetry: () => _onConfirm(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      await PaymentErrorDialog.show(
        context,
        errorInfo: const PaymentErrorInfo(
          type: PaymentErrorType.network,
          message: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ server ໄດ້',
        ),
        onRetry: () => _onConfirm(),
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    children: [
                      _buildDetailsCard(),
                      const SizedBox(height: 32),
                      _buildConfirmButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8820C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'ຢືນຢັນ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 28),
          _buildAccountRow(
            label: 'ຈາກບັນຊີ',
            name: widget.senderName,
            account: widget.senderAccount,
            avatarUrl: widget.senderAvatarUrl,
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                  size: 16,
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
          const SizedBox(height: 16),
          _buildAccountRow(
            label: 'ຫາບັນຊີ',
            name: widget.receiverName,
            account: widget.receiverAccount,
            avatarUrl: widget.receiverAvatarUrl,
            icon: Icons.store_mall_directory_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow({
    required String label,
    required String name,
    required String account,
    String? avatarUrl,
    IconData icon = Icons.person,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                : Icon(icon, color: const Color(0xFFE8820C), size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
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
      ),
    ],
  );

  // ─── Details Card ─────────────────────────────────────────────────────────
  Widget _buildDetailsCard() => Container(
    margin: const EdgeInsets.only(top: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _detailRow(
          label: 'ຈຳນວນເງິນ:',
          value: '₭ ${_fmt(widget.amountLAK)}',
          valueColor: const Color(0xFF1565C0),
          isFirst: true,
        ),
        _divider(),
        _detailRow(
          label: 'ຄ່າທຳນຽມ:',
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '₭',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.feeLAK == 0 ? '0' : _fmt(widget.feeLAK),
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _divider(),
        _detailRow(
          label: 'ເນື້ອໃນ:',
          value: widget.memo.isEmpty ? '-' : widget.memo,
          valueColor: widget.memo.isEmpty
              ? Colors.grey[400]!
              : const Color(0xFF1A1A1A),
          isLast: true,
        ),
      ],
    ),
  );

  Widget _detailRow({
    required String label,
    String? value,
    Widget? valueWidget,
    Color valueColor = const Color(0xFF1565C0),
    bool isFirst = false,
    bool isLast = false,
  }) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: isFirst ? 20 : 14,
      bottom: isLast ? 20 : 14,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        valueWidget ??
            Text(
              value ?? '',
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
      ],
    ),
  );

  Widget _divider() => const Divider(
    color: Color(0xFFF0EAE0),
    height: 1,
    thickness: 1,
    indent: 20,
    endIndent: 20,
  );

  // ─── Confirm Button ───────────────────────────────────────────────────────
  Widget _buildConfirmButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: _loading ? null : _onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8820C),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE8820C).withValues(alpha: 0.6),
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
              'ຢືນຢັນ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );
}
