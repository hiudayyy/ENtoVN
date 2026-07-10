import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/vocab_item.dart';
import '../../main.dart';

class FlashcardReviewModal extends StatefulWidget {
  final List<VocabItem> wordsToReview;

  const FlashcardReviewModal({super.key, required this.wordsToReview});

  @override
  State<FlashcardReviewModal> createState() => _FlashcardReviewModalState();
}

class _FlashcardReviewModalState extends State<FlashcardReviewModal> {
  final FlutterTts flutterTts = FlutterTts();
  int _currentIndex = 0;
  bool _isFlipped = false;

  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
  }

  Future<void> _speakWord(String word) async {
    await flutterTts.speak(word);
  }

  void _nextCard(bool isCorrect) {
    if (isCorrect) {
      _correctCount++;
      vocabProvider.markWordsAsReviewed([widget.wordsToReview[_currentIndex].word], isCorrect: true);
    } else {
      _wrongCount++;
      vocabProvider.markWordsAsReviewed([widget.wordsToReview[_currentIndex].word], isCorrect: false);
    }

    if (_currentIndex < widget.wordsToReview.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Hoàn thành!'),
        content: Text('Bạn đã ôn tập xong ${widget.wordsToReview.length} từ.\n\nĐã nhớ: $_correctCount\nQuên: $_wrongCount\n\nTiến độ hôm nay đã được lưu lại.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close modal
            },
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wordsToReview.isEmpty) {
      return const Scaffold(body: Center(child: Text('Không có từ vựng nào để ôn tập')));
    }

    final currentWord = widget.wordsToReview[_currentIndex];
    final progress = (_currentIndex) / widget.wordsToReview.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Ôn tập qua thẻ', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFEEF2FF),
            color: const Color(0xFF4F46E5),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              Text(
                'Thẻ ${_currentIndex + 1} / ${widget.wordsToReview.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              
              // CÁC THẺ FLASHCARD
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isFlipped = !_isFlipped),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isFlipped ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: _isFlipped ? const Color(0xFF4F46E5).withAlpha(30) : Colors.black.withAlpha(10),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [


                            Text(
                              _isFlipped ? currentWord.meaning : currentWord.word,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _isFlipped ? const Color(0xFF4F46E5) : const Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            if (!_isFlipped) ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _speakWord(currentWord.word),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3F4F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFF4B5563), size: 28),
                                ),
                              )
                            ],

                            if (_isFlipped && currentWord.example.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentWord.example,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],

                            const SizedBox(height: 30),
                            Text(
                              _isFlipped ? 'Chạm để xem lại từ' : 'Chạm để xem nghĩa & ảnh',
                              style: const TextStyle(fontSize: 13, color: Colors.black45),
                            )
                          ],
                        ),
                      ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // NÚT ĐÁNH GIÁ (Chỉ hiện khi đã lật thẻ)
              if (_isFlipped)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _nextCard(false),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Quên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEF4444), // Red
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 2),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _nextCard(true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Nhớ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF10B981).withAlpha(100),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 56, // matching height of buttons
                  child: Center(
                    child: Text('Hãy lật thẻ trước khi đánh giá', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
