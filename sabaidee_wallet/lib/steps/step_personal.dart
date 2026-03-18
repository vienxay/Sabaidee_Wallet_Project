import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../models/kyc_model.dart';
import '../widgets/common_widgets.dart';

class StepPersonal extends StatelessWidget {
  final KycModel data;
  final TextEditingController fullName, laoName, placeOfBirth, phone;
  final VoidCallback onPickDob;
  final ValueChanged<String?> onGenderChanged;
  final Widget? extraContent; // ✅ ເພີ່ມບັ້ນນີ້

  const StepPersonal({
    super.key,
    required this.data,
    required this.fullName,
    required this.laoName,
    required this.placeOfBirth,
    required this.phone,
    required this.onPickDob,
    required this.onGenderChanged,
    this.extraContent, // ✅ optional
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          icon: Icons.person_outline_rounded,
          title: 'ຂໍ້ມູນສ່ວນຕົວ',
          subtitle: 'ກວດສອບໃຫ້ຕົງກັບ Passport ຂອງທ່ານ',
        ),
        SectionCard(
          title: 'ຊື່ ແລະ ນາມສະກຸນ',
          child: Column(
            children: [
              KycTextField(
                label: 'ຊື່ເຕັມ (ຕາມ Passport)',
                controller: fullName,
                required: true,
              ),
              const SizedBox(height: 12),
              KycTextField(label: 'ຊື່ (ພາສາລາວ)', controller: laoName),
            ],
          ),
        ),
        SectionCard(
          title: 'ຂໍ້ມູນທົ່ວໄປ',
          child: Column(
            children: [
              KycDateField(
                label: 'ວັນເດືອນປີເກີດ',
                value: data.dob,
                onTap: onPickDob,
                fmt: data.fmtDate,
                required: true,
              ),
              const SizedBox(height: 12),
              KycTextField(label: 'ສະຖານທີ່ເກີດ', controller: placeOfBirth),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ເພດ',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      GenderChip(
                        label: 'ຊາຍ',
                        value: 'M',
                        groupValue: data.gender,
                        onChanged: onGenderChanged,
                      ),
                      const SizedBox(width: 10),
                      GenderChip(
                        label: 'ຍິງ',
                        value: 'F',
                        groupValue: data.gender,
                        onChanged: onGenderChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'ຂໍ້ມູນຕິດຕໍ່',
          child: KycTextField(
            label: 'ເບີໂທລະສັບ',
            controller: phone,
            keyboardType: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        // ✅ render extraContent ຖ້າມີ
        if (extraContent != null) extraContent!,
      ],
    );
  }
}
