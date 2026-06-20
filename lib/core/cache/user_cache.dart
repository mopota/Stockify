import 'package:shared_preferences/shared_preferences.dart';

class UserCache {
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _avatarKey = 'user_avatar';
  static const _coverKey = 'user_cover';

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, data['name'] ?? '');
    await prefs.setString(_emailKey, data['email'] ?? '');
    await prefs.setString(_avatarKey, data['avatar'] ?? '');
    await prefs.setString(_coverKey, data['cover'] ?? '');
  }

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'avatar': prefs.getString(_avatarKey) ?? '',
      'cover': prefs.getString(_coverKey) ?? '',
    };
  }
}
