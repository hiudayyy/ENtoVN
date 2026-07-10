import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../main.dart'; // for vocabProvider
import '../../models/vocab_item.dart';
import '../../utils/string_utils.dart';
import '../../utils/review_helper.dart';

class ReviewCard extends StatefulWidget {
  const ReviewCard({super.key});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> with SingleTickerProviderStateMixin {
  List<VocabItem> reviewWords = [];
  List<bool> showWordSides = [];
  bool isReviewing = false;
  int currentReviewIndex = 0;
  int correctCount = 0;
  String userAnswer = '';
  String feedback = '';
  bool showAnswer = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
  }

  Future<void> _speakWord(String word) async {
    await flutterTts.speak(word);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _showAlert(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(title), content: Text(content),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  void _startReview() {
    final today = DateTime.now().toIso8601String().split('T').first;
    final dueWords = vocabProvider.vocabList.where((i) => i.nextReviewDate.compareTo(today) <= 0).toList();
    if (dueWords.isEmpty) { 
      _showAlert('Tuyệt vời! 🎉', 'Bạn đã hoàn thành toàn bộ bài ôn tập cho hôm nay.'); 
      return; 
    }
    dueWords.shuffle();
    setState(() {
      reviewWords = dueWords.take(5).toList();
      showWordSides = List.generate(reviewWords.length, (_) => Random().nextBool());
      isReviewing = true;
      currentReviewIndex = 0;
      correctCount = 0;
      userAnswer = '';
      showAnswer = false;
    });
    _flipController.reset();
  }

  Future<void> _startStoryReview() async {
    await ReviewHelper.startStoryReview(context);
  }

  void _startFlashcardReview() {
    ReviewHelper.startFlashcardReview(context);
  }

  Future<void> _submitAnswer(String answer) async {
    final item = reviewWords[currentReviewIndex];
    final expected = showWordSides[currentReviewIndex] ? item.meaning : item.word;
    final normalized = answer.trim().toLowerCase();
    final validAnswers = expected.split(RegExp(r'[,;]')).map((e) => e.trim().toLowerCase()).toList();
    final isExactMatch = validAnswers.contains(normalized);

    if (!isExactMatch) {
      final minDist = validAnswers.map((a) => StringUtils.getLevenshteinDistance(normalized, a)).reduce(min);
      if (minDist <= 2 && normalized.length > 3) {
        _showAlert('🤔 Gần đúng rồi!', 'Bạn đang gõ sai $minDist chữ cái. Hãy kiểm tra lại.');
        return;
      }
    }

    int newRep = item.repetitions;
    int newInt = item.interval;
    
    setState(() {
      if (isExactMatch) {
        correctCount++; newRep++;
        newInt = newRep == 1 ? 1 : newRep == 2 ? 3 : newRep == 3 ? 7 : (newInt * 2.5).round();
        feedback = 'Đúng! 🎉\nÔn lại sau $newInt ngày';
        vocabProvider.updateStreak();
      } else {
        newRep = 0; newInt = 1;
        feedback = 'Sai rồi 😅\nĐáp án đúng: $expected';
      }
      showAnswer = true;
    });

    final nextDate = isExactMatch ? DateTime.now().add(Duration(days: newInt)) : DateTime.now();
    final updatedItem = VocabItem(
      word: item.word, meaning: item.meaning, partOfSpeech: item.partOfSpeech,
      example: item.example, dateAdded: item.dateAdded,
      repetitions: newRep, interval: newInt,
      nextReviewDate: nextDate.toIso8601String().split('T').first,
    );
    
    await vocabProvider.updateWord(updatedItem);
    _flipController.forward();
  }

  void _nextQuestion() {
    if (currentReviewIndex < reviewWords.length - 1) {
      setState(() { currentReviewIndex++; userAnswer = ''; showAnswer = false; });
      _flipController.reset();
    } else {
      setState(() => isReviewing = false);
      _showAlert('Hoàn thành! 🎊', 'Bạn đã trả lời đúng $correctCount/${reviewWords.length} câu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vocabProvider,
      builder: (context, _) {
        if (!isReviewing) {
          return _buildReviewIdle();
        }
        return _buildReviewActive();
      }
    );
  }

  Widget _buildReviewIdle() {
    final today = DateTime.now().toIso8601String().split('T').first;
    final dueCount = vocabProvider.vocabList.where((i) => i.nextReviewDate.compareTo(today) <= 0).length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_outlined, size: 22, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text('Ôn tập nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Dựa trên lịch ôn của bạn', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ]
                )
              ),
            ]
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('⏰  $dueCount từ cần ôn', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
              const SizedBox(width: 8),
              _chip('~ 3 phút'),
            ]
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startFlashcardReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ôn qua Thẻ ảnh 🖼️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _startReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Gõ đáp án ✍️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startStoryReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Ôn qua truyện ✨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ]
          ),
        ]
      )
    );
  }

  Widget _buildReviewActive() {
    return _card(
      borderColor: const Color(0xFFC7D2FE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              ...List.generate(reviewWords.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: i == currentReviewIndex ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == currentReviewIndex ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ]
          ),
          const SizedBox(height: 6),
          Text(
            'Câu ${currentReviewIndex + 1} / ${reviewWords.length}  ·  Đúng: $correctCount',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (ctx, _) {
                final angle = _flipAnimation.value * pi;
                final isFront = angle < (pi / 2);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                  child: isFront
                      ? _buildFrontCard()
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _buildBackCard(),
                        ),
                );
              },
            ),
          ),
        ]
      ),
    );
  }

  Widget _buildFrontCard() {
    final item = reviewWords[currentReviewIndex];
    final prompt = showWordSides[currentReviewIndex] ? 'Dịch sang tiếng Việt:' : 'Dịch sang tiếng Anh:';
    final target = showWordSides[currentReviewIndex] ? item.word : item.meaning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
            child: Text(prompt, style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              if (showWordSides[currentReviewIndex]) {
                _speakWord(target);
              }
            },
            child: Text(
              target,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
              textAlign: TextAlign.center
            ),
          ),

          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => userAnswer = v,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập đáp án...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: () => _submitAnswer(userAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kiểm tra', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            )
          ),
        ]
      ),
    );
  }

  Widget _buildBackCard() {
    final isCorrect = feedback.startsWith('Đúng');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isCorrect
              ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFFCDD2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Text(isCorrect ? '🎉' : '😅', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            feedback,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, height: 1.6,
              color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFBE123C)
            )
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                currentReviewIndex < reviewWords.length - 1 ? 'Tiếp theo →' : 'Hoàn thành ✓',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
              ),
            )
          ),
        ]
      ),
    );
  }

  Widget _card({required Widget child, Color borderColor = const Color(0xFFE5E7EB)}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _chip(String label, {Color bg = const Color(0xFFF3F4F6), Color fg = const Color(0xFF6B7280)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
