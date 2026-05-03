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
  final _usdController = TextEditingController(); // ✅ ປ່ຽນຊື່
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
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return; // ✅ ເພີ່ມ
    setState(() => _loading = true);
    try {
      final res = await _api.get(AppConstants.adminRate);
      if (res.success && res.data?['rate'] != null) {
        if (!mounted) return; // ✅ ເພີ່ມ
        setState(() {
          _currentRate = res.data!['rate'];
          _usdController.text = (_currentRate!['usdToLAK'] ?? 0).toString();
        });
      }
    } finally {
      if (!mounted) return; // ✅ ເພີ່ມ
      setState(() => _loading = false);
    }
  }

  Future<void> _update() async {
    final val = double.tryParse(_usdController.text);
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ໃສ່ຕົວເລກທີ່ຖືກຕ້ອງ')));
      return;
    }

    final res = await _api.post(
      AppConstants.adminUpdateRate,
      {'usdToLAK': val}, // ✅ ສົ່ງ usdToLAK
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? '✅ ອັບເດດ Rate ສຳເລັດ' : res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    if (res.success) _fetch();
  }

  String _satToLAK() {
    debugPrint(
      'btcToLAK raw: ${_currentRate!['btcToLAK']} type: ${_currentRate!['btcToLAK'].runtimeType}',
    );
    final btcToLAK = (_currentRate!['btcToLAK'] as num?)?.toDouble() ?? 0;
    debugPrint('btcToLAK double: $btcToLAK');
    if (btcToLAK <= 0) return '-';
    final sat = btcToLAK / 100000000;
    return '${sat.toStringAsFixed(2)} ກີບ';
  }

  String _kSats() {
    // ✅ ຮອງຮັບທັງ int ແລະ double
    final btcToLAK = (_currentRate!['btcToLAK'] as num?)?.toDouble() ?? 0;
    if (btcToLAK <= 0) return '-';
    final kSats = btcToLAK / 100000;
    return '${_fmt.format(kSats.round())} ກີບ';
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
                    // ✅ ຖືກ — ສົ່ງໄປ rawDisplay
                    _rateCard('1 sat = LAK', null, rawDisplay: _satToLAK()),
                    _rateCard('1,000 sats', null, rawDisplay: _kSats()),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'ແກ້ໄຂ USD → LAK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '1 USD = ? LAK',
                      border: OutlineInputBorder(),
                      suffixText: 'ກີບ',
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

  // ✅ ເພີ່ມ parameter rawDisplay
  Widget _rateCard(
    String label,
    dynamic value, {
    bool isUSD = false,
    String? rawDisplay,
  }) {
    String display = '-';

    if (rawDisplay != null) {
      display = rawDisplay; // ✅ ໃຊ້ string ໂດຍກົງ
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
