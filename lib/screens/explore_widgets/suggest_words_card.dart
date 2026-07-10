import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/vocab_item.dart';
import '../../services/ai_service.dart';

class SuggestWordsCard extends StatefulWidget {
  const SuggestWordsCard({super.key});

  @override
  State<SuggestWordsCard> createState() => _SuggestWordsCardState();
}

class _SuggestWordsCardState extends State<SuggestWordsCard> {
  bool _isLoading = false;
  final TextEditingController _topicController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    setState(() => _isLoading = true);

    final existingWords = vocabProvider.vocabList.map((e) => e.word).toList();
    final topic = _topicController.text.trim();
    final suggestions = await AIService.suggestTrendingWords(existingWords, count: 5, topic: topic);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (suggestions.isEmpty) {
      _showError('Không thể lấy từ gợi ý lúc này. Hãy thử lại sau!');
      return;
    }

    _showReviewDialog(suggestions);
  }

  void _showReviewDialog(List<VocabItem> suggestions) {
    // We use a local state variable inside StatefulBuilder to manage checkboxes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        List<bool> selected = List.generate(suggestions.length, (index) => true);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Từ vựng gợi ý 🔥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bỏ chọn những từ bạn đã biết:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final item = suggestions[index];
                          return CheckboxListTile(
                            value: selected[index],
                            onChanged: (val) {
                              setStateDialog(() => selected[index] = val ?? true);
                            },
                            title: Text(item.word, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                            subtitle: Text('${item.partOfSpeech} - ${item.meaning}', style: const TextStyle(fontSize: 12)),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selectedWords = <VocabItem>[];
                    for (int i = 0; i < suggestions.length; i++) {
                      if (selected[i]) {
                        selectedWords.add(suggestions[i]);
                      }
                    }
                    if (selectedWords.isNotEmpty) {
                      vocabProvider.addMultipleWords(selectedWords);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã thêm ${selectedWords.length} từ vào kho!'), backgroundColor: Colors.green),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm vào kho'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gợi ý từ vựng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text(
            'Nhận 5 từ vựng phổ biến từ AI. Bạn có thể nhập chủ đề bên dưới (tuỳ chọn).',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Nhập chủ đề (VD: IT, Du lịch, Kinh doanh...)',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.topic_outlined, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchSuggestions,
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.auto_awesome, size: 20),
              label: Text(_isLoading ? 'Đang tìm kiếm...' : 'Lấy từ mới 🔥'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
