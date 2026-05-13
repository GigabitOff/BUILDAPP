import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class InvitesService {
  static Future<Map<String, dynamic>> createProjectInvite({
    required int objectId,
    String roleOnObject = 'executor',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Нет токена авторизации'};
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/construction-objects/$objectId/invite',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role_on_object': roleOnObject}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getInviteInfo(String inviteToken) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/invites/$inviteToken'),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> acceptInvite(String inviteToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Нет токена авторизации'};
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/invites/$inviteToken/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
