import 'dart:math';

class StringUtils {
  /// Thuật toán đo khoảng cách chuỗi (Levenshtein) bằng Dart
  static int getLevenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    List<List<int>> matrix = List.generate(
      b.length + 1, 
      (i) => List.filled(a.length + 1, 0)
    );
    
    for (int i = 0; i <= b.length; i++) { matrix[i][0] = i; }
    for (int j = 0; j <= a.length; j++) { matrix[0][j] = j; }
    
    for (int i = 1; i <= b.length; i++) {
      for (int j = 1; j <= a.length; j++) {
        if (b[i - 1] == a[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = [
            matrix[i - 1][j - 1] + 1, 
            matrix[i][j - 1] + 1, 
            matrix[i - 1][j] + 1
          ].reduce(min);
        }
      }
    }
    return matrix[b.length][a.length];
  }
}
