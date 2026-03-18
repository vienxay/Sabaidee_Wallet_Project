// lib/features/kyc/kyc_success_screen.dart

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class KycSuccessScreen extends StatefulWidget {
  final String name;
  final String referenceId;
  final VoidCallback? onContinue; // ← callback ກັບໄປດຳເນີນການ payment

  const KycSuccessScreen({
    super.key,
    required this.name,
    required this.referenceId,
    this.onContinue,
  });

  @override
  State<KycSuccessScreen> createState() => _KycSuccessScreenState();
}

class _KycSuccessScreenState extends State<KycSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCallback = widget.onContinue != null;

    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon ────────────────────────────────────────────────
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'ສົ່ງຂໍ້ມູນສຳເລັດ!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'ທີມງານຈະກວດສອບ KYC ຂອງ ${widget.name.isNotEmpty ? widget.name : "ທ່ານ"}\nພາຍໃນ 1–3 ວັນທຳການ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.kMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Reference ID ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kGreenLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.kGreen.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ລະຫັດອ້າງອີງ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.referenceId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kGreenDark,
                            letterSpacing: 1.2,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SMS notice ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.kBorder, width: 0.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: AppColors.kGreen,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ທ່ານຈະໄດ້ຮັບ SMS ເມື່ອການຢືນຢັນສຳເລັດ\nຫລັງຈາກນັ້ນຈະໂອນໄດ້ໂດຍບໍ່ຈຳກັດ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.kMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── CTA buttons ─────────────────────────────────────────
                  // ຖ້າມາຈາກໜ້າ payment → ສະແດງ "ກັບໄປດຳເນີນການ"
                  if (hasCallback) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop ກັບໄປ payment screen ແລ້ວ trigger callback
                          Navigator.of(context).popUntil(
                            (r) => r.settings.name == '/home' || r.isFirst,
                          );
                          widget.onContinue!();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ກັບໄປດຳເນີນການ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ກັບໜ້າຫລັກ
                  SizedBox(
                    width: double.infinity,
                    height: hasCallback ? 44 : 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).popUntil(
                        (r) => r.settings.name == '/home' || r.isFirst,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: hasCallback
                              ? AppColors.kBorder
                              : AppColors.kGreen,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'ກັບຄືນໜ້າຫລັກ',
                        style: TextStyle(
                          color: hasCallback
                              ? AppColors.kMuted
                              : AppColors.kGreen,
                          fontSize: hasCallback ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
