import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/story_result.dart';
import '../../main.dart'; // for vocabProvider

class StoryReviewModal extends StatefulWidget {
  final StoryResult storyResult;

  const StoryReviewModal({super.key, required this.storyResult});

  @override
  State<StoryReviewModal> createState() => _StoryReviewModalState();
}

class _StoryReviewModalState extends State<StoryReviewModal> {
  final List<StoryBlank> _blanksData = [];
  final List<dynamic> _parsedContent = []; // mix of String and StoryBlank
  
  bool _showTranslation = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _parseStory();
  }

  @override
  void dispose() {
    for (var b in _blanksData) {
      b.controller.dispose();
    }
    super.dispose();
  }

  void _parseStory() {
    String text = widget.storyResult.storyEn;
    final blanks = List<String>.from(widget.storyResult.blanks);
    blanks.sort((a, b) => b.length.compareTo(a.length));
    
    if (blanks.isEmpty) {
      _parsedContent.add(text);
      return;
    }
    
    final escapedBlanks = blanks.map((b) => RegExp.escape(b)).join('|');
    final regex = RegExp(r'\b(' + escapedBlanks + r')\b', caseSensitive: false);
    
    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        _parsedContent.add(text.substring(lastIndex, match.start));
      }
      
      final matchedText = match.group(0)!;
      final blankData = StoryBlank(id: _blanksData.length, correctWord: matchedText);
      _blanksData.add(blankData);
      _parsedContent.add(blankData);
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      _parsedContent.add(text.substring(lastIndex));
    }
  }

  bool _allCorrect() {
    for (var b in _blanksData) {
      if (b.controller.text.trim().toLowerCase() != b.correctWord.toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  void _checkAnswers() {
    setState(() {
      _showResults = true;
    });
    
    if (_allCorrect()) {
      _finishReview(gaveUp: false);
    }
  }

  void _finishReview({required bool gaveUp}) {
    List<String> correctWords = [];
    List<String> wrongWords = [];
    
    for (var b in _blanksData) {
      if (b.controller.text.trim().toLowerCase() == b.correctWord.toLowerCase()) {
        correctWords.add(b.correctWord);
      } else {
        wrongWords.add(b.correctWord);
      }
    }
    
    if (gaveUp) {
      for (var b in _blanksData) {
        if (wrongWords.contains(b.correctWord)) {
          b.controller.text = b.correctWord;
        }
      }
      setState(() { _showResults = true; });
    }
    
    if (correctWords.isNotEmpty) {
      vocabProvider.markWordsAsReviewed(correctWords, isCorrect: true);
    }
    if (wrongWords.isNotEmpty) {
      vocabProvider.markWordsAsReviewed(wrongWords, isCorrect: false);
    }
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => AlertDialog(
      title: Text(correctWords.isNotEmpty ? '🎉 Hoàn thành!' : 'Cố gắng lên!'),
      content: Text(
        correctWords.isNotEmpty 
          ? 'Bạn đã đúng ${correctWords.length}/${_blanksData.length} từ. ${gaveUp ? "Các từ sai đã được hiển thị đáp án. " : ""}Tiến độ hôm nay đã được lưu lại.'
          : 'Bạn chưa điền đúng từ nào. Hãy ôn tập lại sau nhé!'
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // close modal
          },
          child: const Text('Đóng')
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Ôn tập qua câu chuyện', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
            child: Text(_showTranslation ? 'Tắt dịch' : 'Bản dịch', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.storyResult.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 20),
            
            // Story Content
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF374151)),
                  children: _parsedContent.map((item) {
                    if (item is String) {
                      return TextSpan(text: item);
                    } else if (item is StoryBlank) {
                      final isCorrect = _showResults && item.controller.text.trim().toLowerCase() == item.correctWord.toLowerCase();
                      final isWrong = _showResults && !isCorrect;
                      
                      return WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          width: max(item.correctWord.length * 11.0, 50.0),
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: TextField(
                            controller: item.controller,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isCorrect ? Colors.green.shade700 : (isWrong ? Colors.red.shade700 : const Color(0xFF4F46E5)),
                              fontWeight: FontWeight.bold
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              isDense: true,
                              filled: true,
                              fillColor: isCorrect ? Colors.green.withAlpha(30) : (isWrong ? Colors.red.withAlpha(30) : const Color(0xFFEEF2FF)),
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(6)),
                            ),
                          )
                        )
                      );
                    }
                    return const TextSpan();
                  }).toList(),
                ),
              )
            ),
            
            if (_showTranslation) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    const SizedBox(height: 8),
                    Text(widget.storyResult.storyVi, style: const TextStyle(fontSize: 15, color: Color(0xFF92400E), height: 1.6)),
                  ],
                ),
              )
            ],
            
            const SizedBox(height: 40),
            
            if (!_showResults || _allCorrect())
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('Kiểm tra đáp án', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _finishReview(gaveUp: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('Bỏ cuộc & Xem đáp án', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkAnswers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            
            if (_showResults && !_allCorrect()) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text('Bạn có từ chưa chính xác. Hãy sửa lại hoặc chọn "Bỏ cuộc".', 
                  style: TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center)
              )
            ]
          ],
        ),
      ),
    );
  }
}

class StoryBlank {
  final int id;
  final String correctWord;
  final TextEditingController controller = TextEditingController();
  StoryBlank({required this.id, required this.correctWord});
}
