// Auto-logout ເມື່ອ user ບໍ່ໄດ້ໃຊ້ app ດົນກວ່າ 5 ນາທີ
//
// Flow ທົ່ວໄປ:
//   1. onUserActivity() ເອີ້ນທຸກຄັ້ງທີ່ user tap/scroll (ຈາກ GestureDetector ໃນ main.dart)
//   2. ຖ້າ 5 ນາທີຜ່ານໄປ → _onTimeout() → logout + navigate /login
//
// Flow ເມື່ອ app ໄປ background (AppLifecycleState):
//   paused   → ບັນທຶກ _backgroundedAt
//   resumed  → ກວດ elapsed time:
//              - ≥ 5 ນາທີ → logout ທັນທີ
//              - < 5 ນາທີ → ດຳເນີນ timer ດ້ວຍ remaining time
import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class SessionTimeoutService with WidgetsBindingObserver {
  SessionTimeoutService._();
  static final SessionTimeoutService instance = SessionTimeoutService._();

  static const _timeoutDuration = Duration(minutes: 5);

  Timer?    _timer;
  DateTime? _backgroundedAt; // ເວລາທີ່ app ໄປ background
  GlobalKey<NavigatorState>? _navigatorKey;

  // ─── Init / Dispose ───────────────────────────────────────────────────────
  // init() ຕ້ອງ call ໃນ initState ຂອງ root widget (main.dart)
  // register observer ເພື່ອຮັບ AppLifecycleState events
  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── Activity ─────────────────────────────────────────────────────────────
  // reset timer ທຸກຄັ້ງທີ່ user ເຄືອນໄຫວ
  void onUserActivity() {
    _timer?.cancel();
    _timer = Timer(_timeoutDuration, _onTimeout);
  }

  // ─── AppLifecycleState ────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // app ລົງ background → ບັນທຶກເວລາ + ຢຸດ timer ຊົ່ວຄາວ
        _backgroundedAt = DateTime.now();
        _timer?.cancel();
        break;

      case AppLifecycleState.resumed:
        // app ກັບ foreground → ຄຳນວນ elapsed time
        final backgrounded = _backgroundedAt;
        _backgroundedAt = null;
        if (backgrounded == null) break;

        final elapsed = DateTime.now().difference(backgrounded);
        if (elapsed >= _timeoutDuration) {
          // ອອກໄປດົນກວ່າ 5 ນາທີ → ກວດວ່າຍັງ login ຢູ່ ກ່ອນ logout
          // (ກັນ double-logout ຖ້າ user logout manual ກ່ອນ)
          AuthService.instance.isLoggedIn().then((loggedIn) {
            if (loggedIn) _onTimeout();
          });
        } else {
          // ຍັງໃນ window → ດຳເນີນ timer ດ້ວຍ remaining time
          _timer = Timer(_timeoutDuration - elapsed, _onTimeout);
        }
        break;

      default:
        break;
    }
  }

  // ─── Timeout Handler ──────────────────────────────────────────────────────
  Future<void> _onTimeout() async {
    _timer?.cancel();
    _backgroundedAt = null;
    await AuthService.instance.logout();
    // navigate ກັບ /login ແລ້ວ clear stack ທັງໝົດ
    // arguments 'session_expired' → login screen ສະແດງ snackbar
    _navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
      arguments: 'session_expired',
    );
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
