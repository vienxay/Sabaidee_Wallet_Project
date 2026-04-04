import 'package:flutter/material.dart';
import '../../core/core.dart';

class PaymentSuccessSheet extends StatefulWidget {
  final String senderName;
  final String receiverName;
  final String? senderAvatarUrl;
  final String? receiverAvatarUrl;
  final double amountLAK;
  final int amountSats;
  final int? feeLAK;
  final String? memo;
  final bool closeToHome;

  const PaymentSuccessSheet({
    super.key,
    required this.senderName,
    required this.receiverName,
    this.senderAvatarUrl,
    this.receiverAvatarUrl,
    required this.amountLAK,
    this.amountSats = 0,
    this.feeLAK,
    this.memo,
    this.closeToHome = false,
  });

  @override
  State<PaymentSuccessSheet> createState() => _PaymentSuccessSheetState();
}

class _PaymentSuccessSheetState extends State<PaymentSuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _iconCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  void _onClose(BuildContext context) {
    if (widget.closeToHome) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      // ເພີ່ມ Scaffold
      backgroundColor: AppColors.background, // ຕັ້ງສີພື້ນຫລັງ
      body: Column(
        children: [
          // ✅ ເນື້ອໃນ scroll ໄດ້
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ຈ່າຍເງິນສຳເລັດ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Column(
                        children: [
                          _buildPartyRow(
                            'ຈາກ',
                            widget.senderName,
                            widget.senderAvatarUrl,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          _buildPartyRow(
                            'ຫາ',
                            widget.receiverName,
                            widget.receiverAvatarUrl,
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            'ຈຳນວນເງິນ',
                            '${_fmt(widget.amountLAK)} LAK',
                            isLarge: true,
                          ),
                          if (widget.amountSats > 0)
                            _buildDetailRow(
                              'Lightning',
                              '⚡ ${widget.amountSats} sats',
                              color: Colors.orange,
                            ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'ຄ່າທຳນຽມ',
                            '${widget.feeLAK ?? 0} LAK',
                          ),
                          _buildDetailRow(
                            'ເນື້ອໃນ',
                            widget.memo ?? 'ຊຳລະຄ່າສິນຄ້າ',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ ປຸ່ມຢູ່ລຸ່ມສຸດສະເໝີ
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _onClose(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ປິດ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow(String label, String name, String? url) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLarge = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: FontWeight.bold,
              color:
                  color ??
                  (isLarge ? AppColors.primaryDark : AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
