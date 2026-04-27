import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/core.dart';
import '../../models/app_models.dart';
import '../../services/profile_service.dart';

class HomeTopBar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final UserModel? user;
  final VoidCallback? onImageUpdated;

  const HomeTopBar({
    super.key,
    required this.scaffoldKey,
    this.user,
    this.onImageUpdated,
  });

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _profileImageUrl; // ✅ เก็บ URL จาก ProfileService

  @override
  void initState() {
    super.initState();
    _loadProfileImage(); // ✅ โหลดรูปจาก Profile collection
  }

  // ✅ ดึง profileImage จาก ProfileService (ไม่ใช่ UserModel)
  Future<void> _loadProfileImage() async {
    final profile = await ProfileService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _profileImageUrl = profile.profileImage;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: const Text('ເລືອກຈາກ Gallery'),
              onTap: () {
                Navigator.pop(context);
                _upload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: const Text('ຖ່າຍຈາກ Camera'),
              onTap: () {
                Navigator.pop(context);
                _upload(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _upload(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 50, // ✅ ลดจาก 80 → 50
      maxWidth: 400, // ✅ ลดจาก 800 → 400
      maxHeight: 400,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      // ✅ ใช้ ProfileService.uploadAvatar() — endpoint/method/field ถูกต้องทั้งหมด
      final newUrl = await ProfileService.uploadAvatar(File(picked.path));

      if (newUrl != null && mounted) {
        setState(
          () => _profileImageUrl = '${AppConstants.apiBaseUrl}$newUrl',
        ); // ✅ full URL
        widget.onImageUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ອັບເດດຮູບໂປຣໄຟລ໌ສຳເລັດ ✅'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => widget.scaffoldKey.currentState?.openDrawer(),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textDark,
                  size: 26,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textDark,
                      size: 26,
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        // ✅ ใช้ _profileImageUrl แทน widget.user?.profileImage
                        child:
                            _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_uploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_uploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name.isNotEmpty ? name : '...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
