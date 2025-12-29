import 'package:flutter/material.dart';
import '../models/product_post.dart';
import '../services/product_service.dart';
import 'product_form_screen.dart';
import 'package:app_thanh/utils/auth_session.dart';

class FacebookFeedScreen extends StatefulWidget {
  const FacebookFeedScreen({super.key});

  @override
  State<FacebookFeedScreen> createState() => _FacebookFeedScreenState();
}

class _FacebookFeedScreenState extends State<FacebookFeedScreen> {
  final ProductService _productService = ProductService();
  late Future<List<ProductPost>> _postsFuture;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _postsFuture = _productService.fetchProducts();
  }

  Future<void> _loadRole() async {
    final isAdmin = await AuthSession.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  void _refresh() {
    setState(() {
      _postsFuture = _productService.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Facebook Feed',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<ProductPost>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bài đăng nào.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        post.name ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Vừa xong • 🌎'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (!_isAdmin) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bạn không có quyền thực hiện thao tác này.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          if (value == 'edit') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductFormScreen(product: post),
                              ),
                            );
                            if (result == true) _refresh();
                          } else if (value == 'delete') {
                            _confirmDelete(post.id!);
                          }
                        },
                        itemBuilder: (context) => _isAdmin
                            ? [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Chỉnh sửa'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Xóa'),
                                ),
                              ]
                            : const [],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(post.description ?? ''),
                    ),
                    if (post.image != null && post.image!.isNotEmpty)
                      Image.network(
                        post.image!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Giá: ${post.price} VND',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.thumb_up_alt_outlined, size: 20),
                              SizedBox(width: 5),
                              Text('Thích'),
                              SizedBox(width: 15),
                              Icon(Icons.comment_outlined, size: 20),
                              SizedBox(width: 5),
                              Text('Bình luận'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductFormScreen(),
                  ),
                );
                if (result == true) _refresh();
              },
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        content: const Text('Bạn có chắc chắn muốn xóa bài đăng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _productService.deleteProduct(id);
              if (success) {
                _refresh();
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Đã xóa')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
