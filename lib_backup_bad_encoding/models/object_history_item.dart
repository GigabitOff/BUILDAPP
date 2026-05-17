class ObjectHistoryItem {
  final int id;
  final int constructionObjectId;
  final int? userId;
  final String? userName;
  final String actionType;
  final String title;
  final String? description;
  final String? createdAt;

  const ObjectHistoryItem({
    required this.id,
    required this.constructionObjectId,
    this.userId,
    this.userName,
    required this.actionType,
    required this.title,
    this.description,
    this.createdAt,
  });

  factory ObjectHistoryItem.fromJson(Map<String, dynamic> json) {
    return ObjectHistoryItem(
      id: json['id'] ?? 0,
      constructionObjectId: json['construction_object_id'] ?? 0,
      userId: json['user_id'],
      userName: json['user_name'],
      actionType: json['action_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}



