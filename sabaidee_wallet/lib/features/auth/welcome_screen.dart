import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'package:sabaidee_wallet/core/core.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key}); // ✅ super.key

  @override
  Widget build(BuildContext context) {
    // ✅ Responsive image size
    final imageSize = MediaQuery.sizeOf(context).width * 0.75;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ errorBuilder ກັນ crash ຖ້າ asset ຂາດ
              Image.asset(
                'assets/images/wallet_animation.gif',
                height: imageSize,
                width: imageSize,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.account_balance_wallet_outlined,
                  size: imageSize * 0.4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              // ✅ ໃຊ້ Theme
              Text(
                'Welcome to Laos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sabaidee Wallet easy way\nto payment in laos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // ✅ named routes — ບໍ່ import screen ໂດຍກົງ
              CustomButton(
                text: 'Sign Up',
                backgroundColor: AppColors.primary,
                onPressed: () => Navigator.pushNamed(context, '/register'),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Already have an account',
                backgroundColor: AppColors.inputBackground,
                textColor: AppColors.textSecondary,
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
