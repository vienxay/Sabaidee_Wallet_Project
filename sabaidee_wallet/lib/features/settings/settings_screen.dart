import 'package:flutter/material.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ການຕັ້ງຄ່າ',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('ຂໍ້ມູນສ່ວນຕົວ'),
            const SizedBox(height: 8),
            _card([
              _tile(
                context: context,
                icon: Icons.person_outline,
                iconBg: const Color(0xFFF7941D),
                title: 'ຂໍ້ມູນສ່ວນຕົວ',
                subtitle: 'ຊື່, ອີເມວ, ເບີໂທ, ວັນເກີດ',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ]),

            const SizedBox(height: 24),

            _sectionLabel('ຄວາມປອດໄພ'),
            const SizedBox(height: 8),
            _card([
              _tile(
                context: context,
                icon: Icons.lock_outline,
                iconBg: const Color(0xFF2F2FE4),
                title: 'ປ່ຽນລະຫັດຜ່ານ',
                subtitle: 'ອັບເດດລະຫັດຜ່ານຂອງທ່ານ',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconBg, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF333333),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
      );
}
