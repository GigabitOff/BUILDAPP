import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_config.dart';
import 'license_exception.dart';

class UsersService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<AppUser>> getUsers() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/users'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка отримання користувачів');
    }

    final List list = data['users'] ?? [];

    return list.map((item) => AppUser.fromJson(item)).toList();
  }

  static Future<AppUser> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String usertype,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/users'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'usertype': usertype,
      }),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка створення користувача');
    }

    return AppUser.fromJson(data['user']);
  }

  static Future<void> deleteUser(int userId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      if (isLicenseErrorCode(data['code']?.toString())) {
        throwLicenseIfNeeded(data);
      }
      throw Exception(data['message'] ?? 'Помилка видалення користувача');
    }
  }
}




