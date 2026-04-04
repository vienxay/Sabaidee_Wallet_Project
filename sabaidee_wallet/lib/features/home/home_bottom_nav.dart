// lib/features/home/home_bottom_nav.dart
import 'package:flutter/material.dart';
import '../../core/core.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScan;

  const HomeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 1. ແຖບພື້ນຫຼັງ (ສີເທົາອ່ອນ)
        Container(
          height: 85,
          decoration: BoxDecoration(
            color: Colors.grey[300], // ພື້ນຫຼັງສີເທົາຕາມຮູບ
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'ໜ້າຫຼັກ',
                  selected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),

              const SizedBox(width: 80), // ເວັ້ນບ່ອນໃຫ້ປຸ່ມສະແກນ

              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded, // ປ່ຽນຈາກ grid_view ເປັນ person
                  label: 'ໂປຣຟາຍ',
                  selected: selectedIndex == 2,
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ),
            ],
          ),
        ),

        // 2. ປຸ່ມສະແກນ (ຕົວໜັງສືຢູ່ທາງໃນວົງມົນ)
        Positioned(
          top: -40, // ໃຫ້ປຸ່ມນູນຂຶ້ນມາ
          child: GestureDetector(
            onTap: onScan,
            child: Container(
              width: 85, // ປັບຂະໜາດໃຫ້ໃຫຍ່ຂຶ້ນເລັກນ້ອຍເພື່ອໃຫ້ພໍດີກັບຕົວໜັງສື
              height: 85,
              decoration: BoxDecoration(
                color: AppColors.primary, // ສີສົ້ມ
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                // border: Border.all(color: Colors.white, width: 4),
              ),
              // ── ຍ້າຍ Icon ແລະ Text ມາໄວ້ໃນນີ້ ──────────────────────
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                  const Text(
                    'ສະແກນ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0, // ປັບໄລຍະຫ່າງແຖວໃຫ້ຊິດເຂົ້າກັນ
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.primary : Colors.black54,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.primary : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
