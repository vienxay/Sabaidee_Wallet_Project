import 'package:flutter/material.dart';
import 'package:sabaidee_wallet/core/core.dart';

enum ButtonVariant { filled, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Widget? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final ButtonVariant variant;
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.isLoading = false,
    this.height = 55,
    this.width,
    this.borderRadius = 12,
    this.padding,
    this.variant = ButtonVariant.filled,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ isLoading auto-disables — Flutter ຈັດການ disabled style ຜ່ານ styleFrom
    final bool isDisabled = onPressed == null || isLoading;
    final theme = Theme.of(context);

    // ✅ ຄຳນວນສີຕາມ variant ເທົ່ານັ້ນ (ບໍ່ຕ້ອງກວດ isDisabled ຊ້ຳ)
    final Color resolvedBg = _resolveBackground(theme);
    final Color resolvedForeground = _resolveForeground(theme);
    final Color resolvedDisabledBg = _resolveDisabledBackground();

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedBg,
          foregroundColor: resolvedForeground,
          disabledBackgroundColor: resolvedDisabledBg, // ✅ Flutter ໃຊ້ຢ່ານີ້
          disabledForegroundColor: Colors.grey.shade500,
          elevation: isDisabled ? 0 : elevation,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: variant == ButtonVariant.outlined
                ? BorderSide(
                    color: isDisabled
                        ? Colors.grey.shade300
                        : (borderColor ?? resolvedForeground),
                  )
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(resolvedForeground),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    _buildIcon(resolvedForeground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: height < 44 ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: resolvedForeground,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ✅ ກຳນົດ active background ຕາມ variant (disabled ຖືກ handle ໂດຍ Flutter)
  Color _resolveBackground(ThemeData theme) => switch (variant) {
    ButtonVariant.filled => backgroundColor ?? theme.colorScheme.primary,
    ButtonVariant.outlined => Colors.transparent,
    ButtonVariant.text => Colors.transparent,
  };

  // ✅ ກຳນົດ active foreground ຕາມ variant
  Color _resolveForeground(ThemeData theme) => switch (variant) {
    ButtonVariant.filled => textColor ?? Colors.white,
    ButtonVariant.outlined => textColor ?? backgroundColor ?? AppColors.primary,
    ButtonVariant.text => textColor ?? backgroundColor ?? AppColors.primary,
  };

  // ✅ consistent disabled background ໃນຈຸດດຽວ
  Color _resolveDisabledBackground() => switch (variant) {
    ButtonVariant.filled => Colors.grey.shade300,
    ButtonVariant.outlined => Colors.grey.shade100,
    ButtonVariant.text => Colors.transparent,
  };

  Widget _buildIcon(Color color) {
    if (icon is Icon) {
      final source = icon as Icon;
      return Icon(source.icon, color: color, size: source.size ?? 20);
    }
    return icon!;
  }
}
