import 'dart:convert';

class ProductModel {
  final int? id;
  final int vendorId;
  final String name;
  final String category;
  final double price;
  final String? description;
  final List<String> images;
  final int stockQuantity;

  ProductModel({
    this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.images = const [],
    this.stockQuantity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'images': jsonEncode(images),
      'stockQuantity': stockQuantity,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    List<String> imagesList = [];
    if (map['images'] != null && map['images'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['images']);
        if (decoded is List) {
          imagesList = List<String>.from(decoded);
        }
      } catch (e) {
        print('Erreur décodage images: $e');
      }
    }

    return ProductModel(
      id: map['id'],
      vendorId: map['vendorId'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
      description: map['description'],
      images: imagesList,
      stockQuantity: map['stockQuantity'] ?? 0,
    );
  }

  bool get hasImages => images.isNotEmpty;
  String? get firstImage => images.isNotEmpty ? images.first : null;
}