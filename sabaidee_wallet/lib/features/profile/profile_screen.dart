// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../widgets/custom_button.dart';
import '../../../services/profile_service.dart';
import '../../../core/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;

  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender; // ✅ ໃຊ້ String? ແທນ Controller

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await ProfileService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile.name ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _emailController.text = profile.email ?? '';
        _dobController.text = profile.dateOfBirth ?? '';
        _phoneController.text = profile.phone ?? '';
        // ✅ ກວດ gender ໃຫ້ match enum
        const validGenders = ['male', 'female', 'other'];
        _selectedGender = validGenders.contains(profile.gender)
            ? profile.gender
            : null;
        _profileImageUrl = profile.profileImage;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── ເລືອກວັນເດືອນປີເກີດ ─────────────────────────────────────
  Future<void> _pickDate() async {
    DateTime? initial;
    if (_dobController.text.isNotEmpty) {
      initial = DateTime.tryParse(_dobController.text);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // ✅ ISO format "2000-01-01" → server parse ໄດ້
      _dobController.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // ✅ ຫຼຸດຂະໜາດ
      maxHeight: 800,
      imageQuality: 70, // ✅ ຫຼຸດ quality → file ນ້ອຍລົງ → upload ໄວຂຶ້ນ
    );
    if (pickedFile == null) return;

    setState(() => _imageFile = File(pickedFile.path));

    final newUrl = await ProfileService.uploadAvatar(File(pickedFile.path));
    if (newUrl != null && mounted) {
      setState(() => _profileImageUrl = newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ອັບໂຫລດຮູບສຳເລັດ'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // ✅ ສົ່ງ null ຖ້າ field ຫວ່າງ — ບໍ່ສົ່ງ empty string
    String? nullIfEmpty(String text) =>
        text.trim().isEmpty ? null : text.trim();

    final success = await ProfileService.updateProfile(
      name: nullIfEmpty(_nameController.text),
      lastName: nullIfEmpty(_lastNameController.text),
      phone: nullIfEmpty(_phoneController.text),
      dateOfBirth: nullIfEmpty(_dobController.text),
      gender: _selectedGender,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      // ✅ ສະແດງ SnackBar ກ່ອນ ແລ້ວຄ່ອຍປິດ modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'ບັນທຶກຂໍ້ມູນສຳເລັດ' : 'ເກີດຂໍ້ຜິດພາດ'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      Navigator.pop(context);
      if (success) _loadProfile();
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        // ✅ ໃຊ້ StatefulBuilder ສຳລັບ dropdown
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ແກ້ໄຂຂໍ້ມູນສ່ວນຕົວ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'ຊື່ແທ້', Icons.person),
                      _buildTextField(
                        _lastNameController,
                        'ນາມສະກຸນ',
                        Icons.person_outline,
                      ),
                      _buildReadOnlyField(
                        _emailController,
                        'ອີເມວ',
                        Icons.email,
                      ),
                      _buildDateField(),
                      _buildTextField(
                        _phoneController,
                        'ເບີໂທລະສັບ',
                        Icons.phone,
                      ),

                      // ✅ Gender Dropdown
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'ເພດ',
                            prefixIcon: const Icon(
                              Icons.wc,
                              color: Colors.orange,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('ຊາຍ')),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('ຍິງ'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('ອື່ນໆ'),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() => _selectedGender = val);
                          },
                        ),
                      ),

                      const SizedBox(height: 30),
                      _isSaving
                          ? const CircularProgressIndicator(
                              color: Color(0xFFF7941D),
                            )
                          : CustomButton(
                              text: 'ບັນທຶກຂໍ້ມູນ',
                              backgroundColor: const Color(0xFFF7941D),
                              onPressed: _saveProfile,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _dobController,
        readOnly: true, // ✅ ບໍ່ໃຫ້ພິມຟຣີ
        onTap: _pickDate,
        decoration: InputDecoration(
          labelText: 'ວັນເດືອນປີເກີດ',
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          suffixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.grey,
            size: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomButton(
          text: 'ແກ້ໄຂຂໍ້ມູນ',
          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
          onPressed: _showEditProfileModal,
          backgroundColor: const Color(0xFFF7941D),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF7941D)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ຂໍ້ມູນສ່ວນຕົວ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPhotoPicker(),
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ຂໍ້ມູນທົ່ວໄປ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              // ✅ ໃຊ້ backgroundImage ສະເພາະເມື່ອມີຮູບ
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!) as ImageProvider
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? NetworkImage('${AppConstants.apiBaseUrl}$_profileImageUrl')
                  : null,
              // ✅ ຖ້າບໍ່ມີຮູບ → ສະແດງ Icon ແທນ (ບໍ່ຕ້ອງໃຊ້ Asset)
              child:
                  (_imageFile == null &&
                      (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    // ✅ Gender ສະແດງເປັນ label ພາສາລາວ
    String genderLabel = '-';
    if (_selectedGender == 'male')
      genderLabel = 'ຊາຍ';
    else if (_selectedGender == 'female')
      genderLabel = 'ຍິງ';
    else if (_selectedGender == 'other')
      genderLabel = 'ອື່ນໆ';

    return Column(
      children: [
        _infoRow('ຊື່ແທ້', _nameController.text),
        _infoRow('ນາມສະກຸນ', _lastNameController.text),
        _infoRow('ອີເມວ', _emailController.text),
        _infoRow('ວັນເດືອນປີເກີດ', _dobController.text),
        _infoRow('ເພດ', genderLabel),
        _infoRow('ເບີໂທລະສັບ', _phoneController.text, isLast: true),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555555),
                ),
              ),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontSize: 16, color: Color(0xFF777777)),
              ),
            ],
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Divider(color: Color(0xFFEEEEEE), height: 1),
            ),
        ],
      ),
    );
  }
}
