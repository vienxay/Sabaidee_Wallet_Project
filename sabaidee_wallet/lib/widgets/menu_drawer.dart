import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../core/core.dart';
import '../features/withdraw/withdraw_screen.dart';
import '../services/auth_service.dart';

class MenuDrawer extends StatefulWidget {
  final int balanceSats;
  final double balanceLAK;

  const MenuDrawer({
    super.key,
    required this.balanceSats,
    required this.balanceLAK,
  });

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool _isLoggingOut = false;

  Future<void> _launchWhatsApp() async {
    final phoneNumber =
        "+856 20 55 740 336"; // ໃສ່ເບີ WhatsApp ຂອງທ່ານ (ແບບມີລະຫັດປະເທດ 85620...)
    final message = "ສະບາຍດີ, ຂ້າພະເຈົ້າຕ້ອງການແຈ້ງບັນຫາ...";

    // ສ້າງ URL ສຳລັບ WhatsApp
    final url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // ຖ້າເປີດບໍ່ໄດ້ (ເຊັ່ນ: ບໍ່ມີແອັບ WhatsApp)
        debugPrint("Could not launch $url");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ─── Logout Logic ──────────────────────────────────────────────────────────
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await AuthService.instance.logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // ─── Confirm Dialog ────────────────────────────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ອອກຈາກລະບົບ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບແທ້ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'ຍົກເລີກ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ອອກຈາກລະບົບ',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) await _logout();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),

            // ─── Menu Items ──────────────────────────────────────────────────
            _MenuItem(
              icon: Icons.location_on_outlined,
              label: 'ຄົ້ນຫາຮ້ານຄ້າ',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.language_outlined,
              label: 'ພາສາ',
              trailing: const Text(
                'LA',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.payments_outlined,
              label: 'ຖອນເງິນ',
              onTap: () {
                Navigator.pop(context); // ປິດ Drawer ກ່ອນ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WithdrawScreen(
                      balanceSats: widget.balanceSats,
                      balanceLAK: widget.balanceLAK,
                    ),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'ແຈ້ງບັນຫາ',
              onTap: _launchWhatsApp,
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'ການຕັ້ງຄ່າ',
              onTap: () {},
            ),

            const Spacer(),

            // ─── Logout Button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _isLoggingOut ? null : _confirmLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isLoggingOut
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ອອກຈາກລະບົບ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item Widget ─────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 18),
      onTap: onTap,
    );
  }
}
