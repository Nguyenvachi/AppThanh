import 'package:flutter/material.dart';
import '../models/product_post.dart';
import '../services/product_service.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import 'package:app_thanh/utils/auth_session.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductPost? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  final ProductService _productService = ProductService();

  // Thêm biến để quản lý danh mục
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _guardAdmin();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price?.toString() ?? '',
    );
    _imageController = TextEditingController(text: widget.product?.image ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );

    // Khởi tạo giá trị categoryId nếu đang sửa sản phẩm
    _selectedCategoryId = widget.product?.categoryId;

    // Tải danh sách danh mục
    _fetchCategories();
  }

  Future<void> _guardAdmin() async {
    final isAdmin = await AuthSession.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền thêm/sửa sản phẩm.'),
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  // Hàm lấy danh sách danh mục
  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh mục: $e')));
      }
    }
  }

  void _saveProduct() async {
    if (!_isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền thêm/sửa sản phẩm.'),
          ),
        );
      }
      return;
    }
    if (_formKey.currentState!.validate()) {
      final product = ProductPost(
        id: widget.product?.id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        image: _imageController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId, // Thêm categoryId vào đối tượng
      );

      bool success;
      if (widget.product == null) {
        success = await _productService.addProduct(product);
      } else {
        success = await _productService.updateProduct(product);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product == null
                    ? 'Thêm thành công'
                    : 'Cập nhật thành công',
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu sản phẩm')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập giá' : null,
              ),

              // Thêm Dropdown chọn danh mục
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Danh mục sản phẩm',
                ),
                items: _categories.map((Category category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
                validator: (value) =>
                    null, // Danh mục có thể để trống hoặc bắt buộc tùy logic
                hint: const Text("Chọn danh mục"),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập URL ảnh' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveProduct, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }
}
