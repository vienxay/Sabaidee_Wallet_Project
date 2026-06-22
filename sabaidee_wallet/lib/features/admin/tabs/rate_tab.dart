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
  final _feeCtrl       = TextEditingController();
  final _payPerTxUnverifiedCtrl  = TextEditingController();
  final _payDailyUnverifiedCtrl  = TextEditingController();
  final _payPerTxVerifiedCtrl    = TextEditingController();
  final _payDailyVerifiedCtrl    = TextEditingController();
  final _qrDailyUnverifiedCtrl   = TextEditingController();
  final _qrDailyVerifiedCtrl     = TextEditingController();
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
    _feeCtrl.dispose();
    _payPerTxUnverifiedCtrl.dispose();
    _payDailyUnverifiedCtrl.dispose();
    _payPerTxVerifiedCtrl.dispose();
    _payDailyVerifiedCtrl.dispose();
    _qrDailyUnverifiedCtrl.dispose();
    _qrDailyVerifiedCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _api.get(AppConstants.adminRate);
      if (res.success && res.data?['rate'] != null) {
        if (!mounted) return;
        setState(() {
          _currentRate = res.data!['rate'];
          _usdController.text = (_currentRate!['usdToLAKBase'] ?? _currentRate!['usdToLAK'] ?? 0).toString();
          _feeCtrl.text = (_currentRate!['laoQrFeePercent'] ?? 0).toString();
          _payPerTxUnverifiedCtrl.text = (_currentRate!['payPerTxUnverified'] ?? 500000).toString();
          _payDailyUnverifiedCtrl.text = (_currentRate!['payDailyUnverified'] ?? 1000000).toString();
          _payPerTxVerifiedCtrl.text   = (_currentRate!['payPerTxVerified'] ?? 5000000).toString();
          _payDailyVerifiedCtrl.text   = (_currentRate!['payDailyVerified'] ?? 20000000).toString();
          _qrDailyUnverifiedCtrl.text  = (_currentRate!['qrDailyUnverified'] ?? 2000000).toString();
          _qrDailyVerifiedCtrl.text    = (_currentRate!['qrDailyVerified'] ?? 100000000).toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update() async {
    final usdToLAK        = double.tryParse(_usdController.text);
    final laoQrFeePercent = double.tryParse(_feeCtrl.text) ?? 0;

    if (usdToLAK == null || usdToLAK <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ໃສ່ usdToLAK ທີ່ຖືກຕ້ອງ')));
      return;
    }
    if (laoQrFeePercent < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ຄ່າທຳນຽມຕ້ອງ >= 0')));
      return;
    }

    final res = await _api.post(AppConstants.adminUpdateRate, {
      'usdToLAK':        usdToLAK,
      'laoQrFeePercent': laoQrFeePercent,
      'payPerTxUnverified': int.tryParse(_payPerTxUnverifiedCtrl.text) ?? 500000,
      'payDailyUnverified': int.tryParse(_payDailyUnverifiedCtrl.text) ?? 1000000,
      'payPerTxVerified':   int.tryParse(_payPerTxVerifiedCtrl.text) ?? 5000000,
      'payDailyVerified':   int.tryParse(_payDailyVerifiedCtrl.text) ?? 20000000,
      'qrDailyUnverified':  int.tryParse(_qrDailyUnverifiedCtrl.text) ?? 2000000,
      'qrDailyVerified':    int.tryParse(_qrDailyVerifiedCtrl.text) ?? 100000000,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? '✅ ອັບເດດ Rate ສຳເລັດ (ຄ່າທຳນຽມ $laoQrFeePercent%)'
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
                    _rateCard('BTC → USD', _currentRate!['btcToUSD'], isUSD: true),
                    _rateCard('BTC → LAK', _currentRate!['btcToLAK']),
                    _rateCard('USD → LAK', _currentRate!['usdToLAK']),
                    _rateCard('1 sat = LAK', null, rawDisplay: _satToLAK()),
                    _rateCard('1,000 sats', null, rawDisplay: _kSats()),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Base Rate (USD → LAK)',
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

                  const Text(
                    'ຄ່າທຳນຽມ % (ໂອນ/ຈ່າຍ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ຫັກຈາກທຸກການໂອນ/ຈ່າຍ — ກຳໄລຂອງແອັບ (Topup ບໍ່ຄິດ)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'ຄ່າທຳນຽມ %',
                      hintText: '0 = ບໍ່ມີຄ່າທຳນຽມ',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 8),
                  const Text(
                    'ວົງເງິນ Lightning (LAK)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ກຳນົດວົງເງິນສຳລັບການຈ່າຍ Lightning Invoice',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _limitField(_payPerTxUnverifiedCtrl, 'ຕໍ່ຄັ້ງ (ບໍ່ KYC)'),
                  _limitField(_payDailyUnverifiedCtrl, 'ຕໍ່ມື້ (ບໍ່ KYC)'),
                  _limitField(_payPerTxVerifiedCtrl,   'ຕໍ່ຄັ້ງ (KYC ແລ້ວ)'),
                  _limitField(_payDailyVerifiedCtrl,   'ຕໍ່ມື້ (KYC ແລ້ວ)'),
                  const SizedBox(height: 16),
                  const Text(
                    'ວົງເງິນ LAO QR (LAK)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ກຳນົດວົງເງິນສຳລັບການຈ່າຍ LAO QR ຕໍ່ມື້',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _limitField(_qrDailyUnverifiedCtrl, 'ຕໍ່ມື້ (ບໍ່ KYC)'),
                  _limitField(_qrDailyVerifiedCtrl,   'ຕໍ່ມື້ (KYC ແລ້ວ)'),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _update,
                      child: const Text(
                        'ອັບເດດ Rate & Limits',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _limitField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: 'ກີບ',
          isDense: true,
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
