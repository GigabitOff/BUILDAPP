import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/construction_object.dart';
import 'api_config.dart';
import 'license_exception.dart';


class ObjectActiveTaskCommentStats {
  final int totalComments;
  final int newComments;

  const ObjectActiveTaskCommentStats({
    required this.totalComments,
    required this.newComments,
  });
}

class ObjectsService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<String> _getToken() async {
    final prefs = await _getPrefs();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Немає токена авторизації. Выйди и зайди заново.');
    }

    return token;
  }

  Future<String> _getUserType() async {
    final prefs = await _getPrefs();
    return prefs.getString('user_type') ?? '';
  }

  Future<List<ConstructionObject>> getObjects() async {
    final token = await _getToken();
    final userType = await _getUserType();

    final endpoint = userType == 'admin' ? '/api/objects' : '/api/my-objects';

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка отримання об’єктів');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    final List items = data['objects'] ?? [];

    return items.map((item) => ConstructionObject.fromJson(item)).toList();
  }

  Future<ConstructionObject> createObject(ConstructionObject object) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/objects'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(object.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка створення об’єкта');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    return ConstructionObject.fromJson(data['object']);
  }

  Future<void> deleteObject(int objectId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/objects/$objectId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка видалення об’єкта');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }
  }

  String _normalizeTaskStatus(String status) {
    final value = status.trim();

    switch (value) {
      case 'Планируется':
      case 'Планується':
        return 'Планується';

      case 'В работе':
      case 'работе':
      case 'роботі':
      case 'В роботі':
        return 'В роботі';

      case 'Контроль':
        return 'Контроль';

      case 'Проблема':
        return 'Проблема';

      case 'Завершён':
      case 'Завершена':
      case 'Завершено':
        return 'Завершено';

      default:
        return value.isEmpty ? 'Планується' : value;
    }
  }

  Future<int> getObjectActiveTasksCount(int objectId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/construction-objects/$objectId/tasks'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка отримання завдань об’єкта');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    final List items = data['data'] ?? data['tasks'] ?? [];

    return items.where((item) {
      final status = _normalizeTaskStatus('${item['status'] ?? ''}');
      return status == 'В роботі' || status == 'Планується';
    }).length;
  }

  Future<int> getObjectTasksInWorkCount(int objectId) {
    return getObjectActiveTasksCount(objectId);
  }


  Future<ObjectActiveTaskCommentStats> getObjectActiveTaskCommentStats(int objectId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/construction-objects/$objectId/tasks/comment-stats'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка отримання коментарів активних завдань');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    final stats = data['data'] ?? data['stats'] ?? data;

    return ObjectActiveTaskCommentStats(
      totalComments: _toInt(stats['total_comments'] ?? stats['totalComments']),
      newComments: _toInt(stats['new_comments'] ?? stats['newComments'] ?? stats['unread_comments']),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getExecutors() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/executors'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка отримання виконавців');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    final List items = data['users'] ?? [];

    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> assignExecutorToObject({
    required int objectId,
    required int userId,
    String roleOnObject = 'executor',
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/construction-objects/$objectId/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'user_id': userId, 'role_on_object': roleOnObject}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка призначення виконавця');
    }

    if (data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }
  }
}




