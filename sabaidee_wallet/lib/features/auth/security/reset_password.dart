import 'package:flutter/material.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';
import 'forgot_password.dart';
import 'package:sabaidee_wallet/core/core.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key}); // ✅ super.key

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // ✅ Form key
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotPasswordService = ForgotPasswordService();

  bool _isLoading = false;
  bool _argumentsLoaded = false;

  String _email = ''; // ✅ ບໍ່ late
  String _otp = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _email = args?['email']?.toString() ?? '';
      _otp = args?['otp']?.toString() ?? '';
      _argumentsLoaded = true;

      // ✅ ກວດ args ຂາດ — pop ກັບ
      if (_email.isEmpty || _otp.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // ✅ Form validate ຄັ້ງດຽວ
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _forgotPasswordService.resetPassword(
        email: _email,
        otp: _otp,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ hideCurrentSnackBar + AppColors
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success, // ✅ AppColors
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'ສຳເລັດ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ລະຫັດຜ່ານຂອງທ່ານຖືກ reset ສຳເລັດແລ້ວ.\nກະລຸນາເຂົ້າສູ່ລະບົບດ້ວຍລະຫັດຜ່ານໃໝ່.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // ✅ pop dialog ກ່ອນ navigate
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'ກັບເຂົ້າສູ່ລະບົບ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ການຕັ້ງລະຫັດຜ່ານໃໝ່',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ລະຫັດຜ່ານໃໝ່ຕ້ອງແຕກຕ່າງ\nຈາກລະຫັດຜ່ານເກົ່າຂອງທ່ານ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _newPasswordController,
                hintText: 'New Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ລະຫັດຜ່ານໃໝ່';
                  if (v.length < 6) return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາຢືນຢັນລະຫັດຜ່ານ';
                  if (v != _newPasswordController.text) {
                    return 'ລະຫັດຜ່ານບໍ່ຕົງກັນ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'ຕົກລົງ',
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
                onPressed: _isLoading ? null : _resetPassword,
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
