import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local JSON-based data store using SharedPreferences
class DataStore {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<Map<String, dynamic>> getList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.cast<Map<String, dynamic>>();
    } catch {
      return [];
    }
  }

  static Future<void> setList(String key, List<Map<String, dynamic>> data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  static Map<String, dynamic>? getMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch {
      return null;
    }
  }

  static Future<void> setMap(String key, Map<String, dynamic> data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  static String genId() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (DateTime.now().microsecond * 1234567).toRadixString(36);
    return '$now$rand';
  }

  static String todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }
}
