// Entry point ຂອງ App — ເລີ່ມຕົ້ນທຸກຢ່າງທີ່ນີ້
//
// ລຳດັບ startup:
//   1. ຕັ້ງ orientation (portrait only)
//   2. init StorageService
//   3. ກວດ JWT token ທ້ອງຖິ່ນ (offline, ໄວ)
//   4. ຖ້າ logged in → sync KYC status ຈາກ server + ກວດ role admin
//   5. runApp → ສຸດທ້າຍ route = HomeScreen ຫຼື WelcomeScreen

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/navigator_key.dart';
import 'features/admin/admin_screen.dart';
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
import 'services/session_timeout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // lock orientation ສະເພາະ portrait — wallet app ບໍ່ຕ້ອງ landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // status bar ໃສ ໂດຍ transparent + dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  var isLoggedIn = false;
  var isAdmin    = false;

  try {
    // init SharedPreferences ກ່ອນ ທຸກ service ອື່ນ
    await StorageService.instance.init().timeout(const Duration(seconds: 10));

    // ກວດ JWT locally (ບໍ່ call API) → ໄວ ແລ້ວ ໃຊ້ offline ໄດ້
    isLoggedIn = await AuthService.instance.isLoggedIn().timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );

    if (isLoggedIn) {
      // sync KYC status ຈາກ server (fire-and-forget — ບໍ່ block startup)
      KycGateService.instance.syncFromBackend();
      final user = await AuthService.instance.getMe();
      isAdmin = user?.isAdmin ?? false;
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
    isLoggedIn = false;
  }

  runApp(SabaideeWallet(isLoggedIn: isLoggedIn, isAdmin: isAdmin));
}

class SabaideeWallet extends StatefulWidget {
  final bool isLoggedIn;
  final bool isAdmin;
  const SabaideeWallet({
    super.key,
    required this.isLoggedIn,
    this.isAdmin = false,
  });

  @override
  State<SabaideeWallet> createState() => _SabaideeWalletState();
}

class _SabaideeWalletState extends State<SabaideeWallet> {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    // register SessionTimeout observer + start timer ຖ້າ logged in
    SessionTimeoutService.instance.init(navigatorKey);
    if (widget.isLoggedIn) {
      SessionTimeoutService.instance.onUserActivity();
    }
  }

  // ─── Deep Links ──────────────────────────────────────────────────────────
  // ຮອງຮັບ: sabaidee://home, sabaidee://kyc
  // ໃຊ້ redirect ຈາກ server ຫຼັງ Google OAuth callback
  Future<void> _initDeepLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _handleLink(initialLink);

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) async {
    if (uri.scheme != 'sabaidee') return;

    // ─── Google OAuth callback ────────────────────────────────────────────
    // URL pattern: sabaidee://auth/callback?token=JWT
    //   host = 'auth', path = '/callback'
    // ຕ້ອງ handle ກ່ອນ isLoggedIn check ເພາະ token ຍັງບໍ່ຖືກ save ເທື່ອ
    if (uri.host == 'auth' &&
        (uri.path == '/callback' || uri.path == '/auth/callback')) {
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) return;

      // 1. save token ກ່ອນ
      await StorageService.instance.saveToken(token);

      // 2. fetch user ຈາກ server ດ້ວຍ token ໃໝ່
      final user = await AuthService.instance.getMe();
      if (user != null) {
        await StorageService.instance.saveUser(user);
        SessionTimeoutService.instance.onUserActivity();
        KycGateService.instance.syncFromBackend();
      }

      // 3. navigate ໄປ home
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (_) => false,
      );
      return;
    }

    // ─── Other deep links — ຕ້ອງ login ກ່ອນ ─────────────────────────────
    final isLoggedIn = await AuthService.instance.isLoggedIn();
    if (!isLoggedIn) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
      return;
    }

    switch (uri.host) {
      case 'home':
        // sync KYC ກ່ອນ show home (ອາດ verified ຫຼັງຈາກ admin approve)
        await KycGateService.instance.syncFromBackend();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        break;
      case 'kyc':
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/kyc',
          (route) => false,
        );
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    SessionTimeoutService.instance.dispose();
    super.dispose();
  }

  Widget get _initialScreen =>
      widget.isLoggedIn ? const HomeScreen() : const WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabaidee Wallet',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        fontFamily: 'NotoSansLao',
      ),
      // GestureDetector ຄອບ app ທັງໝົດ — reset session timer ທຸກຄັ້ງທີ່ user ສຳຜັດ
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap:     () => SessionTimeoutService.instance.onUserActivity(),
        onPanDown: (_) => SessionTimeoutService.instance.onUserActivity(),
        child: child,
      ),
      home: _initialScreen,
      routes: {
        '/welcome':          (_) => const WelcomeScreen(),
        '/login':            (_) => const LoginScreen(),
        '/register':         (_) => const RegisterScreen(),
        '/forgot-password':  (_) => const ForgotPasswordScreen(),
        '/otp-verification': (_) => const OtpVerificationScreen(),
        '/reset-password':   (_) => const ResetPasswordScreen(),
        '/home':             (_) => const HomeScreen(),
        '/profile':          (_) => const ProfileScreen(),
        '/kyc':              (_) => const KycScreen(),
        '/admin':            (_) => const AdminScreen(),
        GoogleCallbackScreen.routeName: (_) => const GoogleCallbackScreen(),
      },
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
