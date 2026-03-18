import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../models/kyc_model.dart';
import '../widgets/common_widgets.dart';

class StepPassport extends StatelessWidget {
  final KycModel data;
  final TextEditingController passportNum;
  final VoidCallback onPickExpiry;

  const StepPassport({
    super.key,
    required this.data,
    required this.passportNum,
    required this.onPickExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StepHeader(
          icon: Icons.book_outlined,
          title: 'ຂໍ້ມູນ Passport',
          subtitle: 'ກວດສອບວ່າ Passport ຍັງບໍ່ໝົດອາຍຸ',
        ),
        SectionCard(
          title: 'ລາຍລະອຽດ Passport',
          child: Column(
            children: [
              KycTextField(
                label: 'ເລກ Passport',
                controller: passportNum,
                required: true,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
              ),
              const SizedBox(height: 12),
              KycDateField(
                label: 'ວັນໝົດອາຍຸ',
                value: data.expiryDate,
                onTap: onPickExpiry,
                fmt: data.fmtDate,
                required: true,
              ),
            ],
          ),
        ),
        if (data.isPassportExpiringSoon) _WarningBanner(),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kWarningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kWarningBdr, width: 0.5),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.kWarningTxt,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Passport ຂອງທ່ານໃກ້ຈະໝົດອາຍຸ — ກວດສອບກ່ອນດຳເນີນ',
              style: TextStyle(fontSize: 13, color: AppColors.kWarningTxt),
            ),
          ),
        ],
      ),
    );
  }
}
