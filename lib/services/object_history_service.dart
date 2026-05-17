import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/object_history_item.dart';
import 'api_config.dart';

class ObjectHistoryService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<ObjectHistoryItem>> getHistory(int objectId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/construction-objects/$objectId/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Помилка отримання історії об’єкта');
    }

    final List items = data['history'] ?? [];
    return items.map((item) => ObjectHistoryItem.fromJson(item)).toList();
  }

  static Future<ObjectHistoryItem> createHistoryItem({
    required int objectId,
    required String title,
    required String description,
    String actionType = 'manual',
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/construction-objects/$objectId/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action_type': actionType,
        'title': title,
        'description': description,
      }),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Помилка додавання запису історії');
    }

    return ObjectHistoryItem.fromJson(data['item']);
  }
}




