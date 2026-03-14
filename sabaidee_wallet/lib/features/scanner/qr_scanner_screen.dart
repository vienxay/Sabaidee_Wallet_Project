import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerScreen extends StatefulWidget {
  final String title;
  const QrScannerScreen({super.key, this.title = 'ສະແກນ QR Code'});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  bool _hasScanned = false;
  bool _isProcessing = false; // ກັນກົດຊ້ຳຕອນດຶງຮູບ

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── ສະແກນຈາກກ້ອງ Live ──────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    _returnResult(value);
  }

  // ── ເລືອກຮູບຈາກ Gallery ──────────────────────────────────────
  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _controller.stop();

      final XFile? image = await _picker
          .pickImage(source: ImageSource.gallery, imageQuality: 100)
          .timeout(const Duration(seconds: 30), onTimeout: () => null);

      if (image == null) {
        await _controller.start();
        setState(() => _isProcessing = false);
        return;
      }

      final BarcodeCapture? result = await _controller.analyzeImage(image.path);
      if (!mounted) return;

      if (result != null && result.barcodes.isNotEmpty) {
        final value = result.barcodes.first.rawValue;
        if (value != null && value.isNotEmpty) {
          _returnResult(value);
          return;
        }
      }
      _showNotFoundDialog();
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'photo_access_denied') {
        _showPermissionDialog();
      } else {
        _showSnack('ບໍ່ສາມາດເປີດ Gallery ໄດ້: ${e.message}', isError: true);
      }
      await _controller.start();
    } catch (e) {
      if (!mounted) return;
      _showSnack('ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່', isError: true);
      await _controller.start();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── ສົ່ງຜົນກັບໄປ ─────────────────────────────────────────────
  void _returnResult(String value) {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    _controller.stop();
    Navigator.pop(context, value);
  }

  // ── ແຈ້ງເຕືອນ ─────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showNotFoundDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ບໍ່ພົບ QR Code'),
        content: const Text(
          'ບໍ່ສາມາດຊອກຫາ QR Code ໃນຮູບທີ່ເລືອກ\nກະລຸນາລອງເລືອກຮູບໃໝ່',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ປິດ Dialog
              _controller.start(); // ເປີດ Camera ກັບ
            },
            child: const Text(
              'ລອງໃໝ່',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
          TextButton(
            onPressed: _pickImageFromGallery, // ເລືອກຮູບໃໝ່ທັນທີ
            child: const Text(
              'ເລືອກຮູບໃໝ່',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ເພີ່ມ Method ນີ້ໃໝ່
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ຕ້ອງການສິດເຂົ້າເຖິງ Gallery'),
        content: const Text('ກະລຸນາອະນຸຍາດການເຂົ້າເຖິງ Gallery ໃນການຕັ້ງຄ່າ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ຕົກລົງ',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera View ──────────────────────────────────────
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // ── Frame ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF5A623), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              // ── ເສັ້ນມຸມ 4 ທິດ ─────────────────────────────
              child: Stack(
                children: [
                  _corner(top: 0, left: 0, isTop: true, isLeft: true),
                  _corner(top: 0, right: 0, isTop: true, isLeft: false),
                  _corner(bottom: 0, left: 0, isTop: false, isLeft: true),
                  _corner(bottom: 0, right: 0, isTop: false, isLeft: false),
                ],
              ),
            ),
          ),

          // ── Loading Overlay ───────────────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFF5A623)),
                    SizedBox(height: 16),
                    Text(
                      'ກຳລັງວິເຄາະຮູບ...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // ── ປຸ່ມລຸ່ມ ──────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  'ວາງ QR Code ໃຫ້ຢູ່ໃນກອບ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),

                // ── ປຸ່ມເລືອກຮູບຈາກ Gallery ──────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickImageFromGallery,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFFF5A623),
                    ),
                    label: const Text(
                      'ເລືອກຮູບຈາກ Gallery',
                      style: TextStyle(color: Color(0xFFF5A623), fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5A623)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget ມຸມກອບ ─────────────────────────────────────────────
  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
