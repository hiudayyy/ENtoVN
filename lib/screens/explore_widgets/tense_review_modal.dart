import 'package:flutter/material.dart';
import '../../models/tense_quiz.dart';
import '../../services/ai_service.dart';

class TenseReviewModal extends StatefulWidget {
  const TenseReviewModal({super.key});

  @override
  State<TenseReviewModal> createState() => _TenseReviewModalState();
}

class _TenseReviewModalState extends State<TenseReviewModal> {
  bool _isLoading = true;
  List<TenseQuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;

  int? _selectedOption;
  bool _isAnswered = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    final questions = await AIService.generateTenseQuiz(count: 5);
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
        _currentIndex = 0;
        _correctCount = 0;
        _selectedOption = null;
        _isAnswered = false;
        _showHint = false;
      });
    }
  }

  void _submitAnswer(int index) {
    if (_isAnswered) return;
    
    final isCorrect = (index == _questions[_currentIndex].correctIndex);
    setState(() {
      _selectedOption = index;
      _isAnswered = true;
      if (isCorrect) _correctCount++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
        _showHint = false;
      });
    } else {
      // Done
      setState(() {
        _currentIndex++; // to show summary
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.spellcheck, color: Color(0xFF4F46E5)),
                const SizedBox(width: 10),
                const Text('Kiểm tra các thì', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: _isLoading 
                ? _buildLoading()
                : _questions.isEmpty
                    ? _buildError()
                    : _currentIndex >= _questions.length
                        ? _buildSummary()
                        : _buildQuestionCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF4F46E5)),
        const SizedBox(height: 20),
        Text('AI đang soạn bài tập ngữ pháp...', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
        const SizedBox(height: 16),
        const Text('Không thể tải bài tập. Vui lòng thử lại sau.'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadQuiz,
          child: const Text('Thử lại'),
        )
      ],
    );
  }

  Widget _buildQuestionCard() {
    final q = _questions[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu ${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (!_isAnswered)
                GestureDetector(
                  onTap: () => setState(() => _showHint = true),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: _showHint ? Colors.amber : Colors.grey.shade400, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _showHint ? q.tenseName : 'Gợi ý',
                        style: TextStyle(
                          color: _showHint ? Colors.amber.shade700 : Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              q.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5, color: Color(0xFF1F2937)),
            ),
          ),
          const SizedBox(height: 24),

          ...List.generate(q.options.length, (index) {
            bool isSelected = _selectedOption == index;
            bool isCorrectOpt = index == q.correctIndex;
            
            Color bgColor = Colors.white;
            Color borderColor = const Color(0xFFE5E7EB);
            Color textColor = const Color(0xFF374151);

            if (_isAnswered) {
              if (isCorrectOpt) {
                bgColor = const Color(0xFFECFDF5);
                borderColor = const Color(0xFF10B981);
                textColor = const Color(0xFF065F46);
              } else if (isSelected) {
                bgColor = const Color(0xFFFEF2F2);
                borderColor = const Color(0xFFEF4444);
                textColor = const Color(0xFF991B1B);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFF4F46E5);
            }

            return GestureDetector(
              onTap: () => _submitAnswer(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrectOpt) ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + index) + '.', // A, B, C, D
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.options[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (_isAnswered && isCorrectOpt)
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                    else if (_isAnswered && isSelected && !isCorrectOpt)
                      const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20)
                  ],
                ),
              ),
            );
          }),

          if (_isAnswered) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFF4F46E5), size: 20),
                      const SizedBox(width: 8),
                      const Text('Giải thích', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(q.explanation, style: const TextStyle(color: Color(0xFF374151), height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1 ? 'Tiếp tục' : 'Hoàn thành',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummary() {
    bool passed = _correctCount >= (_questions.length / 2);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.emoji_events : Icons.school,
            size: 80,
            color: passed ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 24),
          const Text('Hoàn thành bài kiểm tra!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Bạn đã trả lời đúng $_correctCount/${_questions.length} câu',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đóng', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
