import 'package:flutter/material.dart';
import '../models/product_post.dart';
import '../services/product_service.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';
import 'package:app_thanh/utils/auth_session.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ProductService _productService = ProductService();
  late Future<List<ProductPost>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _refreshProducts();
  }

  Future<void> _loadRole() async {
    final isAdmin = await AuthSession.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  void _refreshProducts() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _productsFuture = _productService.fetchProducts();
      } else {
        _productsFuture = _productService.searchProducts(
          _searchController.text,
        );
      }
    });
  }

  void _deleteProduct(int id) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa sản phẩm.')),
      );
      return;
    }
    bool success = await _productService.deleteProduct(id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa sản phẩm thành công')));
      _refreshProducts();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa sản phẩm thất bại')));
    }
  }

  void _searchById() {
    showDialog(
      context: context,
      builder: (context) {
        final idController = TextEditingController();
        return AlertDialog(
          title: const Text('Tìm sản phẩm theo ID'),
          content: TextField(
            controller: idController,
            decoration: const InputDecoration(hintText: 'Nhập mã ID sản phẩm'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final id = int.tryParse(idController.text);
                if (id != null) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(productId: id),
                    ),
                  );
                }
              },
              child: const Text('Tìm kiếm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace - Sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_sharp, color: Colors.blue),
            tooltip: 'Tìm theo ID',
            onPressed: _searchById,
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
                if (result == true) _refreshProducts();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshProducts();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) => _refreshProducts(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductPost>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy sản phẩm nào.'),
                  );
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: post.image != null && post.image!.isNotEmpty
                            ? Image.network(
                                post.image!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image),
                        title: Text(post.name ?? 'Không tên'),
                        subtitle: Text(
                          'ID: ${post.id} - ${post.price ?? 0} VND',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductFormScreen(product: post),
                                    ),
                                  );
                                  if (result == true) _refreshProducts();
                                },
                              ),
                            if (_isAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _showDeleteDialog(post.id!),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(productId: post.id!),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
