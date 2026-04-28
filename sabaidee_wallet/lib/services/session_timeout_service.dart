// lib/services/session_timeout_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class SessionTimeoutService {
  SessionTimeoutService._();
  static final SessionTimeoutService instance = SessionTimeoutService._();

  static const _timeoutDuration = Duration(minutes: 5); // ✅ 5 ນາທີ
  Timer? _timer;
  GlobalKey<NavigatorState>? _navigatorKey;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  // ✅ ເລີ່ມຈັບເວລາ / reset ທຸກຄັ້ງທີ່ user
  void onUserActivity() {
    _timer?.cancel();
    _timer = Timer(_timeoutDuration, _onTimeout);
  }

  // ✅ ໝົດເວລາ → logout
  Future<void> _onTimeout() async {
    await AuthService.instance.logout();
    _navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
      arguments: 'session_expired', // ✅ ສົ່ງ reason
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}
