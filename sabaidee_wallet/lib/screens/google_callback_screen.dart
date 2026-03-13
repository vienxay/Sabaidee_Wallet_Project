// lib/screens/google_callback_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class GoogleCallbackScreen extends StatefulWidget {
  static const routeName = '/auth/callback';

  const GoogleCallbackScreen({super.key});

  @override
  State<GoogleCallbackScreen> createState() => _GoogleCallbackScreenState();
}

class _GoogleCallbackScreenState extends State<GoogleCallbackScreen> {
  bool _isLoading = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        setState(() {
          _error = 'ບໍ່ພົບຂໍ້ມູນການເຂົ້າສູ່ລະບົບ';
          _isLoading = false;
        });
        return;
      }

      final token = args['token'] as String?;
      final userData = args['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        setState(() {
          _error = 'ຂໍ້ມູນການເຂົ້າສູ່ລະບົບບໍ່ຄົບຖ້ວນ';
          _isLoading = false;
        });
        return;
      }

      // ✅ ແປງ Map ໃຫ້ເປັນ UserModel ກ່ອນ
      final user = UserModel.fromJson(userData);

      await StorageService.instance.saveToken(token);
      await StorageService.instance.saveUser(user); // ✅ ສົ່ງ UserModel ຖືກຕ້ອງ

      setState(() {
        _successMessage = 'ເຂົ້າສູ່ລະບົບສຳເລັດ!';
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    } catch (e) {
      setState(() {
        _error = 'ເກີດຂໍ້ຜິດພາດ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
        const SizedBox(height: 24),
        const Text(
          'ກຳລັງດຳເນີນການ...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _AnimatedDots(),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _successMessage ?? 'ສຳເລັດ!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'ກຳລັງນຳທ່ານໄປຫນ້າຫຼັກ...',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ເຂົ້າສູ່ລະບົບລົ້ມເຫລວ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error ?? 'ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('ກັບໄປຫນ້າ Login'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? _buildWaiting()
                : _error != null
                ? _buildError()
                : _buildSuccess(),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        return Text(
          '.' * _dotsAnimation.value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      },
    );
  }
}
