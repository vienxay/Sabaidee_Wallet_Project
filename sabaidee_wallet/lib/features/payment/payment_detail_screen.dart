import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';

class PaymentDetailScreen extends StatelessWidget {
  final TransactionModel tx;
  const PaymentDetailScreen({super.key, required this.tx});

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Payment Detail',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.close, color: AppColors.textDark),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row(label: 'Time', value: _formatDate(tx.createdAt)),
              const Divider(height: 24, color: AppColors.divider),

              const Text(
                'Amount (sats)',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 4),
              Text(
                '${tx.isReceive ? '+' : '-'}${tx.amountSats}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tx.amountLAK} LAK',
                style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const Divider(height: 24, color: AppColors.divider),

              _Row(label: 'Type', value: 'LIGHTNING NETWORK PAYMENT'),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tx.isSuccess
                          ? AppColors.successLight
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tx.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tx.isSuccess
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.divider),

              _Row(label: 'Total Fees (sats)', value: '${tx.feeSats}'),
              const SizedBox(height: 12),

              if (tx.memo.isNotEmpty) ...[
                const Text(
                  'Note',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.memo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              if (tx.paymentHash.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Payment Hash',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.paymentHash,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    ],
  );
}
