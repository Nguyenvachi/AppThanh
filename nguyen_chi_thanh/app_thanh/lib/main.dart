import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [Bước 9] Thêm thư viện này
import 'package:app_thanh/HomeScreen.dart';
import 'package:app_thanh/app_theme.dart';
import 'package:app_thanh/screens/login_screen.dart'; // Thêm import màn hình đăng nhập

// [Bước 9] Cập nhật hàm main thành async để load biến môi trường
Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load file cấu hình .env
  runApp(const MyApp());
}

/// Ứng dụng chính
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Đa Năng',
      debugShowCheckedModeBanner: false,

      // Theme tổng thể của ứng dụng (từ app_theme.dart)
      theme: AppTheme.lightTheme,

      // Màn hình đầu tiên
      // Thay đổi từ HomeScreen thành LoginScreen để bắt đầu chức năng đăng nhập
      home: const LoginScreen(),
    );
  }
}