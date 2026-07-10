class VocabItem {
  final String word;
  final String meaning;
  final String partOfSpeech;
  final String example;
  final String dateAdded;
  final int repetitions;
  final int interval;
  final String nextReviewDate;

  VocabItem({
    required this.word,
    required this.meaning,
    required this.partOfSpeech,
    this.example = '',
    required this.dateAdded,
    this.repetitions = 0,
    this.interval = 0,
    required this.nextReviewDate,
  });

  // Chuyển từ JSON (lấy từ bộ nhớ) sang Object
  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      partOfSpeech: json['partOfSpeech'] ?? '',
      example: json['example'] ?? '',
      dateAdded: json['dateAdded'] ?? '',
      repetitions: json['repetitions'] ?? 0,
      interval: json['interval'] ?? 0,
      nextReviewDate: json['nextReviewDate'] ?? '',
    );
  }

  // Chuyển từ Object sang Map để lưu xuống JSON
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
      'partOfSpeech': partOfSpeech,
      'example': example,
      'dateAdded': dateAdded,
      'repetitions': repetitions,
      'interval': interval,
      'nextReviewDate': nextReviewDate,
    };
  }
}

// Lớp phụ trợ cho kết quả AI trả về khi quét ảnh
class AIImageResult {
  final String word;
  final String meaning;
  final String partOfSpeech;

  AIImageResult({
    required this.word,
    required this.meaning,
    this.partOfSpeech = '',
  });

  factory AIImageResult.fromJson(Map<String, dynamic> json) {
    return AIImageResult(
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
      partOfSpeech: json['partOfSpeech'] ?? '',
    );
  }
}