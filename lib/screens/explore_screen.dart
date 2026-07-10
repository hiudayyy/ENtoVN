import 'package:flutter/material.dart';
import '../main.dart'; // for vocabProvider
import 'explore_widgets/add_word_card.dart';
import 'explore_widgets/review_card.dart';
import 'explore_widgets/suggest_words_card.dart';
import 'explore_widgets/grammar_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header (SliverAppBar) ──────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: ListenableBuilder(
                      listenable: vocabProvider,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Học & ôn tập',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w400)),
                            const SizedBox(height: 4),
                            const Text('Khám phá ✨',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(height: 16),
                            Row(children: [
                              _statPill('${vocabProvider.vocabList.length}', 'Từ đã học'),
                              const SizedBox(width: 8),
                              _statPill('${vocabProvider.dailyCount}/${vocabProvider.dailyGoal}', 'Hôm nay'),
                              const SizedBox(width: 8),
                              _statPill('🔥 ${vocabProvider.streakCount}', 'Chuỗi ngày'),
                            ]),
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body Content ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Thêm từ mới'),
                  const SizedBox(height: 10),
                  const AddWordCard(),
                  const SizedBox(height: 20),

                  const SuggestWordsCard(),
                  const SizedBox(height: 20),
                  
                  _sectionLabel('Ngữ pháp'),
                  const SizedBox(height: 10),
                  const GrammarCard(),
                  const SizedBox(height: 20),

                  _sectionLabel('Ôn tập hôm nay'),
                  const SizedBox(height: 10),
                  const ReviewCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.8));
  }
}