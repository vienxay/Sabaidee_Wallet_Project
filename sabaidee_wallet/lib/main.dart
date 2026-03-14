// lib/main.dart
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
import 'services/auth_service.dart';
import 'services/storage_service.dart';
// ✅ ລຶບ session_service import ອອກ

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

  runApp(SabaideeWallet(isLoggedIn: isLoggedIn));
}

class SabaideeWallet extends StatelessWidget {
  final bool isLoggedIn;
  const SabaideeWallet({super.key, required this.isLoggedIn});

  Widget get _initialScreen =>
      isLoggedIn ? const HomeScreen() : const WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    // ✅ ລຶບ GestureDetector ອອກ — ບໍ່ຕ້ອງການແລ້ວ
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
        GoogleCallbackScreen.routeName: (_) => const GoogleCallbackScreen(),
      },
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
