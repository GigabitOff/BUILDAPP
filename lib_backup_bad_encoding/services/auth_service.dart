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
      await _saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'РћС€РёР±РєР° Р°РІС‚РѕСЂРёР·Р°С†РёРё');
  }

  Future<Map<String, dynamic>> register({
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
      await _saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'РћС€РёР±РєР° СЂРµРіРёСЃС‚СЂР°С†РёРё');
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

    throw Exception(data['message'] ?? 'РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё PIN-РєРѕРґР°');
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
      await _saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё PIN-РєРѕРґР°');
  }

  Future<Map<String, dynamic>> me() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('РўРѕРєРµРЅ РЅРµ РЅР°Р№РґРµРЅ');
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

    throw Exception(data['message'] ?? 'РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_type');
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final user = data['user'] ?? {};

    await prefs.setString('auth_token', data['token']?.toString() ?? '');

    await prefs.setInt(
      'user_id',
      int.tryParse(user['id']?.toString() ?? '0') ?? 0,
    );

    await prefs.setString('user_name', user['name']?.toString() ?? '');
    await prefs.setString('user_email', user['email']?.toString() ?? '');
    await prefs.setString('user_type', user['usertype']?.toString() ?? '');
  }
}



