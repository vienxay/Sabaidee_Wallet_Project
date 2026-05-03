import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChangeRole;

  const UserCard({super.key, required this.user, required this.onChangeRole});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange[100]!;
      case 'staff':
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = user['role'] ?? 'user';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Text(
            (user['name'] ?? '?')[0].toUpperCase(),
            style: const TextStyle(color: Colors.orange),
          ),
        ),
        title: Text(user['name'] ?? ''),
        subtitle: Text(user['email'] ?? ''),
        trailing: GestureDetector(
          onTap: onChangeRole,
          child: Chip(label: Text(role), backgroundColor: _roleColor(role)),
        ),
      ),
    );
  }
}
