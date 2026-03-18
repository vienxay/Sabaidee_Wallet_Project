import 'dart:io';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class UploadCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final File? file;
  final bool required;
  final VoidCallback onPick;

  const UploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.file,
    required this.required,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.kGreenLight : AppColors.kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? AppColors.kGreen : AppColors.kBorder,
            width: hasFile ? 1.5 : 0.5,
          ),
        ),
        child: hasFile
            ? _PreviewContent(file: file!, onPick: onPick)
            : _EmptyContent(
                title: title,
                subtitle: subtitle,
                icon: icon,
                required: required,
              ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final File file;
  final VoidCallback onPick;
  const _PreviewContent({required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(
            file,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.kGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ປ່ຽນ',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool required;
  const _EmptyContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.kGreenLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.kGreen, size: 26),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kText,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: AppColors.kError, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.kMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.kGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'ຖ່າຍ / ເລືອກຮູບ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
