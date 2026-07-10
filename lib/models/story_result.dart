class StoryResult {
  final String title;
  final String storyEn;
  final String storyVi;
  final List<String> blanks;

  StoryResult({
    required this.title,
    required this.storyEn,
    required this.storyVi,
    required this.blanks,
  });

  factory StoryResult.fromJson(Map<String, dynamic> json) {
    return StoryResult(
      title: json['title'] ?? '',
      storyEn: json['story_en'] ?? '',
      storyVi: json['story_vi'] ?? '',
      blanks: List<String>.from(json['blanks'] ?? []),
    );
  }
}
