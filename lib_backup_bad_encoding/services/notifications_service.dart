import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/object_notification.dart';
import 'api_config.dart';

class NotificationsService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('РўРѕРєРµРЅ Р°РІС‚РѕСЂРёР·Р°С†РёРё РЅРµ РЅР°Р№РґРµРЅ');
    }

    return token;
  }

  static Future<List<ObjectNotification>> getNotifications({
    bool onlyUnread = false,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/notifications${onlyUnread ? '?unread=1' : ''}',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№');
    }

    final List items = data['notifications'] ?? [];
    return items.map((item) => ObjectNotification.fromJson(item)).toList();
  }

  static Future<int> getUnreadCount() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‡С‘С‚С‡РёРєР° СѓРІРµРґРѕРјР»РµРЅРёР№');
    }

    return int.tryParse(data['unread_count'].toString()) ?? 0;
  }

  static Future<void> markAsRead(int notificationId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ');
    }
  }

  static Future<void> markAllAsRead() async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№');
    }
  }
}



