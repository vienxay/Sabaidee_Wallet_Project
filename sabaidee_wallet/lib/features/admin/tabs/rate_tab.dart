import 'package:flutter/material.dart';
import '../../../../services/api_client.dart';
import '../../../../core/app_constants.dart';
import 'package:intl/intl.dart';

class RateTab extends StatefulWidget {
  const RateTab({super.key});

  @override
  State<RateTab> createState() => _RateTabState();
}

class _RateTabState extends State<RateTab> {
  final _api = ApiClient.instance;
  final _usdController = TextEditingController();
  final _spreadController = TextEditingController();
  final _fmt = NumberFormat('#,##0', 'en_US');
  bool _loading = false;
  Map? _currentRate;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _usdController.dispose();
    _spreadController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // ✅ ລຶບ bool success = false; ອອກ
    try {
      final res = await _api.get(AppConstants.adminRate);
      if (res.success && res.data?['rate'] != null) {
        // ✅ ລຶບ success = true; ອອກ
        if (!mounted) return;
        setState(() {
          _currentRate = res.data!['rate'];
          _usdController.text =
              (_currentRate!['usdToLAKBase'] ?? _currentRate!['usdToLAK'] ?? 0)
                  .toString();
          _spreadController.text = (_currentRate!['spreadPercent'] ?? 0)
              .toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _previewSell() {
    final base = double.tryParse(_usdController.text) ?? 0;
    final spread = double.tryParse(_spreadController.text) ?? 0;
    if (base <= 0) return '-';
    final sell = (base * (1 + spread / 100)).round();
    return '${_fmt.format(sell)} ກີບ';
  }

  Future<void> _update() async {
    final usdToLAK = double.tryParse(_usdController.text);
    final spreadPercent = double.tryParse(_spreadController.text) ?? 0;

    if (usdToLAK == null || usdToLAK <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ໃສ່ usdToLAK ທີ່ຖືກຕ້ອງ')));
      return;
    }
    if (spreadPercent < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spread % ຕ້ອງ >= 0')));
      return;
    }

    final res = await _api.post(AppConstants.adminUpdateRate, {
      'usdToLAK': usdToLAK,
      'spreadPercent': spreadPercent,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? '✅ ອັບເດດ Rate ສຳເລັດ (spread $spreadPercent%)'
              : res.message,
        ),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    if (res.success) _fetch();
  }

  String _satToLAK() {
    final btcToLAK = (_currentRate!['btcToLAK'] as num?)?.toDouble() ?? 0;
    if (btcToLAK <= 0) return '-';
    return '${(btcToLAK / 100000000).toStringAsFixed(2)} ກີບ';
  }

  String _kSats() {
    final btcToLAK = (_currentRate!['btcToLAK'] as num?)?.toDouble() ?? 0;
    if (btcToLAK <= 0) return '-';
    return '${_fmt.format((btcToLAK / 100000).round())} ກີບ';
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetch,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ອັດຕາແລກປ່ຽນປັດຈຸບັນ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: _fetch,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_currentRate != null) ...[
                    _rateCard(
                      'BTC → USD',
                      _currentRate!['btcToUSD'],
                      isUSD: true,
                    ),
                    _rateCard('BTC → LAK', _currentRate!['btcToLAK']),
                    _rateCard('USD → LAK', _currentRate!['usdToLAK']),
                    _rateCard('1 sat = LAK', null, rawDisplay: _satToLAK()),
                    _rateCard('1,000 sats', null, rawDisplay: _kSats()),
                    const SizedBox(height: 24),
                  ],

                  // ✅ Preview ລາຄາຂາຍ — ແກ້ withOpacity → withValues
                  if (_currentRate != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.06), // ✅
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3), // ✅
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ລາຄາຂາຍ (ລວມ spread)',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            _previewSell(),
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Base Rate (USD → LAK)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usdController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: '1 USD = ? LAK',
                      border: OutlineInputBorder(),
                      suffixText: 'ກີບ',
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Spread % (ກຳໄລ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _spreadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Spread %',
                      hintText: '0 = ບໍ່ມີ spread',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _update,
                      child: const Text(
                        'ອັບເດດ Rate',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _rateCard(
    String label,
    dynamic value, {
    bool isUSD = false,
    String? rawDisplay,
  }) {
    String display = '-';
    if (rawDisplay != null) {
      display = rawDisplay;
    } else if (value != null) {
      final num = double.tryParse(value.toString()) ?? 0;
      if (num > 0) {
        display = isUSD
            ? '\$${_fmt.format(num.round())}'
            : '${_fmt.format(num.round())} ກີບ';
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          display,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}
