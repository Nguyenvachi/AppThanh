import 'dart:convert';
import '../services/auth_service.dart';
import 'package:app_thanh/services/api_client.dart'; // File này sẽ tạo ở bước 5, hiện tại sẽ báo lỗi đỏ
import 'package:app_thanh/utils/auth_session.dart';

class Auth {
  static final AuthService _authService = AuthService();
  static final ApiClient _apiClient = ApiClient();

  // Đăng nhập
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    var result = await _authService.login(username, password);
    if (result['success'] == true && result['decodedToken'] != null) {
      final decoded = (result['decodedToken'] as Map).cast<String, dynamic>();
      final role = AuthSession.extractRoleFromDecodedToken(decoded) ?? 'User';
      result['role'] = role;
      // cache role để UI phân quyền nhanh
      await AuthSession.saveRole(role);
    }
    return result; // returns a map with {success: bool, token: string?, role: string?, message: string?}
  }

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String initials,
    required String role,
  }) async {
    // Tạo body để gửi lên API
    Map<String, dynamic> body = {
      "username": username,
      "email": email,
      "password": password,
      "initials": initials,
      "role": role,
    };

    // Gọi API đăng ký thông qua ApiClient
    try {
      var response = await _apiClient.post('Authenticate/register', body: body);

      // Xử lý kết quả từ API
      if (response.statusCode == 200) {
        // Chuyển đổi body JSON từ API thành Map
        var result = jsonDecode(response.body);
        return result;
      } else {
        return {
          'success': false,
          'message': 'Đăng ký thất bại, vui lòng thử lại.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
