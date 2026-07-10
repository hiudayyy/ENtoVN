import 'package:flutter/material.dart';
import '../models/vocab_item.dart';
import '../services/storage_service.dart';

class VocabProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<VocabItem> _vocabList = [];
  int _dailyCount = 0;
  int _streakCount = 0;
  String _lastStreakDate = '';

  List<VocabItem> get vocabList => _vocabList;
  int get dailyCount => _dailyCount;
  int get streakCount => _streakCount;
  String get lastStreakDate => _lastStreakDate;
  int get dailyGoal => 5;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  VocabProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _vocabList = await _storageService.loadVocabList();
    final stats = await _storageService.loadStats();

    final today = DateTime.now().toIso8601String().split('T').first;
    final storedDate = stats['lastAddedDate'];
    final storedCount = stats['dailyCount'];

    if (storedDate == today && storedCount != null) {
      _dailyCount = int.tryParse(storedCount) ?? 0;
    } else {
      _dailyCount = 0;
    }

    _streakCount = int.tryParse(stats['streakCount'] ?? '0') ?? 0;
    _lastStreakDate = stats['lastStreakDate'] ?? '';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    await _storageService.saveVocabList(_vocabList);
    final today = DateTime.now().toIso8601String().split('T').first;
    await _storageService.saveStats(
      lastAddedDate: today,
      dailyCount: _dailyCount,
      streakCount: _streakCount,
      lastStreakDate: _lastStreakDate,
    );
  }

  Future<void> updateStreak() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T').first;

    if (_lastStreakDate != today) {
      if (_lastStreakDate == yesterday) {
        _streakCount++;
      } else {
        _streakCount = 1;
      }
      _lastStreakDate = today;
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> addWord(VocabItem newItem) async {
    // Check duplicate
    if (_vocabList.any((item) => item.word.toLowerCase() == newItem.word.toLowerCase())) {
      throw Exception('Duplicate word');
    }

    _vocabList.add(newItem);
    updateStreak();
    _dailyCount++;

    notifyListeners();
    await _saveData();
  }

  Future<void> addMultipleWords(List<VocabItem> items) async {
    bool hasChanges = false;
    int addedCount = 0;
    for (var item in items) {
      if (!_vocabList.any((v) => v.word.toLowerCase() == item.word.toLowerCase())) {
        _vocabList.add(item);
        hasChanges = true;
        addedCount++;
      }
    }
    if (hasChanges) {
      updateStreak();
      _dailyCount += addedCount;
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> updateWord(VocabItem updatedItem) async {
    final idx = _vocabList.indexWhere((v) => v.word == updatedItem.word);
    if (idx != -1) {
      _vocabList[idx] = updatedItem;
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> markWordsAsReviewed(List<String> words, {required bool isCorrect}) async {
    bool hasChanges = false;
    for (String word in words) {
      final idx = _vocabList.indexWhere((v) => v.word.toLowerCase() == word.toLowerCase());
      if (idx != -1) {
        final item = _vocabList[idx];
        int newRep = item.repetitions;
        int newInt = item.interval;
        
        DateTime nextDate;
        if (isCorrect) {
          newRep++;
          newInt = newRep == 1 ? 1 : newRep == 2 ? 3 : newRep == 3 ? 7 : (newInt * 2.5).round();
          nextDate = DateTime.now().add(Duration(days: newInt));
        } else {
          newRep = 0;
          newInt = 1;
          nextDate = DateTime.now(); // Giữ nguyên ngày hôm nay để ôn lại
        }
        
        final updatedItem = VocabItem(
          word: item.word,
          meaning: item.meaning,
          partOfSpeech: item.partOfSpeech,
          example: item.example,
          dateAdded: item.dateAdded,
          repetitions: newRep,
          interval: newInt,
          nextReviewDate: nextDate.toIso8601String().split('T').first,
        );
        _vocabList[idx] = updatedItem;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      if (isCorrect) {
        updateStreak();
      }
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> deleteWord(String word) async {
    _vocabList.removeWhere((item) => item.word == word);
    notifyListeners();
    await _saveData();
  }
}
