import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocab_item.dart';

class StorageService {
  static const String _vocabKey = 'vocabList';
  static const String _lastAddedDateKey = 'lastAddedDate';
  static const String _dailyCountKey = 'dailyCount';
  static const String _streakCountKey = 'streakCount';
  static const String _lastStreakDateKey = 'lastStreakDate';

  Future<List<VocabItem>> loadVocabList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedVocab = prefs.getString(_vocabKey);
    if (storedVocab != null) {
      final List<dynamic> decoded = jsonDecode(storedVocab);
      return decoded.map((e) => VocabItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> saveVocabList(List<VocabItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_vocabKey, jsonStr);
  }

  Future<Map<String, dynamic>> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _lastAddedDateKey: prefs.getString(_lastAddedDateKey),
      _dailyCountKey: prefs.getString(_dailyCountKey),
      _streakCountKey: prefs.getString(_streakCountKey),
      _lastStreakDateKey: prefs.getString(_lastStreakDateKey),
    };
  }

  Future<void> saveStats({
    required String lastAddedDate,
    required int dailyCount,
    required int streakCount,
    required String lastStreakDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAddedDateKey, lastAddedDate);
    await prefs.setString(_dailyCountKey, dailyCount.toString());
    await prefs.setString(_streakCountKey, streakCount.toString());
    await prefs.setString(_lastStreakDateKey, lastStreakDate);
  }
}
