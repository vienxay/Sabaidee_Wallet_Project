import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await NotificationService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _items = result.items;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    setState(() {
      _items = _items.map((n) => NotificationModel(
        id:            n.id,
        title:         n.title,
        body:          n.body,
        type:          n.type,
        read:          true,
        transactionId: n.transactionId,
        createdAt:     n.createdAt,
      )).toList();
    });
  }

  Future<void> _markRead(int index) async {
    final n = _items[index];
    if (n.read) return;
    await NotificationService.instance.markOneRead(n.id);
    setState(() {
      _items[index] = NotificationModel(
        id:            n.id,
        title:         n.title,
        body:          n.body,
        type:          n.type,
        read:          true,
        transactionId: n.transactionId,
        createdAt:     n.createdAt,
      );
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'topup':   return Icons.arrow_downward_rounded;
      case 'pay':     return Icons.bolt_rounded;
      case 'laoQR':  return Icons.qr_code_rounded;
      case 'withdraw': return Icons.arrow_upward_rounded;
      case 'kyc':    return Icons.verified_user_rounded;
      default:       return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'topup':    return Colors.green;
      case 'pay':      return Colors.orange;
      case 'laoQR':   return Colors.blue;
      case 'withdraw': return Colors.red;
      case 'kyc':     return Colors.purple;
      default:        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'ຫາກໍ່ນີ້';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີກ່ອນ';
    if (diff.inHours < 24)   return '${diff.inHours} ຊົ່ວໂມງກ່ອນ';
    if (diff.inDays < 7)     return '${diff.inDays} ວັນກ່ອນ';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.read);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ການແຈ້ງເຕືອນ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('ອ່ານທັງໝົດ', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('ບໍ່ມີການແຈ້ງເຕືອນ', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      return InkWell(
                        onTap: () => _markRead(i),
                        child: Container(
                          color: n.read ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _colorFor(n.type).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: TextStyle(
                                              fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(n.createdAt),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
