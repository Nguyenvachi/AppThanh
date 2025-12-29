import 'dart:convert';

class ProductPost {
  int? id;
  String? name;
  double? price;
  String? image;
  String? description;
  int? categoryId; // Thêm thuộc tính categoryId

  ProductPost({
    this.id,
    this.name,
    this.price,
    this.image,
    this.description,
    this.categoryId,
  });

  factory ProductPost.fromJson(Map<String, dynamic> json) {
    return ProductPost(
      id: json["id"],
      name: json["name"],
      price: json["price"]?.toDouble(),
      image: json["image"],
      description: json["description"],
      categoryId: json["categoryId"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "price": price,
    "image": image,
    "description": description,
    "categoryId": categoryId,
  };
}
