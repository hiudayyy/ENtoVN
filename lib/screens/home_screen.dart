import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../main.dart'; // for vocabProvider
import '../models/vocab_item.dart';
import '../utils/review_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _searchCtrl = TextEditingController();
  
  VocabItem? _randomWord;
  bool _isFlipped = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _pickRandomWord();
    
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
  }

  Future<void> _speakWord(String word) async {
    await flutterTts.speak(word);
  }

  void _pickRandomWord() {
    if (vocabProvider.vocabList.isNotEmpty) {
      final random = Random();
      setState(() {
        _randomWord = vocabProvider.vocabList[random.nextInt(vocabProvider.vocabList.length)];
        _isFlipped = false;
      });
    }
  }

  Future<void> _deleteWord(String wordToDelete) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ vựng'),
        content: Text('Bạn có chắc muốn xóa từ "$wordToDelete"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vocabProvider.deleteWord(wordToDelete);
      if (_randomWord?.word == wordToDelete) _pickRandomWord();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: vocabProvider,
          builder: (context, _) {
            if (vocabProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sync random word in case list was empty at init
            if (_randomWord == null && vocabProvider.vocabList.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _pickRandomWord());
            }

            final vocabList = vocabProvider.vocabList;
            
            // Lọc danh sách tìm kiếm
            List<VocabItem> displayList = vocabList;
            if (_searchQuery.isNotEmpty) {
              displayList = vocabList.where((item) => 
                item.word.toLowerCase().contains(_searchQuery) || 
                item.meaning.toLowerCase().contains(_searchQuery)
              ).toList();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _pickRandomWord();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER & SEARCH ---
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xin chào 👋', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280), letterSpacing: 0.3)),
                              SizedBox(height: 2),
                              Text('Hôm nay học gì?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            ],
                          ),
                        ),
                        // Mini stats on top right
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text('${vocabProvider.streakCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm từ vựng đã học...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchCtrl.clear()) 
                          : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nếu đang tìm kiếm, hiển thị kết quả tìm kiếm ngay lập tức
                    if (_searchQuery.isNotEmpty) ...[
                      Text('Kết quả tìm kiếm (${displayList.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 10),
                      ...displayList.map((item) => _buildWordTile(item)),
                      const SizedBox(height: 50),
                    ] 
                    else ...[
                      // --- QUICK ACTIONS ---
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn('Khám phá truyện', '✨ Ôn tập sâu', const Color(0xFFEEF2FF), const Color(0xFF4F46E5), () {
                              ReviewHelper.startStoryReview(context);
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionBtn('Đã học ${vocabList.length} từ', '🎯 ${vocabProvider.dailyCount}/${vocabProvider.dailyGoal} hôm nay', const Color(0xFFECFDF5), const Color(0xFF10B981), null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- WORD OF THE DAY ---
                      if (_randomWord != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Góc học tập ngẫu nhiên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            GestureDetector(
                              onTap: _pickRandomWord,
                              child: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() => _isFlipped = !_isFlipped),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isFlipped 
                                  ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)] 
                                  : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _isFlipped ? const Color(0xFFBBF7D0) : const Color(0xFFDDD6FE)),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(8)),
                                        child: Text(_randomWord!.partOfSpeech, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isFlipped ? const Color(0xFF15803D) : const Color(0xFF4F46E5))),
                                      ),
                                      GestureDetector(
                                        onTap: () => _speakWord(_randomWord!.word),
                                        child: const Icon(Icons.volume_up_rounded, color: Colors.black54),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  if (_isFlipped && _randomWord!.example.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _randomWord!.example,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  Text(
                                    _isFlipped ? _randomWord!.meaning : _randomWord!.word,
                                    style: TextStyle(
                                      fontSize: 28, 
                                      fontWeight: FontWeight.bold, 
                                      color: _isFlipped ? const Color(0xFF15803D) : const Color(0xFF4F46E5)
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    _isFlipped ? 'Chạm để lật lại' : 'Chạm để xem nghĩa và hình ảnh',
                                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --- RECENT WORDS ---
                      const Text('Từ học gần đây', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 10),

                      if (vocabList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                const Text('📖', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text('Chưa có từ vựng nào.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...vocabList.reversed.take(5).map((item) => _buildWordTile(item)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionBtn(String title, String subtitle, Color bgColor, Color iconColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.bolt_rounded, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildWordTile(VocabItem item) {
    return Dismissible(
      key: Key(item.word),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteWord(item.word);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('XÓA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _speakWord(item.word),
                  child: const Text('🔊', style: TextStyle(fontSize: 14)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(item.partOfSpeech, style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.meaning, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}