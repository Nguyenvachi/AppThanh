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

  static bool isAdminRole(String? role) {
    if (role == null) return false;
    return role.trim().toLowerCase() == 'admin';
  }

  static String? extractRoleFromDecodedToken(Map<String, dynamic> decoded) {
    dynamic roleValue =
        decoded['role'] ??
        decoded['roles'] ??
        decoded['Role'] ??
        decoded['Roles'] ??
        decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

    final normalized = _normalizeRoleValue(roleValue);
    if (normalized != null) return normalized;

    // fallback: một số backend nhét role vào claim kiểu array/string khác
    for (final entry in decoded.entries) {
      if (!entry.key.toLowerCase().contains('role')) continue;
      final candidate = _normalizeRoleValue(entry.value);
      if (candidate != null) return candidate;
    }

    return null;
  }

  static String? _normalizeRoleValue(dynamic value) {
    if (value == null) return null;

    // roles: ['Admin', 'User']
    if (value is List) {
      for (final item in value) {
        final candidate = _normalizeRoleValue(item);
        if (candidate != null) {
          if (candidate.toLowerCase() == 'admin') return 'Admin';
        }
      }
      // không có Admin thì thử lấy User
      for (final item in value) {
        final s = item?.toString().trim();
        if (s == null || s.isEmpty) continue;
        if (s.toLowerCase() == 'user') return 'User';
      }
      return value.isNotEmpty ? value.first.toString() : null;
    }

    final s = value.toString().trim();
    if (s.isEmpty) return null;

    // roles: "Admin,User" hoặc "Admin;User"
    final separators = [',', ';', '|'];
    for (final sep in separators) {
      if (s.contains(sep)) {
        final parts = s
            .split(sep)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        for (final p in parts) {
          if (p.toLowerCase() == 'admin') return 'Admin';
        }
        for (final p in parts) {
          if (p.toLowerCase() == 'user') return 'User';
        }
        return parts.isNotEmpty ? parts.first : null;
      }
    }

    if (s.toLowerCase() == 'admin') return 'Admin';
    if (s.toLowerCase() == 'user') return 'User';

    return s;
  }
}
