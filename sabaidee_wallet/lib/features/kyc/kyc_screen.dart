// lib/features/kyc/kyc_screen.dart
// ✅ ຕົງກັບ backend ຈິງ:
//    - 3 ຮູບ: idFront, idBack, selfie
//    - fields: fullName, idNumber, idType, dateOfBirth, phone, address
//    - status: submitted → verified | rejected

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/kyc_model.dart';
import '../../models/kyc_status.dart';
import '../../services/kyc_service.dart';
import '../../services/kyc_gate_service.dart';
import '../../steps/step_personal.dart';
import '../../steps/step_upload.dart';
import '../../steps/step_review.dart';
import '../../widgets/common_widgets.dart';
import 'kyc_success_screen.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> with TickerProviderStateMixin {
  int _step = 0;
  bool _loading = false;
  late final AnimationController _pageCtrl;
  late Animation<double> _fadeAnim;

  final _data = KycModel();
  final _fullName = TextEditingController();
  final _idNumber = TextEditingController(); // ✅ idNumber ແທນ passportNumber
  final _phone = TextEditingController();
  final _address = TextEditingController(); // ✅ address field ໃໝ່

  // ✅ 3 ຮູບ ຕາມ backend
  // idFront, idBack, selfie ຢູ່ໃນ _data.idFront/idBack/selfie

  final _picker = ImagePicker();
  // ✅ 3 ຂັ້ນຕອນ: ຂໍ້ມູນ → ອັບໂຫລດ → ຢືນຢັນ (ລຶບ step passport ອອກ)
  final _stepLabels = ['ຂໍ້ມູນ', 'ອັບໂຫລດ', 'ຢືນຢັນ'];

  KycRouteArgs? get _args =>
      ModalRoute.of(context)?.settings.arguments as KycRouteArgs?;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fullName.dispose();
    _idNumber.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _go(int next) {
    _syncControllers();
    _pageCtrl.reverse().then((_) {
      setState(() => _step = next);
      _pageCtrl.forward();
    });
  }

  void _syncControllers() {
    _data.fullName = _fullName.text.trim();
    _data.idNumber = _idNumber.text.trim().toUpperCase();
    _data.phone = _phone.text.trim();
    _data.address = _address.text.trim();
  }

  Future<void> _pickImage(String field) async {
    final src = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(),
    );
    if (src == null) return;
    final source = src == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final f = await _picker.pickImage(source: source, imageQuality: 85);
    if (f != null) {
      setState(() {
        if (field == 'idFront') _data.idFront = File(f.path);
        if (field == 'idBack') _data.idBack = File(f.path);
        if (field == 'selfie') _data.selfie = File(f.path);
      });
    }
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.kGreen,
            onPrimary: Colors.white,
            surface: AppColors.kCard,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _data.dateOfBirth = d);
  }

  bool get _canProceed {
    switch (_step) {
      case 0: // ຂໍ້ມູນ
        return _fullName.text.trim().isNotEmpty &&
            _idNumber.text.trim().isNotEmpty &&
            _phone.text.trim().isNotEmpty &&
            _data.dateOfBirth != null;
      case 1: // ອັບໂຫລດ — ຕ້ອງຄົບ 3 ຮູບ
        return _data.uploadComplete;
      case 2: // ຢືນຢັນ
        return _data.consentData && _data.consentPdpa;
      default:
        return false;
    }
  }

  String get _hintText {
    switch (_step) {
      case 0:
        return 'ກະລຸນາລະບຸຊື່, ເລກ ID ແລະ ເບີໂທ';
      case 1:
        return 'ກະລຸນາອັບໂຫລດຮູບໃຫ້ຄົບ 3 ໃບ';
      case 2:
        return 'ກະລຸນາຍິນຍອມ ກ່ອນຈຶ່ງສົ່ງ';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    _syncControllers();
    setState(() => _loading = true);

    final result = await KycService.submitKyc(data: _data);
    setState(() => _loading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      // ✅ ບັນທຶກ submitted (ລໍຖ້າ admin approve)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          KycProgressBar(
            current: _step,
            total: _stepLabels.length,
            labels: _stepLabels,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.kCard,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: _step > 0
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.kText,
            ),
            onPressed: () => _go(_step - 1),
          )
        : IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.kText,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
    title: Column(
      children: [
        const Text(
          'ຢືນຢັນຕົວຕົນ KYC',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.kText,
          ),
        ),
        Text(
          'ຂັ້ນຕອນ ${_step + 1} ຈາກ ${_stepLabels.length}',
          style: const TextStyle(fontSize: 12, color: AppColors.kMuted),
        ),
      ],
    ),
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: AppColors.kBorder),
    ),
  );

  Widget _buildStep() {
    switch (_step) {
      case 0: // ✅ ຂໍ້ມູນ: fullName, idNumber, idType, dateOfBirth, phone, address
        return StepPersonal(
          data: _data,
          fullName: _fullName,
          laoName: TextEditingController(), // unused — kept for compat
          placeOfBirth: _address, // ✅ reuse as address
          phone: _phone,
          onPickDob: _pickDob,
          onGenderChanged: (_) {}, // no gender in backend schema
          // ── Extra: idNumber + idType ──
          extraContent: _buildIdFields(),
        );
      case 1: // ✅ 3 ຮູບ
        return StepUpload(
          idFront: _data.idFront,
          idBack: _data.idBack,
          selfie: _data.selfie,
          onPickIdFront: () => _pickImage('idFront'),
          onPickIdBack: () => _pickImage('idBack'),
          onPickSelfie: () => _pickImage('selfie'),
        );
      case 2: // ຢືນຢັນ + consent
        return StepReview(
          data: _data,
          onToggleConsentData: (v) => setState(() => _data.consentData = v!),
          onToggleConsentPdpa: (v) => setState(() => _data.consentPdpa = v!),
          onTogglePep: (v) => setState(() => _data.isPep = v!),
          onFundChanged: (v) => setState(() => _data.fundSource = v!),
        );
      default:
        return const SizedBox();
    }
  }

  // ── ID Number + ID Type (ເພີ່ມໃນ step 0) ─────────────────────────────────
  Widget _buildIdFields() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // ID Type selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ປະເພດເອກະສານ',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.kMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _IdTypeChip(
                  label: 'Passport',
                  value: 'passport',
                  selected: _data.idType,
                  onTap: () => setState(() => _data.idType = 'passport'),
                ),
                const SizedBox(width: 10),
                _IdTypeChip(
                  label: 'ບັດປະຊາຊົນ',
                  value: 'national_id',
                  selected: _data.idType,
                  onTap: () => setState(() => _data.idType = 'national_id'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ID Number
        KycTextField(
          label:
              'ເລກ ${_data.idType == 'passport' ? 'Passport' : 'ບັດປະຊາຊົນ'}',
          controller: _idNumber,
          required: true,
          formatters: [], // allow all characters
        ),
      ],
    );
  }

  Widget _buildBottomNav() => Container(
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
      animation: Listenable.merge([_fullName, _idNumber, _phone]),
      builder: (_, __) {
        final ok = _canProceed;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: ok && !_loading
                    ? () {
                        HapticFeedback.mediumImpact();
                        _step < _stepLabels.length - 1
                            ? _go(_step + 1)
                            : _submit();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kGreen,
                  disabledBackgroundColor: const Color(0xFFB2DDD1),
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
                    : Text(
                        _step == _stepLabels.length - 1 ? 'ສົ່ງ KYC' : 'ຕໍ່ໄປ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (!ok && !_loading) ...[
              const SizedBox(height: 8),
              Text(
                _hintText,
                style: const TextStyle(fontSize: 12, color: AppColors.kMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    ),
  );
}

// ─── ID Type Chip ─────────────────────────────────────────────────────────────
class _IdTypeChip extends StatelessWidget {
  final String label, value, selected;
  final VoidCallback onTap;
  const _IdTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kGreen : AppColors.kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.kGreen : AppColors.kBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.kMuted,
          ),
        ),
      ),
    );
  }
}
