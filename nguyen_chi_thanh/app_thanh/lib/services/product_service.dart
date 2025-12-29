import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_post.dart';
import '../config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:app_thanh/utils/auth_session.dart';

class ProductService {
  static String get baseUrl => "${Config_URL.baseUrl}ProductApi";

  // Hàm hỗ trợ để lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // GET: Fetch all products
  Future<List<ProductPost>> fetchProducts() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required - Vui lòng đăng nhập.');
    }
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => ProductPost.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền truy cập.');
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  // GET by ID: Fetch a single product
  Future<ProductPost> fetchProductById(int id) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required - Vui lòng đăng nhập.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return ProductPost.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền truy cập.');
    } else {
      throw Exception('Product not found: ${response.statusCode}');
    }
  }

  // SEARCH: Tìm kiếm sản phẩm theo tên (Lọc trực tiếp từ danh sách)
  Future<List<ProductPost>> searchProducts(String query) async {
    // Lấy toàn bộ danh sách về trước với token
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required - Vui lòng đăng nhập.');
    }
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<ProductPost> allProducts = data
          .map((item) => ProductPost.fromJson(item))
          .toList();

      return allProducts.where((product) {
        final nameLower = (product.name ?? "").toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower);
      }).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền truy cập.');
    } else {
      throw Exception('Failed to search products: ${response.statusCode}');
    }
  }

  // POST: Add new product (Yêu cầu quyền Admin)
  Future<bool> addProduct(ProductPost product) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required for adding products.');
    }
    if (!await AuthSession.isAdmin()) {
      throw Exception('Forbidden - Bạn không có quyền thêm sản phẩm.');
    }
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(product.toJson()..remove('id')),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền thêm sản phẩm.');
    } else {
      throw Exception('Failed to add product: ${response.statusCode}');
    }
  }

  // PUT: Update product (Yêu cầu quyền Admin)
  Future<bool> updateProduct(ProductPost product) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required for updating products.');
    }
    if (!await AuthSession.isAdmin()) {
      throw Exception('Forbidden - Bạn không có quyền cập nhật sản phẩm.');
    }
    final response = await http.put(
      Uri.parse('$baseUrl/${product.id}'),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền cập nhật sản phẩm.');
    } else {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
  }

  // DELETE: Delete product (Yêu cầu quyền Admin)
  Future<bool> deleteProduct(int id) async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required for deleting products.');
    }
    if (!await AuthSession.isAdmin()) {
      throw Exception('Forbidden - Bạn không có quyền xóa sản phẩm.');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Vui lòng đăng nhập lại.');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - Bạn không có quyền xóa sản phẩm.');
    } else {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }
}
