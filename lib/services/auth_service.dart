import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'push_notifications_service.dart';
import 'license_exception.dart';

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
      await _saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'Помилка авторизації');
  }

  Future<Map<String, dynamic>> register({
    required String licenseKey,
    required String organization,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'license_key': licenseKey.trim(),
        'organization': organization,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      await _saveAuthData(data, phone: phone);
      return data;
    }

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка реєстрації');
  }

  Future<Map<String, dynamic>> startPhoneLogin({required String phone}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/phone/start');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка надсилання PIN-коду');
  }

  Future<Map<String, dynamic>> verifyPhoneCode({
    required String phone,
    required String code,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/phone/verify');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await _saveAuthData(data, phone: phone);
      return data;
    }

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка перевірки PIN-коду');
  }

  Future<Map<String, dynamic>> me() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Токен не знайдено');
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

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка перевірки користувача');
  }


  Future<Map<String, dynamic>> checkLicenseKey({required String licenseKey}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/license/check');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'license_key': licenseKey.trim()}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка перевірки ліцензії');
  }

  Future<void> logout() async {
    await PushNotificationsService.unregisterCurrentDevice();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('auth_phone');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_type');
  }

  Future<void> _saveAuthData(Map<String, dynamic> data, {String? phone}) async {
    final prefs = await SharedPreferences.getInstance();

    final user = data['user'] ?? {};

    await prefs.setString('auth_token', data['token']?.toString() ?? '');

    final savedPhone = phone ?? user['phone']?.toString() ?? '';
    if (savedPhone.isNotEmpty) {
      await prefs.setString('auth_phone', savedPhone);
    }

    await prefs.setInt(
      'user_id',
      int.tryParse(user['id']?.toString() ?? '0') ?? 0,
    );

    await prefs.setString('user_name', user['name']?.toString() ?? '');
    await prefs.setString('user_email', user['email']?.toString() ?? '');
    await prefs.setString('user_type', user['usertype']?.toString() ?? '');

    await PushNotificationsService.registerCurrentDevice();
  }
}




