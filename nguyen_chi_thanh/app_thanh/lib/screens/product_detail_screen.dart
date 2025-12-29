import 'package:flutter/material.dart';
import '../models/product_post.dart';
import '../services/product_service.dart';
import '../services/category_service.dart'; // Thêm service category
import '../models/category.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  late Future<ProductPost> _productFuture;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _productFuture = _productService.fetchProductById(widget.productId);
  }

  // Hàm tải tên danh mục
  Future<void> _loadCategoryName(int categoryId) async {
    try {
      Category category = await _categoryService.fetchCategoryById(categoryId);
      if (mounted) {
        setState(() {
          _categoryName = category.name;
        });
      }
    } catch (e) {
      // Bỏ qua lỗi nếu không tải được danh mục
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: FutureBuilder<ProductPost>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy sản phẩm.'));
          }

          final product = snapshot.data!;
          
          // Nếu có categoryId và chưa có tên danh mục, thử tải tên
          if (product.categoryId != null && _categoryName == null) {
            _loadCategoryName(product.categoryId!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.image != null && product.image!.isNotEmpty)
                  Center(
                    child: Image.network(
                      product.image!,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  product.name ?? 'Không tên',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID: ${product.id}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                // Hiển thị danh mục
                if (product.categoryId != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       'Danh mục: ${_categoryName ?? product.categoryId}', // Hiển thị tên hoặc ID
                       style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                     ),
                   ),
                const SizedBox(height: 10),
                Text(
                  'Giá: ${product.price} VND',
                  style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mô tả:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description ?? 'Không có mô tả',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
