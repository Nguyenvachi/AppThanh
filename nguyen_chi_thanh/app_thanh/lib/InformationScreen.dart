import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import để xóa token
import 'package:app_thanh/screens/login_screen.dart'; // Import để chuyển về màn hình đăng nhập
import 'package:app_thanh/utils/auth_session.dart';
import 'app_colors.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final Uri telUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception();
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      _showSnack(context, "Không thể mở Điện thoại. Đã sao chép: $phone");
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        return;
      }
      final Uri gmailWeb = Uri.parse(
        "https://mail.google.com/mail/?view=cm&to=$email",
      );
      if (await canLaunchUrl(gmailWeb)) {
        await launchUrl(gmailWeb, mode: LaunchMode.externalApplication);
        return;
      }
      throw Exception();
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: email));
      _showSnack(context, "Không thể mở Email. Đã sao chép: $email");
    }
  }

  Future<void> _openYouTube(String url) async {
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(BuildContext ctx, String msg) {
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.black87),
      );
    } catch (_) {}
  }

  // Hàm xử lý đăng xuất
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove(AuthSession.roleKey);
    // Có thể xóa thêm các thông tin lưu trữ khác nếu cần
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ---------------------------
      // APPBAR TỐI GIẢN
      // ---------------------------
      appBar: AppBar(
        title: const Text(
          "Thông Tin Cá Nhân",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      // ---------------------------
      // BODY TỐI GIẢN
      // ---------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // ---------------------
            // AVATAR TỐI GIẢN
            // ---------------------
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 70, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------------
            // HỌ TÊN
            // ---------------------
            Text(
              "Nguyễn Chí Thanh",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Sinh viên",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 30),

            // ---------------------
            // THÔNG TIN CÁ NHÂN
            // ---------------------
            _buildInfoCard(
              context: context,
              icon: Icons.school_outlined,
              title: "Khoa",
              content: "Công nghệ thông tin",
            ),
            const SizedBox(height: 14),

            _buildInfoCard(
              context: context,
              icon: Icons.email_outlined,
              title: "Email",
              content: "tn822798@gmail.com",
              isLink: true,
              onTap: () => _sendEmail(context, "tn822798@gmail.com"),
            ),
            const SizedBox(height: 14),

            _buildInfoCard(
              context: context,
              icon: Icons.phone_outlined,
              title: "Số điện thoại",
              content: "0398219340",
              isLink: true,
              onTap: () => _makePhoneCall(context, "0398219340"),
            ),
            const SizedBox(height: 14),

            _buildInfoCard(
              context: context,
              icon: Icons.play_circle_outline,
              title: "Kênh YouTube",
              content: "Nguyễn Chí Thanh Official",
              isLink: true,
              onTap: () => _openYouTube("https://www.youtube.com"),
            ),

            const SizedBox(height: 30),

            // ---------------------
            // NÚT ĐĂNG XUẤT
            // ---------------------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // THẺ THÔNG TIN TỐI GIẢN
  // ---------------------------
  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: content));
        _showSnack(context, "Đã sao chép: $content");
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: Colors.grey.shade700),
            const SizedBox(width: 16),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLink ? Colors.black : Colors.black87,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            if (isLink)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
