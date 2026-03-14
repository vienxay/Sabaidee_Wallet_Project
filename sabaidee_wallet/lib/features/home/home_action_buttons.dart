import 'package:flutter/material.dart';
import '../../core/core.dart';

class HomeActionButtons extends StatelessWidget {
  final VoidCallback onReceive;
  final VoidCallback onSend;

  const HomeActionButtons({
    super.key,
    required this.onReceive,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // ── ປຸ່ມ ຮັບ ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onReceive,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'ຮັບ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── ປຸ່ມ ສົ່ງ ────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onSend,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ສົ່ງ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
