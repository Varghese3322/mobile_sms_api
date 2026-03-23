import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _userIdKey = "user_id";
  static const String _deviceRegisteredKey = "device_registered";

  // Save user id
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Get user id
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Save device register status
  static Future<void> setDeviceRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceRegisteredKey, value);
  }

  // Get device register status
  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deviceRegisteredKey) ?? false;
  }

  // Clear on logout/unregister
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
