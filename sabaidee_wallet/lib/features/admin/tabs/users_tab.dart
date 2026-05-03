import 'package:flutter/material.dart';
import '../../../../services/api_client.dart';
import '../../../../core/app_constants.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _api = ApiClient.instance;
  List _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(AppConstants.adminUsers);
      if (res.success) {
        setState(() => _users = res.data?['data'] ?? []);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(String userId, String currentRole) async {
    final roles = ['user', 'staff', 'admin'];
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('ປ່ຽນ Role'),
        children: roles
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, r),
                child: Row(
                  children: [
                    Icon(
                      r == currentRole ? Icons.check : Icons.circle_outlined,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(r),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || selected == currentRole) return;

    final res = await _api.post(AppConstants.adminUpdateRole, {
      'userId': userId,
      'role': selected,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'ປ່ຽນ Role ສຳເລັດ' : res.message),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
    if (res.success) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetch,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: Text(
                        (u['name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                    title: Text(u['name'] ?? ''),
                    subtitle: Text(u['email'] ?? ''),
                    trailing: GestureDetector(
                      onTap: () => _changeRole(u['_id'], u['role'] ?? 'user'),
                      child: Chip(
                        label: Text(u['role'] ?? 'user'),
                        backgroundColor: u['role'] == 'admin'
                            ? Colors.orange[100]
                            : u['role'] == 'staff'
                            ? Colors.blue[100]
                            : Colors.grey[200],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
