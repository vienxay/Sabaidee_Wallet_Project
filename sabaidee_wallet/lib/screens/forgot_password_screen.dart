import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../security/forgot_password.dart';
import 'package:sabaidee_wallet/core/core.dart';

class ForgotPasswordScreen extends StatefulWidget {
  // ✅ inject service ເພື່ອ testability
  final ForgotPasswordService? forgotPasswordService;
  const ForgotPasswordScreen({
    super.key,
    this.forgotPasswordService,
  }); // ✅ super.key

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // ✅ Form validation
  final _emailController = TextEditingController();
  late final ForgotPasswordService _forgotPasswordService; // ✅ late init
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _forgotPasswordService =
        widget.forgotPasswordService ?? ForgotPasswordService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // ✅ Form validate ຄັ້ງດຽວ
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await _forgotPasswordService.sendOtp(email: email);

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/otp-verification',
        arguments: {'email': email},
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ hideCurrentSnackBar ກ່ອນສະແດງອັນໃໝ່
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
        child: Form(
          // ✅ ຄອບດ້ວຍ Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forgot Password',
                // ✅ ໃຊ້ Theme ແທນ hardcode
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your account email address to receive\n'
                'the 6 digit code to reset your password',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                // ✅ validator ຢູ່ໃນ widget
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ກະລຸນາໃສ່ອີເມວ';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value.trim())) {
                    return 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Send',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
