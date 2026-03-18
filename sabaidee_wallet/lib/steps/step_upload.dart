// lib/steps/step_upload.dart
// ✅ 3 ຮູບ ຕາມ backend: idFront, idBack, selfie

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/upload_card.dart';

class StepUpload extends StatelessWidget {
  final File? idFront;
  final File? idBack;
  final File? selfie;
  final VoidCallback onPickIdFront;
  final VoidCallback onPickIdBack;
  final VoidCallback onPickSelfie;

  const StepUpload({
    super.key,
    this.idFront,
    this.idBack,
    this.selfie,
    required this.onPickIdFront,
    required this.onPickIdBack,
    required this.onPickSelfie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StepHeader(
          icon: Icons.upload_rounded,
          title: 'ອັບໂຫລດເອກະສານ',
          subtitle: 'ຮູບຕ້ອງຊັດ, ແສງດີ, ເຫັນຂໍ້ຄວາມທຸກຕົວ',
        ),
        UploadCard(
          title: 'ໜ້າ Passport / ບັດປະຊາຊົນ',
          subtitle: 'ຮູບ, ຊື່, ເລກ ID ຕ້ອງເຫັນຊັດ',
          icon: Icons.credit_card_rounded,
          file: idFront,
          required: true,
          onPick: onPickIdFront,
        ),
        const SizedBox(height: 12),
        UploadCard(
          title: 'ຫລັງ Passport / ບັດປະຊາຊົນ',
          subtitle: 'ຖ້າ Passport ໃຊ້ຮູບໜ້າ MRZ',
          icon: Icons.flip_rounded,
          file: idBack,
          required: true,
          onPick: onPickIdBack,
        ),
        const SizedBox(height: 12),
        UploadCard(
          title: 'Selfie ກັບ ID / Passport',
          subtitle: 'ຖື ID ຂ້າງຕົວ, ບໍ່ໃສ່ mask',
          icon: Icons.face_outlined,
          file: selfie,
          required: true,
          onPick: onPickSelfie,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.kInfoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.kInfoBdr, width: 0.5),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.kInfoTxt,
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ຮູບທັງ 3 ຈະຖືກສົ່ງໄປຢືນຢັນໂດຍທີມງານ — ໃຊ້ເວລາ 1–3 ວັນທຳການ',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.kInfoTxt,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
