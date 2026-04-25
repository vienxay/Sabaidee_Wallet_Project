// lib/features/kyc/kyc_screen.dart
// ✅ ອັບເດດຕາມ Design:
//    - Single page form
//    - Fields: fullName, gender, dateOfBirth, nationality, email,
//              passportNumber, expiryDate, passportScan
//    - ປຸ່ມ "ຢືນຢັນ"

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/kyc_model.dart';
import '../../models/kyc_status.dart';
import '../../services/kyc_service.dart';
import '../../services/kyc_gate_service.dart';
import '../../widgets/common_widgets.dart';
import 'kyc_success_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _loading = false;

  final _data = KycModel();

  // Controllers
  final _fullName = TextEditingController();
  final _nationality = TextEditingController();
  final _email = TextEditingController();
  final _passportNumber = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;
  DateTime? _expiryDate;
  File? _passportScan;

  final _picker = ImagePicker();

  KycRouteArgs? get _args =>
      ModalRoute.of(context)?.settings.arguments as KycRouteArgs?;

  @override
  void dispose() {
    _fullName.dispose();
    _nationality.dispose();
    _email.dispose();
    _passportNumber.dispose();
    super.dispose();
  }

  // ── Date Pickers ─────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => _datePickerTheme(ctx, child!),
    );
    if (d != null) setState(() => _dateOfBirth = d);
  }

  Future<void> _pickExpiry() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2060),
      builder: (ctx, child) => _datePickerTheme(ctx, child!),
    );
    if (d != null) setState(() => _expiryDate = d);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.kGreen,
        onPrimary: Colors.white,
        surface: AppColors.kCard,
      ),
    ),
    child: child,
  );

  // ── Image Picker ──────────────────────────────────────────────────────────
  Future<void> _pickPassportScan() async {
    final src = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(),
    );
    if (src == null) return;
    final source = src == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final f = await _picker.pickImage(source: source, imageQuality: 85);
    if (f != null) setState(() => _passportScan = File(f.path));
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool get _canSubmit =>
      _fullName.text.trim().isNotEmpty &&
      _gender != null &&
      _dateOfBirth != null &&
      _nationality.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _passportNumber.text.trim().isNotEmpty &&
      _expiryDate != null &&
      _passportScan != null;

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    _data.fullName = _fullName.text.trim();
    _data.gender = _gender ?? '';
    _data.dateOfBirth = _dateOfBirth;
    _data.nationality = _nationality.text.trim();
    _data.email = _email.text.trim();
    _data.passportNumber = _passportNumber.text.trim().toUpperCase();
    _data.expiryDate = _expiryDate;
    _data.passportScan = _passportScan;

    setState(() => _loading = true);
    final result = await KycService.submitKyc(data: _data);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      await KycGateService.instance.saveStatus(KycStatus.submitted);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => KycSuccessScreen(
            name: _data.fullName,
            referenceId: '',
            onContinue: _args?.onCompleted,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'ເກີດຂໍ້ຜິດພາດ'),
          backgroundColor: AppColors.kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: AppColors.kCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 20,
            color: AppColors.kText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'KYC',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.kText,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.kBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.kGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.kGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ຢືນຢັນຕົວຕົນຂອງທ່ານ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Form Card ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.kBorder, width: 0.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Full Name
                  KycTextField(
                    label: 'Full Name',
                    controller: _fullName,
                    hint: 'Full Name',
                    required: true,
                  ),
                  const SizedBox(height: 14),

                  // Gender
                  _buildLabel('Gender'),
                  const SizedBox(height: 5),
                  _GenderDropdown(
                    value: _gender,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),

                  // Date of Birth
                  _buildLabel('Date of Birth'),
                  const SizedBox(height: 5),
                  _DateField(
                    value: _dateOfBirth,
                    hint: 'dd/mm/yyyy',
                    onTap: _pickDob,
                  ),
                  const SizedBox(height: 14),

                  // Nationality
                  KycTextField(
                    label: 'Nationality',
                    controller: _nationality,
                    hint: 'e.g United Kingdom',
                    required: true,
                  ),
                  const SizedBox(height: 14),

                  // Email Address
                  KycTextField(
                    label: 'Email Address',
                    controller: _email,
                    hint: 'email@gmail.com',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Passport Number
                  KycTextField(
                    label: 'Passport Number',
                    controller: _passportNumber,
                    hint: 'AZ123456',
                    required: true,
                    formatters: [],
                  ),
                  const SizedBox(height: 14),

                  // Expiry Date
                  _buildLabel('Expiry Date'),
                  const SizedBox(height: 5),
                  _DateField(
                    value: _expiryDate,
                    hint: 'dd/mm/yyyy',
                    onTap: _pickExpiry,
                  ),
                  const SizedBox(height: 14),

                  // Passport Scan
                  _buildLabel('Passport scan (BIO-DATE-PAGE)'),
                  const SizedBox(height: 8),
                  _PassportScanBox(
                    file: _passportScan,
                    onTap: _pickPassportScan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Button ────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.kCard,
          border: Border(top: BorderSide(color: AppColors.kBorder, width: 0.5)),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fullName,
            _nationality,
            _email,
            _passportNumber,
          ]),
          builder: (_, __) {
            final ok = _canSubmit;
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: ok && !_loading
                    ? () {
                        HapticFeedback.mediumImpact();
                        _submit();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  disabledBackgroundColor: const Color(
                    0xFFF5A623,
                  ).withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                        'ຢືນຢັນ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12.5,
      color: AppColors.kMuted,
      fontWeight: FontWeight.w500,
    ),
  );
}

// ─── Gender Dropdown ──────────────────────────────────────────────────────────
class _GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text(
            'Select gender',
            style: TextStyle(color: AppColors.kMuted, fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.kMuted,
          ),
          dropdownColor: AppColors.kCard,
          style: const TextStyle(color: AppColors.kText, fontSize: 14),
          items: const [
            // ✅ FIX: ສົ່ງ 'M' / 'F' ຕົງກັບ backend enum ['M', 'F']
            DropdownMenuItem(value: 'M', child: Text('Male')),
            DropdownMenuItem(value: 'F', child: Text('Female')),
            // ✅ FIX: ລຶບ 'other' ອອກ — backend ບໍ່ຮັບ
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Date Field ───────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;

  const _DateField({
    required this.value,
    required this.hint,
    required this.onTap,
  });

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.kBorder, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? _format(value!) : hint,
              style: TextStyle(
                fontSize: 14,
                color: value != null ? AppColors.kText : AppColors.kMuted,
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.kMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Passport Scan Box ────────────────────────────────────────────────────────
class _PassportScanBox extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;

  const _PassportScanBox({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.kGreen : const Color(0xFFF5A623),
            width: 1.5,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(file!, height: 140, fit: BoxFit.cover),
              )
            : Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFFF5A623),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Drag and drop or click to\nupload a clear photo of\nyour passport',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.kMuted),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'JPG, PNG or PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF5A623),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
