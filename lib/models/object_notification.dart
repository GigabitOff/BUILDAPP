class ObjectNotification {
  final int id;
  final int constructionObjectId;
  final String? objectName;
  final int userId;
  final int? actorUserId;
  final String? actorName;
  final String title;
  final String? message;
  final String notificationType;
  final bool isRead;
  final String? createdAt;
  final String? readAt;

  ObjectNotification({
    required this.id,
    required this.constructionObjectId,
    this.objectName,
    required this.userId,
    this.actorUserId,
    this.actorName,
    required this.title,
    this.message,
    required this.notificationType,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  factory ObjectNotification.fromJson(Map<String, dynamic> json) {
    return ObjectNotification(
      id: json['id'] ?? 0,
      constructionObjectId: json['construction_object_id'] ?? 0,
      objectName: json['object_name'],
      userId: json['user_id'] ?? 0,
      actorUserId: json['actor_user_id'],
      actorName: json['actor_name'],
      title: json['title'] ?? '',
      message: json['message'],
      notificationType: json['notification_type'] ?? 'object_change',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
      readAt: json['read_at'],
    );
  }
}




