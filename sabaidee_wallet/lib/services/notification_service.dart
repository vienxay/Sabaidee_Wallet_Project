import '../core/core.dart';
import '../models/app_models.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  Future<({List<NotificationModel> items, int unreadCount})> getNotifications() async {
    final res = await _api.get(AppConstants.notifications);
    if (res.success && res.data != null) {
      final list = (res.data!['notifications'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final unread = (res.data!['unreadCount'] as num?)?.toInt() ?? 0;
      return (items: list, unreadCount: unread);
    }
    return (items: <NotificationModel>[], unreadCount: 0);
  }

  Future<void> markAllRead() async {
    await _api.put(AppConstants.notificationsReadAll, {});
  }

  Future<void> markOneRead(String id) async {
    await _api.put('${AppConstants.notifications}/$id/read', {});
  }
}
