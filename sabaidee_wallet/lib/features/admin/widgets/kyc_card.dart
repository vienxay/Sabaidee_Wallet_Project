import 'package:flutter/material.dart';
import '../screens/kyc_detail_screen.dart'; // ✅ ເພີ່ມ

class KycCard extends StatelessWidget {
  final Map<String, dynamic> kyc;
  final String status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onUpdated; // ✅ ເພີ່ມ

  const KycCard({
    super.key,
    required this.kyc,
    required this.status,
    this.onApprove,
    this.onReject,
    this.onUpdated, // ✅ ເພີ່ມ
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ ເພີ່ມ — ກົດ card ໄປ detail
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              KycDetailScreen(kyc: kyc, onUpdated: onUpdated ?? () {}),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: kyc['profileImage'] != null
                ? NetworkImage(kyc['profileImage'])
                : null,
            child: kyc['profileImage'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(kyc['name'] ?? ''),
          subtitle: Text(kyc['email'] ?? ''),
          trailing: status == 'pending'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'ອະນຸມັດ',
                      onPressed: onApprove,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'ປະຕິເສດ',
                      onPressed: onReject,
                    ),
                  ],
                )
              : Chip(
                  label: Text(status),
                  backgroundColor: status == 'verified'
                      ? Colors.green[100]
                      : Colors.red[100],
                ),
        ),
      ),
    );
  }
}
