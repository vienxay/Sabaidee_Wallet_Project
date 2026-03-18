// lib/main.dart — Sabaidee Wallet (ອັບເດດ: ເພີ່ມ KYC route + sync)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/google_callback_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/auth/security/otp_verification.dart';
import 'features/auth/security/reset_password.dart';
import 'features/kyc/kyc_screen.dart'; // ✅ ໃໝ່
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/kyc_gate_service.dart'; // ✅ ໃໝ່

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await StorageService.instance.init();
  final isLoggedIn = await AuthService.instance.isLoggedIn();

  // ✅ Sync KYC status ຈາກ backend ທຸກຄັ້ງທີ່ app ເປີດ
  // (ບໍ່ await — ໃຫ້ run background ບໍ່ block splash)
  if (isLoggedIn) {
    KycGateService.instance.syncFromBackend();
  }

  runApp(SabaideeWallet(isLoggedIn: isLoggedIn));
}

class SabaideeWallet extends StatelessWidget {
  final bool isLoggedIn;
  const SabaideeWallet({super.key, required this.isLoggedIn});

  Widget get _initialScreen =>
      isLoggedIn ? const HomeScreen() : const WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabaidee Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        fontFamily: 'NotoSansLao',
      ),
      home: _initialScreen,
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/otp-verification': (_) => const OtpVerificationScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/kyc': (_) => const KycScreen(), // ✅ ໃໝ່
        GoogleCallbackScreen.routeName: (_) => const GoogleCallbackScreen(),
      },
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
