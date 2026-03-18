import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/kyc_model.dart';
import '../widgets/common_widgets.dart';

class StepReview extends StatelessWidget {
  final KycModel data;
  final ValueChanged<bool?> onToggleConsentData,
      onToggleConsentPdpa,
      onTogglePep;
  final ValueChanged<String?> onFundChanged;

  const StepReview({
    super.key,
    required this.data,
    required this.onToggleConsentData,
    required this.onToggleConsentPdpa,
    required this.onTogglePep,
    required this.onFundChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StepHeader(
          icon: Icons.fact_check_outlined,
          title: 'ກວດທານ ແລະ ຢືນຢັນ',
          subtitle: 'ກວດສອບຂໍ້ມູນກ່ອນສົ່ງ',
        ),
        SectionCard(
          title: 'ສະຫຼຸບຂໍ້ມູນ',
          child: Column(
            children: [
              _ReviewRow(
                'ຊື່ເຕັມ',
                data.fullName.isEmpty ? '—' : data.fullName,
              ),
              _ReviewRow(
                'ຊື່ (ລາວ)',
                data.laoName.isEmpty ? '—' : data.laoName,
              ),
              _ReviewRow('ເພດ', data.gender == 'M' ? 'ຊາຍ' : 'ຍິງ'),
              _ReviewRow(
                'ວັນເດືອນປີເກີດ',
                data.dobFormatted.isEmpty ? '—' : data.dobFormatted,
              ),
              _ReviewRow(
                'ເລກ Passport',
                data.passportNumber.isEmpty ? '—' : data.passportNumber,
                mono: true,
              ),
              _ReviewRow(
                'ວັນໝົດອາຍຸ',
                data.expiryFormatted.isEmpty ? '—' : data.expiryFormatted,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'AML / PEP',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ທ່ານເປັນ PEP ຫລືບໍ?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.kText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ບຸກຄົນທາງດ້ານການເມືອງ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: data.isPep,
                    onChanged: onTogglePep,
                    activeColor: AppColors.kGreen,
                  ),
                ],
              ),
              const Divider(
                height: 16,
                thickness: 0.5,
                color: AppColors.kBorder,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ແຫລ່ງທີ່ມາຂອງທຶນ',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: data.fundSource,
                    onChanged: onFundChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.kBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.kBorder,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.kBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.kText,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ເງິນເດືອນ',
                        child: Text('ເງິນເດືອນ / ການຈ້າງງານ'),
                      ),
                      DropdownMenuItem(
                        value: 'ທຸລະກິດ',
                        child: Text('ທຸລະກິດສ່ວນຕົວ'),
                      ),
                      DropdownMenuItem(
                        value: 'ມໍລະດົກ',
                        child: Text('ມໍລະດົກ'),
                      ),
                      DropdownMenuItem(
                        value: 'ການລົງທຶນ',
                        child: Text('ການລົງທຶນ'),
                      ),
                      DropdownMenuItem(value: 'ອື່ນໆ', child: Text('ອື່ນໆ')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'ການຍິນຍອມ',
          child: Column(
            children: [
              ConsentTile(
                checked: data.consentData,
                onChanged: onToggleConsentData,
                title: 'ຂ້ອຍຮັບຮອງວ່າຂໍ້ມູນທັງໝົດຖືກຕ້ອງ',
                subtitle: 'ຕາມ ກ.ຈ.ສ.ສ.ລ. AML/CFT ມາດຕາ 10',
                required: true,
              ),
              const SizedBox(height: 4),
              ConsentTile(
                checked: data.consentPdpa,
                onChanged: onToggleConsentPdpa,
                title: 'ຍິນຍອມໃຫ້ເກັບ ແລະ ໃຊ້ຂໍ້ມູນສ່ວນຕົວ',
                subtitle: 'ສຳລັບການກວດສອບຕົວຕົນ ແລະ ບໍລິການທາງການເງິນ',
                required: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  final bool mono;
  const _ReviewRow(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.kMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.kText,
              fontFamily: mono ? 'Courier' : null,
              letterSpacing: mono ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}
