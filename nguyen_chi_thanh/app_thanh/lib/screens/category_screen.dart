import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product_post.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import 'package:app_thanh/utils/auth_session.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  late Future<List<Category>> _categories;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _guardAdmin();
    _refreshCategories();
  }

  Future<void> _guardAdmin() async {
    final isAdmin = await AuthSession.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn không có quyền quản lý danh mục.')),
        );
        Navigator.pop(context);
      });
    }
  }

  Future<void> _detachProductsFromCategory(int categoryId) async {
    // Khi xóa danh mục: các sản phẩm thuộc danh mục đó sẽ trở về categoryId = null
    final products = await _productService.fetchProducts();
    final affected = products.where((p) => p.categoryId == categoryId).toList();
    for (final p in affected) {
      final updated = ProductPost(
        id: p.id,
        name: p.name,
        price: p.price,
        image: p.image,
        description: p.description,
        categoryId: null,
      );
      await _productService.updateProduct(updated);
    }
  }

  void _refreshCategories() {
    setState(() {
      _categories = _categoryService.fetchCategories();
    });
  }

  void _showCategoryDialog({Category? category}) {
    if (!_isAdmin) return;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final newCategory = Category(
                id: category?.id ?? 0,
                name: nameController.text,
                description: descriptionController.text,
              );

              bool success;
              try {
                if (category == null) {
                  success = await _categoryService.addCategory(newCategory);
                } else {
                  success = await _categoryService.updateCategory(newCategory);
                }

                if (success && mounted) {
                  Navigator.pop(context);
                  _refreshCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        category == null
                            ? 'Thêm thành công'
                            : 'Cập nhật thành công',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    if (!_isAdmin) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa danh mục này? Các sản phẩm thuộc danh mục này sẽ không thuộc danh mục nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // Bước 1: Gỡ danh mục khỏi các sản phẩm liên quan
                await _detachProductsFromCategory(id);

                // Bước 2: Xóa danh mục
                bool success = await _categoryService.deleteCategory(id);
                if (success && mounted) {
                  Navigator.pop(context);
                  _refreshCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa thành công')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Danh Mục')),
      body: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(category.description ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showCategoryDialog(category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(category.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
