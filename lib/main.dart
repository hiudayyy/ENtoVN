import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'providers/vocab_provider.dart';

final vocabProvider = VocabProvider();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kho Từ Vựng',
      debugShowCheckedModeBanner: false, // Ẩn chữ DEBUG ở góc phải màn hình
      theme: ThemeData(
        // Cài đặt tone màu chủ đạo là màu Indigo (mã #4F46E5) giống file thiết kế của bạn
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
        ),
        useMaterial3: true,
      ),
      // Đặt màn hình khởi chạy là HomeScreen
      home: const MainShell(),
    );
  }
}