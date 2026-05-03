import 'package:flutter/material.dart';
import '../../../services/api_client.dart';
import '../../../core/app_constants.dart';

class KycDetailScreen extends StatelessWidget {
  final Map<String, dynamic> kyc;
  final VoidCallback onUpdated;

  const KycDetailScreen({
    super.key,
    required this.kyc,
    required this.onUpdated,
  });

  Future<void> _review(BuildContext context, String status) async {
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

    final res = await ApiClient.instance.post(AppConstants.adminKycReview, {
      'userId': kyc['_id'],
      'status': status,
      'note': noteController.text,
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'ສຳເລັດ' : res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    if (res.success) {
      onUpdated();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = kyc['images'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ກວດສອບ KYC'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ຂໍ້ມູນສ່ວນຕົວ ──────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ຂໍ້ມູນສ່ວນຕົວ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _infoRow('ຊື່', kyc['name'] ?? '-'),
                    _infoRow('Email', kyc['email'] ?? '-'),
                    _infoRow('ເພດ', kyc['gender'] ?? '-'),
                    _infoRow('ວັນເດືອນປີເກີດ', kyc['dob'] ?? '-'),
                    _infoRow('ສັນຊາດ', kyc['nationality'] ?? '-'),
                    _infoRow('Passport No.', kyc['passportNo'] ?? '-'),
                    _infoRow('ວັນໝົດອາຍຸ', kyc['expiry'] ?? '-'),
                    _infoRow('REF ID', kyc['refId'] ?? '-'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── ຮູບພາບ ──────────────────────────────────────
            if (images.isNotEmpty) ...[
              const Text(
                'ຮູບພາບ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[i].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Buttons ──────────────────────────────────────
            if (kyc['kycStatus'] == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text(
                        'ອະນຸມັດ',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () => _review(context, 'verified'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        'ປະຕິເສດ',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () => _review(context, 'rejected'),
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kyc['kycStatus'] == 'verified'
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kyc['kycStatus'] == 'verified'
                      ? '✅ ອະນຸມັດແລ້ວ'
                      : '❌ ປະຕິເສດແລ້ວ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kyc['kycStatus'] == 'verified'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
