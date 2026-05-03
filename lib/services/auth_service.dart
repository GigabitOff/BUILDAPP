import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', data['token']);
      await prefs.setString('user_name', data['user']['name'] ?? '');
      await prefs.setString('user_email', data['user']['email'] ?? '');
      await prefs.setString('user_type', data['user']['usertype'] ?? '');

      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка авторизации');
  }

  Future<Map<String, dynamic>> me() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Токен не найден');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/me');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message'] ?? 'Ошибка проверки пользователя');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_type');
  }
}
