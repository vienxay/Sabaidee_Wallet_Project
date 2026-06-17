import 'package:flutter/material.dart';
import '../../../core/app_constants.dart';
import '../../../services/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _currentCtrl    = TextEditingController();
  final _newCtrl        = TextEditingController();
  final _confirmCtrl    = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _loading     = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.post(
        AppConstants.authChangePass,
        {
          'currentPassword': _currentCtrl.text.trim(),
          'newPassword':     _newCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success ? '✅ ປ່ຽນລະຫັດຜ່ານສຳເລັດ' : res.message),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ປ່ຽນລະຫັດຜ່ານ',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2FE4).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2F2FE4).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2F2FE4), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ລະຫັດຜ່ານໃໝ່ຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2F2FE4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildPasswordField(
                controller:  _currentCtrl,
                label:       'ລະຫັດຜ່ານປະຈຸບັນ',
                show:        _showCurrent,
                onToggle:    () => setState(() => _showCurrent = !_showCurrent),
                validator:   (v) => (v == null || v.isEmpty) ? 'ກະລຸນາໃສ່ລະຫັດຜ່ານປະຈຸບັນ' : null,
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller:  _newCtrl,
                label:       'ລະຫັດຜ່ານໃໝ່',
                show:        _showNew,
                onToggle:    () => setState(() => _showNew = !_showNew),
                validator:   (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາໃສ່ລະຫັດຜ່ານໃໝ່';
                  if (v.length < 6) return 'ຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                  if (v == _currentCtrl.text) return 'ລະຫັດໃໝ່ຕ້ອງຕ່າງຈາກເກົ່າ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller:  _confirmCtrl,
                label:       'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
                show:        _showConfirm,
                onToggle:    () => setState(() => _showConfirm = !_showConfirm),
                validator:   (v) {
                  if (v == null || v.isEmpty) return 'ກະລຸນາຢືນຢັນລະຫັດຜ່ານ';
                  if (v != _newCtrl.text) return 'ລະຫັດຜ່ານບໍ່ກົງກັນ';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7941D),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'ບັນທຶກລະຫັດຜ່ານໃໝ່',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller:    controller,
        obscureText:   !show,
        validator:     validator,
        style:         const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText:   label,
          labelStyle:  const TextStyle(color: Color(0xFF888888)),
          filled:      true,
          fillColor:   Colors.white,
          prefixIcon:  const Icon(Icons.lock_outline, color: Color(0xFFF7941D)),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF999999),
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF7941D), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      );
}
