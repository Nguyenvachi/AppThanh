import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../config/config_url.dart';

class CategoryService {
  static String get baseUrl => "${Config_URL.baseUrl}CategoryApi";

  // Hàm hỗ trợ để lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // GET: Lấy danh sách danh mục
  Future<List<Category>> fetchCategories() async {
    String? token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  // GET: Lấy chi tiết danh mục theo ID
  Future<Category> fetchCategoryById(int id) async {
    String? token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load category: ${response.statusCode}');
    }
  }

  // POST: Thêm danh mục mới (Admin)
  Future<bool> addCategory(Category category) async {
    String? token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "name": category.name,
        "description": category.description,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to add category: ${response.statusCode}');
    }
  }

  // PUT: Cập nhật danh mục (Admin)
  Future<bool> updateCategory(Category category) async {
    String? token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.put(
      Uri.parse('$baseUrl/${category.id}'),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "id": category.id,
        "name": category.name,
        "description": category.description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to update category: ${response.statusCode}');
    }
  }

  // DELETE: Xóa danh mục (Admin)
  Future<bool> deleteCategory(int id) async {
    String? token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
