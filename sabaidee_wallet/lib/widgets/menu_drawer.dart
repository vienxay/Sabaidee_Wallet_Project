import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/core.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool _isLoggingOut = false;

  // ─── Logout Logic ──────────────────────────────────────────────────────────
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      if (token != null) {
        await http
            .post(
              Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.authLogout}'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => http.Response('timeout', 408),
            );
      }
    } catch (_) {
      // ບໍ່ block logout ຖ້າ network error
    }

    // ✅ ຍ້າຍ Cleanup + Navigate ອອກຈາກ finally
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);

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
              label: 'Find Merchants',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.language_outlined,
              label: 'English',
              trailing: const Text(
                'EN',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'Support',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
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
