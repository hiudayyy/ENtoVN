import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/vocab_item.dart';
import '../models/story_result.dart';
import '../models/tense_quiz.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAQwDvpa8gMEMG4DahNDCY3Kl0OL0pGTCg';

  // Khởi tạo model Gemini 1.5 Flash (tối ưu tốc độ cho App)
  static final _model = GenerativeModel(
    model: 'gemini-3.5-flash',
    apiKey: _apiKey,
  );

  /// Phân tích base64 của ảnh và trả về danh sách từ vựng
  static Future<List<AIImageResult>> analyzeImageFromAI(String base64Image) async {
    try {
      final prompt = TextPart('''
        Phân tích bức ảnh này và liệt kê 30 đồ vật, khái niệm hoặc hành động.
        Ưu tiên các từ vựng cụ thể, chi tiết hoặc mang tính học thuật (trình độ B2, C1, C2). 
        Bỏ qua các từ vựng quá cơ bản (A1, A2).
        Trả về ĐÚNG định dạng JSON sau, KHÔNG giải thích thêm:
        [{"word": "...", "meaning": "...", "partOfSpeech": "..."}]
      ''');

      final imageBytes = base64Decode(base64Image);
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final responseText = response.text ?? '';

      // Lọc sạch text để lấy đúng mảng JSON
      final jsonString = _extractJsonArray(responseText);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => AIImageResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi gọi Gemini AI (Image): $e');
      return [];
    }
  }

  /// Tự động điền chi tiết từ vựng
  static Future<VocabItem?> fetchWordDetailsFromAI(String word) async {
    try {
      final prompt = '''
        Cho từ tiếng Anh: "$word".
        Hãy trả về ĐÚNG định dạng JSON sau, KHÔNG giải thích thêm:
        {
          "meaning": "nghĩa tiếng Việt ngắn gọn",
          "partOfSpeech": "Từ loại (V, N, Adj, Adv...)",
          "example": "1 câu ví dụ tiếng Anh chứa từ này và có kèm dịch nghĩa tiếng Việt ở trong ngoặc đơn"
        }
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      final jsonString = _extractJsonObject(responseText);
      if (jsonString != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        return VocabItem(
          word: word,
          meaning: decoded['meaning'] ?? '',
          partOfSpeech: decoded['partOfSpeech'] ?? '',
          example: decoded['example'] ?? '',
          dateAdded: DateTime.now().toIso8601String().split('T').first,
          nextReviewDate: DateTime.now().toIso8601String().split('T').first,
        );
      }
      return null;
    } catch (e) {
      print('Lỗi gọi Gemini AI (Text): $e');
      return null;
    }
  }

  /// Sáng tác câu chuyện từ danh sách từ vựng
  static Future<StoryResult?> generateStoryFromWords(List<String> words) async {
    if (words.isEmpty) return null;
    try {
      final wordsListStr = words.join(', ');
      final prompt = '''
        Bạn là một giáo viên tiếng Anh.
        Hãy viết một đoạn văn hoặc câu chuyện ngắn gọn (khoảng 100-150 từ) bằng tiếng Anh, có nội dung tự nhiên và lôi cuốn, 
        trong đó BẮT BUỘC SỬ DỤNG TẤT CẢ các từ vựng sau: $wordsListStr.
        
        Trả về ĐÚNG định dạng JSON sau, KHÔNG giải thích thêm:
        {
          "title": "Tiêu đề câu chuyện bằng tiếng Anh",
          "story_en": "Nội dung câu chuyện bằng tiếng Anh",
          "story_vi": "Nội dung câu chuyện dịch sang tiếng Việt",
          "blanks": ["từ thứ 1", "từ thứ 2", ...] (Dạng nguyên mẫu hoặc biến thể xuất hiện TRONG BÀI của các từ vựng đã cho)
        }
        Lưu ý phần "blanks" là mảng chứa chính xác các từ vựng đó (hoặc dạng chia động từ/số nhiều của nó) ĐÚNG NHƯ CÁCH NÓ XUẤT HIỆN trong story_en để làm bài tập đục lỗ.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      final jsonString = _extractJsonObject(responseText);
      if (jsonString != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        return StoryResult.fromJson(decoded);
      }
      return null;
    } catch (e) {
      print('Lỗi gọi Gemini AI (Story): $e');
      return null;
    }
  }

  /// Gợi ý từ vựng trending/daily
  static Future<List<VocabItem>> suggestTrendingWords(List<String> existingWords, {int count = 5, String topic = ''}) async {
    try {
      final blacklistStr = existingWords.isEmpty ? "không có" : existingWords.join(', ');
      final topicStr = topic.trim().isNotEmpty ? "thuộc chủ đề '$topic'" : "trong thực tế (giao tiếp, công việc, tin tức đời sống)";
      
      final prompt = '''
        Bạn là một chuyên gia ngôn ngữ và từ điển tiếng Anh thông minh. 
        Hãy đề xuất $count từ vựng tiếng Anh ĐƯỢC SỬ DỤNG PHỔ BIẾN NHẤT $topicStr.
        Ưu tiên những từ mang tính thiết thực, có tần suất xuất hiện cao, và thực sự phù hợp/hữu ích cho người học tiếng Anh để nâng cao trình độ.
        KHÔNG NÊN đề xuất những từ lóng (slang) quá dị biệt hoặc những từ quá hàn lâm ít khi dùng tới.
        TUYỆT ĐỐI KHÔNG đề xuất các từ trong danh sách sau: $blacklistStr.
        
        Trả về ĐÚNG định dạng JSON mảng sau, KHÔNG giải thích thêm:
        [
          {
            "word": "từ vựng",
            "meaning": "nghĩa tiếng Việt ngắn gọn",
            "partOfSpeech": "Từ loại (V, N, Adj, Adv...)",
            "example": "1 câu ví dụ tiếng Anh chứa từ này và có kèm dịch nghĩa tiếng Việt ở trong ngoặc đơn"
          }
        ]
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      final jsonString = _extractJsonArray(responseText);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final today = DateTime.now().toIso8601String().split('T').first;
        return decoded.map((item) => VocabItem(
          word: item['word'] ?? '',
          meaning: item['meaning'] ?? '',
          partOfSpeech: item['partOfSpeech'] ?? '',
          example: item['example'] ?? '',
          dateAdded: today,
          nextReviewDate: today,
        )).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi gọi Gemini AI (Suggest): $e');
      return [];
    }
  }

  /// Sinh bài kiểm tra trắc nghiệm các thì (Tenses)
  static Future<List<TenseQuizQuestion>> generateTenseQuiz({int count = 5}) async {
    try {
      final prompt = '''
        Bạn là một giáo viên tiếng Anh chuyên nghiệp.
        Hãy tạo ra $count câu hỏi trắc nghiệm (Multiple Choice) để kiểm tra kiến thức về các thì trong tiếng Anh (Tenses) của học viên.
        Bao gồm nhiều thì khác nhau: Hiện tại, Quá khứ, Tương lai, Hoàn thành, Tiếp diễn...
        Mỗi câu hỏi có 1 chỗ trống (blank) để điền động từ được chia đúng thì, kèm theo 4 đáp án lựa chọn.
        Giải thích ngắn gọn bằng tiếng Việt lý do tại sao lại dùng thì đó.

        Trả về ĐÚNG định dạng JSON mảng sau, KHÔNG giải thích thêm:
        [
          {
            "question": "Câu tiếng Anh có chứa chỗ trống dạng _______ (động từ nguyên mẫu).",
            "options": ["đáp án 1", "đáp án 2", "đáp án 3", "đáp án 4"],
            "correctIndex": vị_trí_đáp_án_đúng_từ_0_đến_3,
            "explanation": "Giải thích ngắn gọn bằng tiếng Việt tại sao chọn thì này dựa vào dấu hiệu nhận biết nào.",
            "tenseName": "Tên của thì (VD: Hiện tại đơn, Quá khứ hoàn thành...)"
          }
        ]
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      final jsonString = _extractJsonArray(responseText);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => TenseQuizQuestion.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi gọi Gemini AI (Tense Quiz): $e');
      return [];
    }
  }

  // Hàm hỗ trợ bóc tách JSON mảng từ chuỗi phản hồi của AI
  static String? _extractJsonArray(String rawText) {
    final startIndex = rawText.indexOf('[');
    final endIndex = rawText.lastIndexOf(']');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return rawText.substring(startIndex, endIndex + 1);
    }
    return null;
  }

  // Hàm hỗ trợ bóc tách JSON object từ chuỗi phản hồi của AI
  static String? _extractJsonObject(String rawText) {
    final startIndex = rawText.indexOf('{');
    final endIndex = rawText.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return rawText.substring(startIndex, endIndex + 1);
    }
    return null;
  }
}