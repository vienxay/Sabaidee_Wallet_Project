// lib/main.dart — Sabaidee Wallet

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/google_callback_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/security/otp_verification.dart';
import 'features/auth/security/reset_password.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_screen.dart';
import 'features/kyc/kyc_screen.dart';
import 'features/profile/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/kyc_gate_service.dart';
import 'services/storage_service.dart';

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

  var isLoggedIn = false;

  try {
    await StorageService.instance.init().timeout(const Duration(seconds: 3));

    isLoggedIn = await AuthService.instance.isLoggedIn().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );

    if (isLoggedIn) {
      KycGateService.instance.syncFromBackend();
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
    isLoggedIn = false;
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
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) async {
    if (uri.scheme != 'sabaidee') return;

    final isLoggedIn = await AuthService.instance.isLoggedIn();

    if (!isLoggedIn) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      return;
    }

    switch (uri.host) {
      case 'home':
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
      navigatorKey: _navigatorKey,
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
