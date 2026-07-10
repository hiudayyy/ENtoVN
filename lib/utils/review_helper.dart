import 'package:flutter/material.dart';
import '../main.dart';
import '../main.dart'; // vocabProvider
import '../screens/explore_widgets/story_review_modal.dart';
import '../screens/explore_widgets/flashcard_review_modal.dart';
import '../services/ai_service.dart';

class ReviewHelper {
  /// Bắt đầu phiên ôn tập qua truyện
  static Future<void> startStoryReview(BuildContext context) async {
    final vocabList = vocabProvider.vocabList;
    if (vocabList.isEmpty) return;

    final today = DateTime.now().toIso8601String().split('T').first;
    var dueWords = vocabList.where((v) => v.nextReviewDate.compareTo(today) <= 0).toList();
    
    if (dueWords.isEmpty) {
      dueWords = List.from(vocabList);
    }
    
    dueWords.shuffle();
    final wordsToReview = dueWords.take(5).map((e) => e.word).toList();
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    final story = await AIService.generateStoryFromWords(wordsToReview);
    
    if (context.mounted) {
      Navigator.pop(context); // close loading
      if (story != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryReviewModal(storyResult: story))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tạo câu chuyện, vui lòng thử lại!'))
        );
      }
    }
  }

  /// Bắt đầu phiên ôn tập qua thẻ ảnh (Flashcard)
  static void startFlashcardReview(BuildContext context) {
    final vocabList = vocabProvider.vocabList;
    if (vocabList.isEmpty) return;

    final today = DateTime.now().toIso8601String().split('T').first;
    var dueWords = vocabList.where((v) => v.nextReviewDate.compareTo(today) <= 0).toList();
    
    if (dueWords.isEmpty) {
      dueWords = List.from(vocabList); // Ôn tập lại tất cả nếu không có từ đến hạn
    }
    
    dueWords.shuffle();
    final wordsToReview = dueWords.take(15).toList(); // Cho phép ôn tập tới 15 từ qua Flashcard vì nó nhanh
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FlashcardReviewModal(wordsToReview: wordsToReview))
    );
  }
}
