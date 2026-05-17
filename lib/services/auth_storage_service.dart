import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _keyPhone = 'auth_phone';
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';

  static Future<void> saveAuthData({
    required String phone,
    required String token,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, int.tryParse(userId) ?? 0);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<bool> hasPhone() async {
    final phone = await getPhone();
    return phone != null && phone.trim().isNotEmpty;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_type');
  }
}
