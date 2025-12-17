import 'package:flutter/material.dart';
import 'package:app_thanh/HomeScreen.dart';
import 'package:app_thanh/app_theme.dart';

void main() {
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
      home: const HomeScreen(),
    );
  }
}
