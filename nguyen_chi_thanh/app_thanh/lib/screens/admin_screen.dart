import 'package:flutter/material.dart';
import 'package:app_thanh/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_thanh/screens/category_screen.dart';
import 'package:app_thanh/screens/market_screen.dart'; // Để quản lý sản phẩm nếu cần
import 'package:app_thanh/utils/auth_session.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove(AuthSession.roleKey);
    // Xóa thêm các thông tin khác nếu cần
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: const Text('Quản lý Danh Mục Sản Phẩm'),
              subtitle: const Text('Thêm, Xóa, Sửa danh mục'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store, color: Colors.green),
              title: const Text('Quản lý Sản Phẩm'),
              subtitle: const Text('Xem danh sách sản phẩm (Market)'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
