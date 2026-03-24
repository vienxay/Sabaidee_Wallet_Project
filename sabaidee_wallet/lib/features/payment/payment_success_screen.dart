import 'package:flutter/material.dart';
import '../../core/core.dart';

// ════════════════════════════════════════════════════════════════════════════
// PaymentSuccessSheet — unified success widget
//
// ⚡ Lightning  → showModalBottomSheet(builder: (_) => PaymentSuccessSheet(...))
// 🇱🇦 LAO QR   → showModalBottomSheet(builder: (_) => PaymentSuccessSheet(
//                   feeLAK: 0, memo: 'ອາຫານ', closeToHome: true, ...))
// 🔄 ໂອນເງິນ   → ຄືກັບ LAO QR
// ════════════════════════════════════════════════════════════════════════════
class PaymentSuccessSheet extends StatelessWidget {
  final String senderName;
  final String receiverName;
  final String? senderAvatarUrl;
  final String? receiverAvatarUrl;

  final double amountLAK;
  final int amountSats; // ⚡ Lightning: ໃສ່ຄ່າ | 🇱🇦 LAO QR / ໂອນ: 0
  final int? feeLAK; // ຄ່າທຳນຽມ (null = ບໍ່ສະແດງ)
  final String? memo; // ເຫດໃດ   (null = ບໍ່ສະແດງ)

  /// true  → ກົດ Close ໄປ /home (LAO QR / ໂອນເງິນ)
  /// false → ກົດ Close pop sheet (Lightning)
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

  // ─── helpers ───────────────────────────────────────────────────────────────
  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  void _onClose(BuildContext context) {
    if (closeToHome) {
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
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 28),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── check icon ──
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Payment success',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),

          // ── sender ──
          _PartyRow(
            label: 'Sender',
            name: senderName,
            avatarUrl: senderAvatarUrl,
            avatarColor: AppColors.primaryLight,
            iconColor: AppColors.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textGrey,
              size: 22,
            ),
          ),

          // ── receiver ──
          _PartyRow(
            label: 'Receiver',
            name: receiverName,
            avatarUrl: receiverAvatarUrl,
            avatarColor: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── amount (LAK) ──
          _AmountRow(label: 'Amount', value: '${_fmt(amountLAK)} LAK'),

          // ── sats (⚡ Lightning ເທົ່ານັ້ນ) ──
          if (amountSats > 0) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$amountSats sats',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ),
          ],

          // ── fee (ຖ້າສ່ງ feeLAK) ──
          if (feeLAK != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              label: 'ຄ່າທຳນຽມ',
              value: '${feeLAK == 0 ? "0" : _fmt(feeLAK!.toDouble())} LAK',
            ),
          ],

          // ── memo (ຖ້າສ່ງ memo) ──
          if (memo != null && memo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailRow(label: 'ເຫດໃດ', value: memo!),
          ],

          const SizedBox(height: 24),

          // ── close button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _onClose(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'ປິດ',
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
  }
}

// ─── Party row ────────────────────────────────────────────────────────────────
class _PartyRow extends StatelessWidget {
  final String label, name;
  final String? avatarUrl;
  final Color avatarColor, iconColor;

  const _PartyRow({
    required this.label,
    required this.name,
    this.avatarUrl,
    required this.avatarColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: avatarColor,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.person, color: iconColor, size: 22)
            : null,
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    ],
  );
}

// ─── Amount row (ໃຫຍ່) ───────────────────────────────────────────────────────
class _AmountRow extends StatelessWidget {
  final String label, value;
  const _AmountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ],
  );
}

// ─── Detail row (ຄ່າທຳນຽມ / ເຫດໃດ) ──────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    ],
  );
}
