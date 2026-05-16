// ─── lib/screens/withdraw/withdraw_success_screen.dart ──────────────────────
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// format destination ໃຫ້ user-friendly
String _fmtDest(String dest) {
  if (dest.isEmpty) return 'Lightning Network';
  if (dest.contains('@') && !dest.toLowerCase().startsWith('lnbc')) return dest;
  if (dest.toUpperCase().startsWith('LNURL')) return 'LNURL Payment';
  if (dest.toLowerCase().startsWith('lnbc') && dest.length > 20) {
    return '${dest.substring(0, 12)}...${dest.substring(dest.length - 8)}';
  }
  if (dest.length > 30) {
    return '${dest.substring(0, 15)}...${dest.substring(dest.length - 8)}';
  }
  return dest;
}

class WithdrawSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const WithdrawSuccessScreen({super.key, required this.data});

  @override
  State<WithdrawSuccessScreen> createState() => _WithdrawSuccessScreenState();
}

class _WithdrawSuccessScreenState extends State<WithdrawSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final fmt = NumberFormat('#,###', 'en_US');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    final createdAt = data['createdAt'] != null
        ? dateFmt.format(DateTime.parse(data['createdAt']).toLocal())
        : dateFmt.format(DateTime.now());

    final amountLAK = data['amountLAK'] ?? 0;
    final amountSats = data['amountSats'] ?? 0;
    final destination = _fmtDest(data['destination'] ?? '');
    final feeSats = data['feeSats'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'ຖອນເງິນສຳເລັດ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),

                      // ── Checkmark ───────────────────────────────────────────
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF4CAF50),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Timestamp ───────────────────────────────────────────
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Receipt card ─────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFE6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // ── From ─────────────────────────────────────────
                            _ReceiptSection(
                              label: 'ຈາກບັນຊີ',
                              value: 'Sabaidee wallet',
                              valueStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            // ── Divider with arrow ────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  _dashedDivider(),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFE0D5C5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _dashedDivider(),
                                ],
                              ),
                            ),

                            // ── To ───────────────────────────────────────────
                            _ReceiptSection(
                              label: 'ຫາບັນຊີ',
                              value: destination,
                              valueStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF555555),
                              ),
                            ),

                            // ── Divider ───────────────────────────────────────
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Divider(color: Color(0xFFE0D5C5)),
                            ),

                            // ── Amount ───────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                24,
                                24,
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'ຈຳນວນເງິນ',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${fmt.format(amountLAK)} LAK',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF8C00),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sats ${fmt.format(amountSats)}',
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (feeSats > 0) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'ຄ່າທຳນຽມ: ${fmt.format(feeSats)} sats',
                                      style: const TextStyle(
                                        color: Colors.black38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Transaction ID ────────────────────────────────────
                      if (data['transactionId'] != null)
                        Text(
                          'TX: ${data['transactionId'].toString().substring(0, 16)}...',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 11,
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // ── Close button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to home / wallet screen
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ປິດ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashedDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 6.0, gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1.5,
              margin: const EdgeInsets.only(right: gap),
              color: const Color(0xFFCCBBA0),
            ),
          ),
        );
      },
    ),
  );
}

// ── Receipt section widget ────────────────────────────────────────────────────
class _ReceiptSection extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ReceiptSection({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style:
                valueStyle ??
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
