import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/object_material.dart';
import 'api_config.dart';

class MaterialsService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> getMaterials(int objectId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/construction-objects/$objectId/materials'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»РѕРІ');
    }

    final List materialsJson = data['materials'] ?? [];

    return {
      'materials': materialsJson
          .map((item) => ObjectMaterial.fromJson(item))
          .toList(),
      'can_edit': data['can_edit'] == true,
    };
  }

  static Future<ObjectMaterial> createMaterial({
    required int objectId,
    required String name,
    String? unit,
    required double quantity,
    required double price,
    String? comment,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/construction-objects/$objectId/materials'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°');
    }

    return ObjectMaterial.fromJson(data['material']);
  }

  static Future<ObjectMaterial> updateMaterial({
    required int objectId,
    required int materialId,
    required String name,
    String? unit,
    required double quantity,
    required double price,
    String? comment,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse(
        '$baseUrl/construction-objects/$objectId/materials/$materialId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°');
    }

    return ObjectMaterial.fromJson(data['material']);
  }

  static Future<void> deleteMaterial({
    required int objectId,
    required int materialId,
  }) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse(
        '$baseUrl/construction-objects/$objectId/materials/$materialId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°');
    }
  }
}



