import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabaidee_wallet/core/core.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final bool showCounter;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.contentPadding,
    this.fillColor,
    this.labelText,
    this.helperText,
    this.errorText,
    this.showCounter = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  // ✅ Extract icon color ໃຫ້ເປັນ method ດຽວ — ບໍ່ duplicate 3 ບ່ອນ
  Color _resolveIconColor(bool hasError) {
    if (hasError) return AppColors.error;
    if (_isFocused) return AppColors.primary;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null) ...[
            Text(
              widget.labelText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasError ? AppColors.error : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
          ],
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            style: TextStyle(
              // ✅ ໃຊ້ AppColors ແທນ hardcode Colors.black87
              color: widget.enabled
                  ? AppColors.textPrimary
                  : Colors.grey.shade500,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.enabled
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
              ),
              // ✅ ໃຊ້ _resolveIconColor ດຽວ — ບໍ່ duplicate logic
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: _resolveIconColor(hasError))
                  : null,
              suffixIcon: _buildSuffixIcon(hasError),
              filled: true,
              fillColor: widget.enabled
                  ? (widget.fillColor ?? AppColors.inputBackground)
                  : Colors.grey.shade100,
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: _buildBorder(Colors.transparent),
              focusedBorder: _buildBorder(AppColors.primary, width: 2),
              errorBorder: _buildBorder(AppColors.error),
              focusedErrorBorder: _buildBorder(AppColors.error, width: 2),
              disabledBorder: _buildBorder(Colors.transparent),
              errorText: widget.errorText,
              errorStyle: const TextStyle(fontSize: 12),
              helperText: widget.helperText,
              helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              counterText: widget.showCounter ? null : '',
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ໃຊ້ _resolveIconColor ດຽວ ທັງ password toggle ແລະ suffixIcon
  Widget? _buildSuffixIcon(bool hasError) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isObscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _resolveIconColor(hasError),
        ),
        onPressed: () => setState(() => _isObscured = !_isObscured),
      );
    }
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, color: _resolveIconColor(hasError));
    }
    return null;
  }

  InputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: color == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }
}
