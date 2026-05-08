import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/custom_button.dart';
import 'forgot_password.dart';
import 'package:sabaidee_wallet/core/core.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _forgotPasswordService = ForgotPasswordService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  Timer? _timer;
  Timer? _autoVerifyTimer;

  String _email = '';
  bool _argumentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _email = args?['email']?.toString() ?? '';
      _argumentsLoaded = true;

      if (_email.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoVerifyTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      _showError('ກະລຸນາໃສ່ລະຫັດ OTP ໃຫ້ຄົບ 6 ຕົວ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final verified = await _forgotPasswordService.verifyOtp(
        email: _email,
        otp: _otpCode,
      );

      if (!mounted) return;

      if (verified) {
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {'email': _email, 'otp': _otpCode},
        );
      } else {
        _showError('OTP ບໍ່ຖືກຕ້ອງ ຫຼື ໝົດອາຍຸ');
        _clearOtp();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      await _forgotPasswordService.resendOtp(email: _email);
      if (!mounted) return;

      _startCountdown();
      _clearOtp();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('ສົ່ງລະຫັດ OTP ຄືນໃໝ່ແລ້ວ'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      _showError('ບໍ່ສາມາດສົ່ງ OTP ໄດ້');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {});
    _focusNodes.first.requestFocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) _focusNodes[index + 1].requestFocus();
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
    setState(() {});

    _autoVerifyTimer?.cancel();
    if (_otpCode.length == 6) {
      _autoVerifyTimer = Timer(const Duration(milliseconds: 100), _verifyOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ຢືນຢັນລະຫັດ OTP',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'ປ້ອນລະຫັດ 6 ຕົວເລກທີ່ສົ່ງໄປຫາ\n$_email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, _buildOtpBox),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'ຢືນຢັນ',
              isLoading: _isLoading,
              backgroundColor: AppColors.primary,
              onPressed: _isLoading ? null : _verifyOtp,
            ),
            const SizedBox(height: 24),
            Center(
              child: _isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _resendCountdown == 0 ? _resendOtp : null,
                      child: Text(
                        _resendCountdown > 0
                            // ✅ ແກ້: ${_resendCountdown} → $_resendCountdown
                            ? 'ບໍ່ໄດ້ຮັບລະຫັດບໍ? ສົ່ງຄືນໃໝ່ໃນອີກ $_resendCountdown ວິນາທີ'
                            : 'ບໍ່ໄດ້ຮັບລະຫັດບໍ? ສົ່ງຄືນໃໝ່',
                        style: TextStyle(
                          fontSize: 14,
                          color: _resendCountdown > 0
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontWeight: _resendCountdown > 0
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFilled ? AppColors.primary : Colors.grey.shade300,
              width: isFilled ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
        onTap: () => _controllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: _controllers[index].text.length),
        ),
      ),
    );
  }
}
