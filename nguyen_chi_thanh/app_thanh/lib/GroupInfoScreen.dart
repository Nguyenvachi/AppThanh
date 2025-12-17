import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _members = [
    {
      'name': 'Nguyễn Chí Thanh',
      'mssv': '2280602918',
      'role': 'Nhóm trưởng',
      'phone': '0398219340',
      'email': 'Tn822798@gmail.com',
      'description': 'Phát triển giao diện và tính năng dịch',
    },
    {
      'name': 'Thành viên 2',
      'mssv': '2199',
      'role': 'Thành viên',
      'phone': '0987654321',
      'email': 'member2@student.edu.vn',
      'description': 'Phát triển tính năng chuyển đổi nhiệt độ',
    },
    {
      'name': 'Thành viên 3',
      'mssv': '2200',
      'role': 'Thành viên',
      'phone': '0369852147',
      'email': 'member3@student.edu.vn',
      'description': 'Phát triển tính năng đồng hồ báo thức',
    },
    {
      'name': 'Thành viên 4',
      'mssv': '2201',
      'role': 'Thành viên',
      'phone': '0258963147',
      'email': 'member4@student.edu.vn',
      'description': 'Phát triển tính năng đồng hồ bấm giờ',
    },
    {
      'name': 'Thành viên 5',
      'mssv': '2202',
      'role': 'Thành viên',
      'phone': '0147258369',
      'email': 'member5@student.edu.vn',
      'description': 'Phát triển tính năng YouTube Player',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Thông Tin Nhóm',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildPageIndicators(),
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _members.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) =>
                  _buildMemberCard(_members[index]),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vuốt để xem thành viên khác',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -------------------------
  // PAGE INDICATOR TỐI GIẢN
  // -------------------------
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _members.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 10 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.black : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // CARD THÀNH VIÊN TỐI GIẢN
  // -------------------------
  Widget _buildMemberCard(Map<String, String> member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAvatar(member['name']!),
              const SizedBox(height: 20),
              _buildName(member['name']!),
              _buildRole(member['role']!),
              const SizedBox(height: 24),
              _buildInfoRow(
                icon: Icons.badge,
                label: 'MSSV',
                value: member['mssv']!,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: member['phone']!,
                onTap: () => _makePhoneCall(member['phone']!),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: member['email']!,
                onTap: () => _sendEmail(member['email']!),
              ),
              const SizedBox(height: 24),
              _buildDescription(member['description']!),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // AVATAR TỐI GIẢN
  // -------------------------
  Widget _buildAvatar(String name) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // -------------------------
  // TÊN + CHỨC VỤ
  // -------------------------
  Widget _buildName(String name) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRole(String role) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // -------------------------
  // INFO ROW (TỐI GIẢN)
  // -------------------------
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // DESCRIPTION (TỐI GIẢN)
  // -------------------------
  Widget _buildDescription(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nhiệm vụ",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // CALL & EMAIL (GIỮ NGUYÊN LOGIC)
  // -------------------------
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}
