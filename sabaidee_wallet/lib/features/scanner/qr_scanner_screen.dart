import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final String title;

  const QrScannerScreen({super.key, this.title = 'Scan QR Code'});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  bool _hasScanned = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    _returnResult(value);
  }

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
        if (mounted) {
          setState(() => _isProcessing = false);
        }
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
        _showSnack('Unable to open gallery: ${e.message}', isError: true);
      }
      await _controller.start();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.', isError: true);
      await _controller.start();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _returnResult(String value) {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);
    _controller.stop();
    Navigator.pop(context, value);
  }

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
        title: const Text('QR Code not found'),
        content: const Text(
          'No QR Code was found in the selected image.\nPlease choose another image.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.start();
            },
            child: const Text(
              'Try Again',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text(
              'Choose Image',
              style: TextStyle(color: Color(0xFFF5A623)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gallery Permission Needed'),
        content: const Text(
          'Please allow gallery access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
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
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
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
                      'Analyzing image...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  'Place the QR code inside the frame',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickImageFromGallery,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFFF5A623),
                    ),
                    label: const Text(
                      'Choose Image From Gallery',
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
                ? const BorderSide(color: Color(0xFFF5A623), width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Color(0xFFF5A623), width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Color(0xFFF5A623), width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Color(0xFFF5A623), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
