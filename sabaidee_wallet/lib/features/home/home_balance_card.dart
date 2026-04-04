import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';

class HomeBalanceCard extends StatelessWidget {
  final WalletModel? wallet;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  const HomeBalanceCard({
    super.key,
    required this.wallet,
    required this.balanceVisible,
    required this.onToggleVisibility,
  });

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final sats = wallet?.balanceSats ?? 0;
    final lak = wallet?.balanceLAK ?? 0;
    final rate = wallet?.rate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ຍອດຄົງເຫຼື່ອ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Balance Amount ────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: balanceVisible
                  ? Text(
                      '${_fmt(lak)} LAK',
                      key: const ValueKey('shown'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    )
                  : const Text(
                      '••••••• LAK',
                      key: ValueKey('hidden'),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
            ),

            const SizedBox(height: 4),

            // ── Sats + Rate ───────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primary, size: 14),
                const SizedBox(width: 2),
                Text(
                  balanceVisible
                      ? '${_fmt(sats)} sats${rate != null ? '  ·  \$${rate.btcToUSD.toStringAsFixed(0)}' : ''}'
                      : '•••• sats',
                  style: const TextStyle(
                    fontSize: 13,
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
