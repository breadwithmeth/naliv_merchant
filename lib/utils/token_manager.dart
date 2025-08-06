import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';

  /// Сохранить токен в SharedPreferences
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Ошибка при сохранении токена: $e');
      return false;
    }
  }

  /// Получить токен из SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Ошибка при получении токена: $e');
      return null;
    }
  }

  /// Проверить, есть ли сохраненный токен
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Удалить токен из SharedPreferences
  static Future<bool> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokenKey);
    } catch (e) {
      print('Ошибка при удалении токена: $e');
      return false;
    }
  }

  /// Очистить все данные из SharedPreferences
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Ошибка при очистке данных: $e');
      return false;
    }
  }
}
