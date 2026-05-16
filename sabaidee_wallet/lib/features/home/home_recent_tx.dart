import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';

class HomeRecentTx extends StatelessWidget {
  final TransactionModel tx;
  const HomeRecentTx({super.key, required this.tx});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String _formatDate(DateTime dt) {
    const months = [
      'ມັງກອນ',
      'ກຸມພາ',
      'ມີນາ',
      'ເມສາ',
      'ພຶດສະພາ',
      'ມິຖຸນາ',
      'ກໍລະກົດ',
      'ສິງຫາ',
      'ກັນຍາ',
      'ຕຸລາ',
      'ພະຈິກ',
      'ທັນວາ',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tx.isPending
                    ? Colors.grey.shade100
                    : tx.isFailed
                        ? Colors.grey.shade100
                        : tx.isReceive
                            ? AppColors.successLight
                            : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tx.isPending ? Icons.access_time_rounded : Icons.bolt,
                color: tx.isPending
                    ? Colors.grey
                    : tx.isFailed
                        ? Colors.grey
                        : tx.isReceive
                            ? AppColors.success
                            : AppColors.primary,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // ── Memo + Date ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.memo.isNotEmpty ? tx.memo : tx.type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(tx.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            // ── Amount ────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.isFailed
                      ? 'ລົ້ມເຫລວ'
                      : '${tx.isReceive ? '+' : '-'}${_fmt(tx.amountSats)} sats',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tx.isFailed
                        ? Colors.grey
                        : tx.isPending
                            ? Colors.orange.shade300
                            : tx.isReceive
                                ? AppColors.success
                                : AppColors.error,
                  ),
                ),
                if (tx.isPending)
                  const Text(
                    'ລໍຖ້າ',
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  )
                else if (!tx.isFailed)
                  Text(
                    '${_fmt(tx.amountLAK)} LAK',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
