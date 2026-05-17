import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class TaskComment {
  final int id;
  final int taskId;
  final int userId;
  final String userName;
  final String comment;
  final String createdAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      taskId: int.tryParse('${json['task_id'] ?? json['object_task_id'] ?? 0}') ?? 0,
      userId: int.tryParse('${json['user_id'] ?? json['created_by'] ?? 0}') ?? 0,
      userName: '${json['user_name'] ?? json['author_name'] ?? json['created_by_name'] ?? ''}',
      comment: '${json['comment'] ?? json['message'] ?? json['text'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class TaskCommentsService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизації не знайдено');
    }

    return token;
  }

  static Future<List<TaskComment>> getTaskComments(int taskId) async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/object-tasks/$taskId/comments'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Помилка отримання коментарів');
    }

    final dynamic rawItems = data['data'] ?? data['comments'] ?? [];
    final List items = rawItems is List ? rawItems : [];

    return items
        .map((item) => TaskComment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> addTaskComment({
    required int taskId,
    required String comment,
  }) async {
    final token = await _getToken();

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/object-tasks/$taskId/comments'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'comment': comment.trim(),
            'message': comment.trim(),
            'text': comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final Map<String, dynamic> data = jsonDecode(response.body);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Помилка додавання коментаря');
    }
  }
}
