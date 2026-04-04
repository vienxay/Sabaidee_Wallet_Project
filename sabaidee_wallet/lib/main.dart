// lib/main.dart — Sabaidee Wallet (ອັບເດດ: ເພີ່ມ KYC route + sync)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/google_callback_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/security/otp_verification.dart';
import 'features/auth/security/reset_password.dart';
import 'features/kyc/kyc_screen.dart'; // ✅ ໃໝ່
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/kyc_gate_service.dart'; // ✅ ໃໝ່
import 'package:app_links/app_links.dart';
import 'dart:async';

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

class SabaideeWallet extends StatefulWidget {
  final bool isLoggedIn;
  const SabaideeWallet({super.key, required this.isLoggedIn});

  @override
  State<SabaideeWallet> createState() => _SabaideeWalletState();
}

class _SabaideeWalletState extends State<SabaideeWallet> {
  final _appLinks = AppLinks();
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // ✅ ຮັບ link ຕອນ app ເປີດຈາກ background
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // ✅ ຮັບ link ຂະນະ app ເປີດຢູ່
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) async {
    if (uri.scheme != 'sabaidee') return;

    // ✅ ກວດ login ກ່ອນ navigate ສະເໝີ
    final isLoggedIn = await AuthService.instance.isLoggedIn();

    if (!isLoggedIn) {
      // ຍັງບໍ່ login → ໄປໜ້າ login ກ່ອນ ແລ້ວ redirect ຕໍ່
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      return;
    }

    switch (uri.host) {
      case 'home':
        // ✅ sync KYC ກ່ອນໄປໜ້າ home
        await KycGateService.instance.syncFromBackend();
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        break;
      case 'kyc':
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/kyc',
          (route) => false,
        );
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Widget get _initialScreen =>
      widget.isLoggedIn ? const HomeScreen() : const WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabaidee Wallet',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey, // ✅ ສຳຄັນ
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
        '/profile': (_) => const ProfileScreen(),
        '/kyc': (_) => const KycScreen(),
        GoogleCallbackScreen.routeName: (_) => const GoogleCallbackScreen(),
      },
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
