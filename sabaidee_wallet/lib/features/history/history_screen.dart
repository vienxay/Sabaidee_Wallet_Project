import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../models/app_models.dart';
import '../../services/transaction_service.dart';
import '../payment/payment_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<TransactionModel> _txList = [];
  String? _error;
  String? _filter;

  static const _months = [
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ', 'ພຶດສະພາ', 'ມິຖຸນາ',
    'ກໍລະກົດ', 'ສິງຫາ', 'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await TransactionService.instance.getTransactions(
      type: _filter,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) { _txList = res.data ?? []; }
      else { _error = res.message; }
    });
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String _dateHeader(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  // Returns a flat list alternating between String (date header) and TransactionModel
  List<dynamic> _grouped() {
    final result = <dynamic>[];
    String? lastKey;
    for (final tx in _txList) {
      final key = '${tx.createdAt.year}-${tx.createdAt.month}-${tx.createdAt.day}';
      if (key != lastKey) {
        result.add(tx.createdAt);
        lastKey = key;
      }
      result.add(tx);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: AppColors.textDark),
        ),
        title: const Text(
          'ປະຫວັດທຸລະກຳ',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Filter Chips ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                for (final f in [null, 'topup', 'withdraw', 'pay'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () { setState(() => _filter = f); _load(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _filter == f ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _filter == f ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          f == null ? 'ທັງໝົດ'
                              : f == 'topup' ? 'TopUp'
                              : f == 'withdraw' ? 'ຖອນ'
                              : 'ຈ່າຍ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _filter == f ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── List ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('ລອງໃໝ່', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _txList.isEmpty
                ? const Center(
                    child: Text('ຍັງບໍ່ມີລາຍການ', style: TextStyle(color: AppColors.textGrey)),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: _buildGroupedList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final items = _grouped();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        // ── Date header ──────────────────────────────────────────────────
        if (item is DateTime) {
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 4 : 20, bottom: 10),
            child: Row(
              children: [
                Text(
                  _dateHeader(item),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Divider(color: AppColors.divider, thickness: 1),
                ),
              ],
            ),
          );
        }

        // ── Transaction card ─────────────────────────────────────────────
        final tx = item as TransactionModel;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TxCard(
            tx: tx,
            fmt: _fmt,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentDetailScreen(tx: tx)),
            ),
          ),
        );
      },
    );
  }
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final String Function(int) fmt;
  final VoidCallback onTap;

  const _TxCard({required this.tx, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tx.isPending
                    ? Colors.grey.shade100
                    : tx.isFailed
                        ? Colors.grey.shade100
                        : tx.isReceive
                            ? AppColors.successLight
                            : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tx.isPending ? Icons.access_time_rounded : Icons.bolt,
                color: tx.isPending
                    ? Colors.grey
                    : tx.isFailed
                        ? Colors.grey
                        : tx.isReceive
                            ? AppColors.success
                            : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.memo.isNotEmpty ? tx.memo : tx.type,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')} ໂມງ',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tx.isFailed
                      ? 'ລົ້ມເຫລວ'
                      : '${tx.isReceive ? '+' : '-'}${fmt(tx.amountSats)} sats',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tx.isFailed
                        ? Colors.grey
                        : tx.isPending
                            ? Colors.orange.shade300
                            : tx.isReceive
                                ? AppColors.success
                                : AppColors.error,
                  ),
                ),
                if (tx.isPending)
                  const Text('ລໍຖ້າ', style: TextStyle(fontSize: 10, color: Colors.orange))
                else if (!tx.isFailed)
                  Text(
                    '${fmt(tx.amountLAK)} LAK',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
