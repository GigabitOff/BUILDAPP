import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'license_exception.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Токен не знайдено');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/dashboard/counts');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['counts'];
    }

    if (isLicenseErrorCode(data['code']?.toString())) {
      throwLicenseIfNeeded(data);
    }

    throw Exception(data['message'] ?? 'Помилка отримання лічильників');
  }
}



