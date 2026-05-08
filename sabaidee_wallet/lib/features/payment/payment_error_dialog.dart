// lib/features/payment/payment_error_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PaymentErrorType {
  requireKYC,
  limitExceeded,
  insufficientFunds,
  invalidInvoice,
  network,
  general,
}

class PaymentErrorInfo {
  final PaymentErrorType type;
  final String message;
  final bool requireKYC;

  const PaymentErrorInfo({
    required this.type,
    required this.message,
    this.requireKYC = false,
  });

  factory PaymentErrorInfo.fromApiResponse(Map<String, dynamic> json) {
    final message = json['message'] as String? ?? 'ເກີດຂໍ້ຜິດພາດ';
    final requireKYC = json['requireKYC'] as bool? ?? false;

    final msg = message.toLowerCase();

    PaymentErrorType type;
    if (requireKYC || msg.contains('kyc')) {
      type = PaymentErrorType.requireKYC;
    } else if (msg.contains('limit') || msg.contains('ເກີນ')) {
      type = PaymentErrorType.limitExceeded;
    } else if (msg.contains('sats') || msg.contains('ຍອດເງິນ')) {
      type = PaymentErrorType.insufficientFunds;
    } else if (msg.contains('invoice')) {
      type = PaymentErrorType.invalidInvoice;
    } else if (msg.contains('network') || msg.contains('timeout')) {
      type = PaymentErrorType.network;
    } else {
      type = PaymentErrorType.general;
    }

    return PaymentErrorInfo(
      type: type,
      message: message,
      requireKYC: requireKYC,
    );
  }
}

// ─── Dialog ─────────────────────────────────────────────────────────────
class PaymentErrorDialog extends StatefulWidget {
  final PaymentErrorInfo errorInfo;
  final VoidCallback? onRetry;
  final VoidCallback? onGoToKYC;

  const PaymentErrorDialog({
    super.key,
    required this.errorInfo,
    this.onRetry,
    this.onGoToKYC,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentErrorInfo errorInfo,
    VoidCallback? onRetry,
    VoidCallback? onGoToKYC,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6), // ✅ fixed
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => PaymentErrorDialog(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onGoToKYC: onGoToKYC,
      ),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PaymentErrorDialog> createState() => _PaymentErrorDialogState();
}

class _PaymentErrorDialogState extends State<PaymentErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    ); // ✅ smoother

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Config ───────────────────────────────────────────────────────────
  _Cfg get _cfg {
    switch (widget.errorInfo.type) {
      case PaymentErrorType.requireKYC:
        return _Cfg(
          color: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFFBEB),
          ringColor: const Color(0xFFFDE68A),
          icon: Icons.shield_outlined,
          title: 'ຕ້ອງຢືນຢັນຕົວຕົນ',
          showKYC: true,
          showRetry: false,
        );
      case PaymentErrorType.limitExceeded:
        return _Cfg(
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          ringColor: const Color(0xFFFECACA),
          icon: Icons.remove_circle_outline_rounded,
          title: 'ເກີນວົງເງິນ',
          showKYC: widget.errorInfo.requireKYC,
          showRetry: false,
        );
      case PaymentErrorType.insufficientFunds:
        return _Cfg(
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
          ringColor: const Color(0xFFDDD6FE),
          icon: Icons.account_balance_wallet_outlined,
          title: 'ຍອດເງິນບໍ່ພໍ',
          showKYC: false,
          showRetry: false,
        );
      case PaymentErrorType.invalidInvoice:
        return _Cfg(
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
          ringColor: const Color(0xFFBFDBFE),
          icon: Icons.qr_code_2_rounded,
          title: 'Invoice ບໍ່ຖືກຕ້ອງ',
          showKYC: false,
          showRetry: true,
        );
      case PaymentErrorType.network:
        return _Cfg(
          color: const Color(0xFF6B7280),
          bgColor: const Color(0xFFF9FAFB),
          ringColor: const Color(0xFFE5E7EB),
          icon: Icons.wifi_off_rounded,
          title: 'ເຊື່ອມຕໍ່ບໍ່ໄດ້',
          showKYC: false,
          showRetry: true,
        );
      case PaymentErrorType.general:
        return _Cfg(
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          ringColor: const Color(0xFFFECACA),
          icon: Icons.error_outline_rounded,
          title: 'ຈ່າຍເງິນບໍ່ສຳເລັດ',
          showKYC: false,
          showRetry: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ single top accent
              Container(height: 3, color: cfg.color),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _iconAnim,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: cfg.bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: cfg.ringColor, width: 1.5),
                        ),
                        child: Icon(cfg.icon, color: cfg.color, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      cfg.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      widget.errorInfo.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Column(
                      children: [
                        if (cfg.showKYC && widget.onGoToKYC != null) ...[
                          _PrimaryBtn(
                            label: 'ຢືນຢັນ KYC',
                            color: cfg.color,
                            icon: Icons.shield_outlined,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onGoToKYC?.call();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (cfg.showRetry && widget.onRetry != null) ...[
                          _PrimaryBtn(
                            label: 'ລອງໃໝ່',
                            color: cfg.color,
                            icon: Icons.refresh_rounded,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onRetry?.call();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],

                        _GhostBtn(
                          color: cfg.color,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Primary Button ─────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─── Ghost Button (Improved) ────────────────────────────────────────────
class _GhostBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;

  const _GhostBtn({required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: c,
          backgroundColor: c.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ປິດ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─── Config ─────────────────────────────────────────────────────────────
class _Cfg {
  final Color color;
  final Color bgColor;
  final Color ringColor;
  final IconData icon;
  final String title;
  final bool showKYC;
  final bool showRetry;

  const _Cfg({
    required this.color,
    required this.bgColor,
    required this.ringColor,
    required this.icon,
    required this.title,
    required this.showKYC,
    required this.showRetry,
  });
}
