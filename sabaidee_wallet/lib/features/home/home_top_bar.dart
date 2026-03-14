import 'package:flutter/material.dart';
import '../../core/core.dart';

class HomeTopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeTopBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconBtn(
            icon: Icons.menu_rounded,
            onTap: () => scaffoldKey.currentState?.openDrawer(),
          ),
          const Text(
            'Home',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () {},
            badge: true,
          ),
        ],
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _IconBtn({required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Center(child: Icon(icon, color: AppColors.textDark, size: 22)),
          if (badge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
