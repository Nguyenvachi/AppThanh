import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static const String tokenKey = 'jwt_token';
  static const String roleKey = 'user_role';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  static Future<void> saveRole(String? role) async {
    final prefs = await SharedPreferences.getInstance();
    if (role == null || role.trim().isEmpty) {
      await prefs.remove(roleKey);
      return;
    }
    await prefs.setString(roleKey, role);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(roleKey);
  }

  static bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      // Nếu decode lỗi thì coi như token không hợp lệ
      return true;
    }
  }

  static Future<String?> getRoleFromToken() async {
    final token = await getToken();
    if (token == null) return null;
    if (isTokenExpired(token)) return null;

    try {
      final decoded = JwtDecoder.decode(token);
      final role = extractRoleFromDecodedToken(decoded);
      if (role != null) {
        // cache để dùng nhanh cho UI
        await saveRole(role);
      }
      return role;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isAdmin() async {
    final saved = await getSavedRole();
    if (saved != null && isAdminRole(saved)) return true;

    final roleFromToken = await getRoleFromToken();
    return isAdminRole(roleFromToken);
  }

  // Cải thiện hàm check role để linh hoạt hơn
  static bool isAdminRole(String? role) {
    if (role == null) return false;
    final r = role.trim().toLowerCase();
    // Chấp nhận nhiều biến thể của Admin
    return r == 'admin' || r == 'administrator' || r == 'quản trị viên';
  }

  static String? extractRoleFromDecodedToken(Map<String, dynamic> decoded) {
    // 1. Thử các key phổ biến chứa Role
    dynamic roleValue =
        decoded['role'] ??
        decoded['roles'] ??
        decoded['Role'] ??
        decoded['Roles'] ??
        decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role']; // Thêm namespace chuẩn SOAP

    final normalized = _normalizeRoleValue(roleValue);
    if (normalized != null) return normalized;

    // 2. Tìm case-insensitive trong map
    for (final entry in decoded.entries) {
      if (entry.key.toLowerCase().contains('role')) {
        final candidate = _normalizeRoleValue(entry.value);
        if (candidate != null) return candidate;
      }
    }

    return null;
  }

  static String? _normalizeRoleValue(dynamic value) {
    if (value == null) return null;

    // Trường hợp value là List (vd: roles: ['Admin', 'User'])
    if (value is List) {
      for (final item in value) {
        final s = item.toString().trim();
        if (isAdminRole(s)) return 'Admin'; // Trả về chuỗi 'Admin' thống nhất
      }
      // Nếu không có Admin, trả về phần tử đầu tiên nếu có
      if (value.isNotEmpty) {
        return value.first.toString();
      }
      return null;
    }

    final s = value.toString().trim();
    if (s.isEmpty) return null;

    // Trường hợp value là chuỗi ngăn cách bởi dấu câu (vd: "Admin,User")
    final separators = [',', ';', '|'];
    for (final sep in separators) {
      if (s.contains(sep)) {
        final parts = s
            .split(sep)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        
        // Ưu tiên tìm Admin trước
        for (final p in parts) {
          if (isAdminRole(p)) return 'Admin';
        }
        return parts.isNotEmpty ? parts.first : null;
      }
    }

    // Trường hợp chuỗi đơn
    if (isAdminRole(s)) return 'Admin';
    if (s.toLowerCase() == 'user') return 'User';

    return s;
  }
}
