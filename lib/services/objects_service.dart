import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/construction_object.dart';

class ObjectsService {
  static const String baseUrl = 'http://185.112.41.227:3036';

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<String> _getToken() async {
    final prefs = await _getPrefs();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Нет токена авторизации. Выйди и зайди заново.');
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
      throw Exception(data['message'] ?? 'Ошибка получения объектов');
    }

    if (data['success'] != true) {
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
      throw Exception(data['message'] ?? 'Ошибка создания объекта');
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }

    return ConstructionObject.fromJson(data['object']);
  }

  Future<List<Map<String, dynamic>>> getExecutors() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/executors'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Ошибка получения исполнителей');
    }

    if (data['success'] != true) {
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
      throw Exception(data['message'] ?? 'Ошибка назначения исполнителя');
    }

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Сервер вернул ошибку');
    }
  }
}
