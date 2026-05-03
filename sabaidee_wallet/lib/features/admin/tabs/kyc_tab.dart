import 'package:flutter/material.dart';
import '../../../../services/api_client.dart';
import '../../../../core/app_constants.dart';
import '../screens/kyc_detail_screen.dart'; // ✅ ເພີ່ມ

class KycTab extends StatefulWidget {
  const KycTab({super.key});

  @override
  State<KycTab> createState() => _KycTabState();
}

class _KycTabState extends State<KycTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiClient.instance;
  List _list = [];
  bool _loading = false;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final statuses = ['pending', 'verified', 'rejected'];
      _status = statuses[_tabController.index];
      _fetch();
    });
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('${AppConstants.adminKyc}?status=$_status');
      if (res.success) {
        setState(() => _list = res.data?['kycs'] ?? []);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _review(String userId, String status) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(status == 'verified' ? '✅ ອະນຸມັດ KYC' : '❌ ປະຕິເສດ KYC'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'ໝາຍເຫດ (ຖ້າມີ)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'verified' ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ຢືນຢັນ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await _api.post(AppConstants.adminKycReview, {
      'userId': userId,
      'status': status,
      'note': noteController.text,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'ສຳເລັດ' : res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    if (res.success) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          tabs: const [
            Tab(text: 'ລໍຖ້າ'),
            Tab(text: 'ອະນຸມັດ'),
            Tab(text: 'ປະຕິເສດ'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _list.isEmpty
              ? const Center(child: Text('ບໍ່ມີຂໍ້ມູນ'))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final k = _list[i];
                      return GestureDetector(
                        // ✅ ເພີ່ມ
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KycDetailScreen(kyc: k, onUpdated: _fetch),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: k['profileImage'] != null
                                  ? NetworkImage(k['profileImage'])
                                  : null,
                              child: k['profileImage'] == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(k['name'] ?? ''),
                            subtitle: Text(k['email'] ?? ''),
                            trailing: _status == 'pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _review(k['_id'], 'verified'),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _review(k['_id'], 'rejected'),
                                      ),
                                    ],
                                  )
                                : Chip(
                                    label: Text(_status),
                                    backgroundColor: _status == 'verified'
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
