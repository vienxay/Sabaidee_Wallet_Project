import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../widgets/custom_button.dart';
import '../../../models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.name ?? "ວຽງໄຊ";
    _lastNameController.text = widget.user?.lastName ?? "ແກ້ວວົງສີ";
    _emailController.text = "vienxay@gmail.com";
    _dobController.text = "19/10/2026";
    _genderController.text = "ຊາຍ";
    _phoneController.text = "+856 20 55 740 336";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      // TODO: UserService.uploadAvatar
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ ອະນຸຍາດໃຫ້ຂະຫຍາຍຄວາມສູງໄດ້
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SizedBox(
        height:
            MediaQuery.of(context).size.height *
            0.9, // ✅ ໃຫ້ສູງ 90% ຂອງຈໍ (ເກືອບເຕັມຈໍ)
        child: Column(
          children: [
            // ສ່ວນຫົວຂອງ Modal
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ແກ້ໄຂຂໍ້ມູນສ່ວນຕົວ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),

            // ສ່ວນ Form ປ້ອນຂໍ້ມູນ
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
                    _buildTextField(_nameController, "ຊື່ແທ້", Icons.person),
                    _buildTextField(
                      _lastNameController,
                      "ນາມສະກຸນ",
                      Icons.person_outline,
                    ),
                    _buildTextField(_emailController, "ອີເມວ", Icons.email),
                    _buildTextField(
                      _dobController,
                      "ວັນເດືອນປີເກີດ",
                      Icons.calendar_today,
                    ),
                    _buildTextField(_genderController, "ເພດ", Icons.wc),
                    _buildTextField(
                      _phoneController,
                      "ເບີໂທລະສັບ",
                      Icons.phone,
                    ),

                    const SizedBox(height: 30),

                    CustomButton(
                      text: "ບັນທຶກຂໍ້ມູນ",
                      backgroundColor: const Color(
                        0xFFF7941D,
                      ), // ✅ ໃສ່ສີສົ້ມຕາມທີ່ທ່ານຕ້ອງການ
                      // ຖ້າ CustomButton ຂອງທ່ານຮອງຮັບ textColor ໃຫ້ໃສ່ນຳເພື່ອໃຫ້ຕົວໜັງສືເປັນສີຂາວ
                      // textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          // ຂໍ້ມູນໃນໜ້າ Profile ຈະຖືກອັບເດດຕາມ Controller ທີ່ເຮົາປ້ອນ
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "ບັນທຶກຂໍ້ມູນສຳເລັດ",
                              style: TextStyle(fontFamily: 'Lao'),
                            ),
                            backgroundColor: Colors
                                .green, // ໃຫ້ SnackBar ເປັນສີຂຽວເພື່ອບອກວ່າສຳເລັດ
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ຊ່ວຍສ້າງ TextField ໃຫ້ໄວຂຶ້ນ
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

  @override
  Widget build(BuildContext context) {
    // ✅ ປ່ຽນພື້ນຫຼັງໃຫ້ເປັນສີເທົາອ່ອນຄືກັບຮູບຕົວຢ່າງ
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // ✅ ໃຊ້ AppBar ປົກກະຕິ ແຕ່ເອົາສີພື້ນອອກ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✅ ໃຫ້ປຸ່ມແກ້ໄຂຂໍ້ມູນຢູ່ດ້ານລຸ່ມສຸດສະເໝີ
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomButton(
          text: "ແກ້ໄຂຂໍ້ມູນ",
          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
          onPressed: () => _showEditProfileModal(),
          backgroundColor: const Color(0xFFF7941D),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ ຫົວຂໍ້ໃຫຍ່ຢູ່ດ້ານເທິງ
            const Text(
              "ປ້ອນຂໍ້ມູນສ່ວນຕົວ",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 30),

            // ສ່ວນສະແດງຮູບພາບ
            _buildPhotoPicker(),

            const SizedBox(height: 40),

            // ✅ ຫົວຂໍ້ຍ່ອຍ "ຂໍ້ມູນທົ່ວໄປ"
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ຂໍ້ມູນທົ່ວໄປ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ ສ່ວນສະແດງລາຍການຂໍ້ມູນ (ປັບ UI ໃຫ້ສະອາດຂຶ້ນ)
            _buildInfoList(),

            const SizedBox(height: 20), // ເວັ້ນໄລຍະຫ່າງດ້ານລຸ່ມໜ້ອຍໜຶ່ງ
          ],
        ),
      ),
    );
  }

  // ✅ ແຍກ Widget ສ່ວນ Photo Picker ເພື່ອໃຫ້ Code ສະອາດ
  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle, // ປ່ຽນເປັນວົງມົນ
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: CircleAvatar(
              // ໃຊ້ CircleAvatar ໃຫ້ເໝາະກັບຮູບວົງມົນ
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : const NetworkImage("https://via.placeholder.com/150")
                        as ImageProvider,
            ),
          ),
          // ✅ ປຸ່ມ "ປ່ຽນຮູບ" ແບບມີໄອຄອນເລັກນ້ອຍ (Optional ແຕ່ເບິ່ງດີຂຶ້ນ)
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

  // ✅ ແຍກ Widget ສ່ວນ List ຂອງຂໍ້ມູນເພື່ອUI ທີ່ສະອາດຄືກັບຮູບທີ 2
  Widget _buildInfoList() {
    return Column(
      children: [
        _infoRow("ຊື່ແທ້", _nameController.text),
        _infoRow("ນາມສະກຸນ", _lastNameController.text),
        _infoRow("ອີເມວ", widget.user?.email ?? "vienxay@gmail.com"),
        _infoRow("ວັນເດືອນປີເກີດ", "19/10/2026"),
        _infoRow("ເພດ", "ຊາຍ"),
        _infoRow(
          "ເບີໂທລະສັບ",
          "+856 20 55 740 336",
          isLast: true,
        ), // ບໍ່ມີເສັ້ນຂີດກ້ອງອັນສຸດທ້າຍ
      ],
    );
  }

  // ✅ ປັບປຸງ _infoRow ໃຫ້ມີ UI ທີ່ທັນສະໄໝຄືກັບຮູບທີ 2
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
                value,
                style: const TextStyle(fontSize: 16, color: Color(0xFF777777)),
              ),
            ],
          ),
          if (!isLast) // ✅ ສະແດງເສັ້ນຂີດກ້ອງຍົກເວັ້ນອັນສຸດທ້າຍ
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Divider(color: Color(0xFFEEEEEE), height: 1),
            ),
        ],
      ),
    );
  }
}
