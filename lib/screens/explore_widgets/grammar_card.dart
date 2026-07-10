import 'package:flutter/material.dart';
import 'tense_review_modal.dart';

class GrammarCard extends StatelessWidget {
  const GrammarCard({super.key});

  void _startTenseQuiz(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TenseReviewModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFFE4E6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rule, size: 22, color: Color(0xFFE11D48)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ngữ pháp (Grammar)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Luyện tập các thì tiếng Anh', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ]
                )
              ),
            ]
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _startTenseQuiz(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kiểm tra các thì 📝', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
