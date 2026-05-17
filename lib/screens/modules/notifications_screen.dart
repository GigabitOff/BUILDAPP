import 'package:flutter/material.dart';

import '../../models/object_notification.dart';
import '../../services/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool isLoading = true;
  bool onlyUnread = false;
  String? errorText;
  List<ObjectNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final result = await NotificationsService.getNotifications(
        onlyUnread: onlyUnread,
      );

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(ObjectNotification notification) async {
    if (notification.isRead) return;

    try {
      await NotificationsService.markAsRead(notification.id);
      await loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationsService.markAllAsRead();
      await loadNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Усі сповіщення позначені як прочитані')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    }
  }

  String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;

    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  IconData iconByType(String type) {
    switch (type) {
      case 'material_created':
      case 'material_updated':
      case 'material_deleted':
        return Icons.inventory_2_outlined;
      case 'task_created':
      case 'task_updated':
      case 'task_deleted':
      case 'task_status_changed':
        return Icons.task_alt_outlined;
      case 'photo_report_created':
      case 'photo_report_deleted':
        return Icons.photo_camera_outlined;
      case 'history_created':
        return Icons.history_outlined;
      case 'object_created':
      case 'executor_assigned':
        return Icons.circle_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Widget buildNotificationCard(ObjectNotification item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => markAsRead(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? Colors.black.withValues(alpha: 0.06)
                      : const Color(0xFF1F6FEB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconByType(item.notificationType),
                  color: item.isRead ? Colors.black45 : const Color(0xFF1F6FEB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1F6FEB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if ((item.message ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.message!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if ((item.objectName ?? '').isNotEmpty)
                          _Badge(text: item.objectName!),
                        if ((item.actorName ?? '').isNotEmpty)
                          _Badge(text: 'Автор: ${item.actorName!}'),
                        if (item.createdAt != null)
                          _Badge(text: formatDate(item.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorText!, textAlign: TextAlign.center),
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.black38),
            SizedBox(height: 18),
            Center(
              child: Text(
                'Сповіщень поки немає',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Коли по об’єктах будуть зміни, вони з’являться тут.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: notifications.map(buildNotificationCard).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Сповіщення',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: onlyUnread ? 'Показати всі' : 'Тільки непрочитані',
            onPressed: () {
              setState(() {
                onlyUnread = !onlyUnread;
              });
              loadNotifications();
            },
            icon: Icon(onlyUnread ? Icons.mark_email_unread : Icons.filter_alt_outlined),
          ),
          IconButton(
            tooltip: 'Позначити всі як прочитані',
            onPressed: notifications.any((item) => !item.isRead) ? markAllAsRead : null,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Обновить',
            onPressed: loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}




