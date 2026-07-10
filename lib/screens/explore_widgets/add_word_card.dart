import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../main.dart'; // for vocabProvider
import '../../models/vocab_item.dart';
import '../../services/ai_service.dart';

class AddWordCard extends StatefulWidget {
  const AddWordCard({super.key});

  @override
  State<AddWordCard> createState() => _AddWordCardState();
}

class _AddWordCardState extends State<AddWordCard> {
  final _wordCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  
  bool isAiLoading = false;
  bool isImageAnalyzing = false;

  List<AIImageResult> suggestedWords = [];
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _posCtrl.dispose();
    _exampleCtrl.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  void _showAlert(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> _addWord() async {
    final word = _wordCtrl.text.trim();
    final meaning = _meaningCtrl.text.trim();

    if (word.isEmpty || meaning.isEmpty) {
      _showAlert('Lỗi', 'Vui lòng nhập cả từ và nghĩa.');
      return;
    }

    final newItem = VocabItem(
      word: word,
      meaning: meaning,
      partOfSpeech: _posCtrl.text.trim(),
      example: _exampleCtrl.text.trim(),
      dateAdded: DateTime.now().toIso8601String().split('T').first,
      nextReviewDate: DateTime.now().toIso8601String().split('T').first,
    );

    try {
      await vocabProvider.addWord(newItem);
      if (!mounted) return;
      _wordCtrl.clear();
      _meaningCtrl.clear();
      _posCtrl.clear();
      _exampleCtrl.clear();
      _showAlert('Thành công 🎉', 'Từ mới đã được lưu vào kho!');
    } catch (e) {
      if (e.toString().contains('Duplicate')) {
        _showAlert('Từ đã tồn tại! 🛑', 'Từ "$word" đã có trong kho từ vựng của bạn rồi.');
      } else {
        _showAlert('Lỗi', 'Không thể lưu từ vựng: $e');
      }
    }
  }

  Future<void> _handleScanImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;

    setState(() => isImageAnalyzing = true);
    
    try {
      final bytes = await File(image.path).readAsBytes();
      final b64 = base64Encode(bytes);
      final aiResults = await AIService.analyzeImageFromAI(b64);
      
      if (!mounted) return;
      
      if (aiResults.isNotEmpty) {
        final learned = vocabProvider.vocabList.map((e) => e.word.toLowerCase()).toSet();
        final uniqueWords = aiResults.where((i) => !learned.contains(i.word.toLowerCase())).toList();
        
        setState(() { 
          suggestedWords = uniqueWords.take(5).toList(); 
          isImageAnalyzing = false; 
        });
        
        if (suggestedWords.isNotEmpty) {
          _showTinderSwipeModal();
        } else {
          _showAlert('Quá đỉnh! 🌟', 'Tất cả các từ trong ảnh bạn đã học rồi!');
        }
      } else {
        setState(() => isImageAnalyzing = false);
        _showAlert('Lỗi', 'Không thể nhận diện hình ảnh này hoặc định dạng phản hồi từ AI không đúng.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isImageAnalyzing = false);
      _showAlert('Lỗi', 'Có lỗi xảy ra: $e');
    }
  }

  void _showTinderSwipeModal() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: false,
      pageBuilder: (ctx, _, __) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40, bottom: 20),
                child: Text('👇 VUỐT ĐỂ LỌC TỪ VỰNG 👇',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
              Expanded(
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: suggestedWords.length,
                  onSwipe: (prev, curr, direction) {
                    if (direction == CardSwiperDirection.right) {
                      _saveWordDirectly(suggestedWords[prev]);
                    }
                    return true;
                  },
                  onEnd: () {
                    Navigator.pop(ctx);
                    setState(() => suggestedWords.clear());
                    _showAlert('Hoàn tất! 🎉', 'Bạn đã duyệt xong các từ vựng.');
                  },
                  cardBuilder: (ctx, index, _, __) {
                    final card = suggestedWords[index];
                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Text(card.word, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                          if (card.partOfSpeech.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                              child: Text(card.partOfSpeech, style: const TextStyle(fontSize: 16, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                            ),
                          Text(card.meaning, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                        ]
                      ),
                    );
                  },
                )
              ),
              TextButton(
                onPressed: () { 
                  Navigator.pop(ctx); 
                  setState(() => suggestedWords.clear()); 
                },
                child: const Text('✕ Đóng & Bỏ qua', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ]
          )
        ),
      ),
    );
  }

  Future<void> _saveWordDirectly(AIImageResult item) async {
    final newItem = VocabItem(
      word: item.word, 
      meaning: item.meaning, 
      partOfSpeech: item.partOfSpeech,
      dateAdded: DateTime.now().toIso8601String().split('T').first,
      nextReviewDate: DateTime.now().toIso8601String().split('T').first,
    );
    try {
      await vocabProvider.addWord(newItem);
    } catch (e) {
      // ignore duplicate inside swiper silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(
                children: [
                  const Text('Thêm từ mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                    child: const Text('+ Mới', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                  ),
                ]
              ),
              Row(
                children: [
                  _squareBtn(
                    child: isImageAnalyzing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B7280)))
                        : const Icon(Icons.camera_alt_outlined, size: 17, color: Color(0xFF6B7280)),
                    onTap: isImageAnalyzing ? null : _handleScanImage,
                  ),
                  const SizedBox(width: 6),
                  _squareBtn(
                    child: isAiLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B7280)))
                        : const Icon(Icons.auto_awesome_outlined, size: 17, color: Color(0xFF6B7280)),
                    onTap: isAiLoading ? null : () async {
                      if (_wordCtrl.text.trim().isEmpty) {
                        _showAlert('Chưa nhập từ', 'Vui lòng nhập một từ tiếng Anh vào ô đầu tiên để AI tìm kiếm.');
                        return;
                      }
                      setState(() => isAiLoading = true);
                      final result = await AIService.fetchWordDetailsFromAI(_wordCtrl.text.trim());
                      if (!mounted) return;
                      setState(() => isAiLoading = false);

                      if (result != null) {
                        setState(() {
                          _meaningCtrl.text = result.meaning;
                          _posCtrl.text = result.partOfSpeech;
                          _exampleCtrl.text = result.example;
                        });
                      } else {
                        _showAlert('Lỗi', 'Không thể lấy dữ liệu từ AI lúc này. Vui lòng thử lại.');
                      }
                    },
                  ),
                ]
              ),
            ]
          ),
          const SizedBox(height: 14),

          _field(_wordCtrl, '🔤  Từ tiếng Anh *'),
          const SizedBox(height: 8),
          _field(_meaningCtrl, '🇻🇳  Nghĩa tiếng Việt *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_posCtrl, '🏷️  Loại từ (N, V, Adj...)')),
            ],
          ),
          const SizedBox(height: 8),
          _field(_exampleCtrl, '📝  Câu ví dụ (Không bắt buộc)'),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lưu từ vựng →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
            ),
          ),
        ]
      )
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

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true, fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      ),
    );
  }

  Widget _squareBtn({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Center(child: child),
      ),
    );
  }
}
