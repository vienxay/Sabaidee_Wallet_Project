import 'package:flutter/material.dart';
import 'package:sabaidee_wallet/core/core.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // ✅ super.key

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // ✅ Form key
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ ແກ້: ສົ່ງ walletName ໃຫ້ກົງກັບ Backend
      await AuthService.instance.register(
        walletName: _nameCtrl.text.trim(), // ← ປ່ຽນຈາກ name → walletName
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      _showSnack('ສະໝັກສະມາຊິກ ແລະ ສ້າງ Wallet ສຳເລັດ!');

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } on Exception catch (e) {
      // ✅ ດັກ Exception ສະເພາະ ບໍ່ໃຊ້ catch(e) ກວ້າງເກີນ
      if (!mounted) return;

      // ✅ ດຶງ Message ສະອາດ (ໂດຍບໍ່ຕ້ອງ replaceAll ເອົາ)
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showSnack(
        msg.isNotEmpty ? msg : 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່',
        isError: true,
      );
    } catch (e) {
      // ✅ ດັກ Error ທີ່ບໍ່ຄາດຄິດ (Network, Type errors, ...)
      if (!mounted) return;
      _showSnack('ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ ກະລຸນາລອງໃໝ່', isError: true);
      debugPrint('❌ Register unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError
              ? Colors.red
              : Colors.green, // ໃຊ້ colors ໂດຍກົງຖ້າ AppColors ມີບັນຫາ
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
          onPressed: () {
            // ✅ ກວດວ່າສາມາດ pop ໄດ້ບໍ່
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // ໄປຫນ້າ Register ແທນ
              Navigator.pushReplacementNamed(context, '/welcome');
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          // ✅ ຄອບດ້ວຍ Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's sign up",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // ── Fields ────────────────────────────────────────────────
              CustomTextField(
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
                controller: _nameCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'ກະລຸນາໃສ່ຊື່';
                  if (v.trim().length < 2) {
                    return 'ຊື່ຕ້ອງມີຢ່າງໜ້ອຍ 2 ຕົວອັກສອນ';
                  }
                  return null;
                },
              ),
              CustomTextField(
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'ກະລຸນາໃສ່ອີເມວ';
                  // ✅ RegEx validation
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'ຮູບແບບ Email ບໍ່ຖືກຕ້ອງ';
                  }
                  return null;
                },
              ),
              CustomTextField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ລະຫັດຜ່ານ';
                  if (v.length < 6) return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ';
                  return null;
                },
              ),
              CustomTextField(
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາຢືນຢັນລະຫັດຜ່ານ';
                  if (v != _passwordCtrl.text) return 'ລະຫັດຜ່ານບໍ່ກົງກັນ';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ✅ ໃຊ້ isLoading property
              CustomButton(
                text: 'Sign Up',
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
                onPressed: _isLoading ? null : _handleSignUp,
              ),

              const SizedBox(height: 32),

              // ✅ TextButton ແທນ GestureDetector
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
