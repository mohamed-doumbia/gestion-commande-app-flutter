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
  final String? branchId;
  final DateTime createdAt; // 🆕 AJOUTÉ
  final DateTime updatedAt; // 🆕 AJOUTÉ

  ProductModel({
    this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.images = const [],
    this.stockQuantity = 0,
    this.branchId,
    DateTime? createdAt, // 🆕 AJOUTÉ
    DateTime? updatedAt, // 🆕 AJOUTÉ
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'branchId': branchId,
      'created_at': createdAt.toIso8601String(), // 🆕 AJOUTÉ
      'updated_at': updatedAt.toIso8601String(), // 🆕 AJOUTÉ
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
      branchId: map['branchId'] as String?,
      createdAt: map['created_at'] != null // 🆕 AJOUTÉ
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null // 🆕 AJOUTÉ
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  ProductModel copyWith({
    int? id,
    int? vendorId,
    String? name,
    String? category,
    double? price,
    String? description,
    List<String>? images,
    int? stockQuantity,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      images: images ?? this.images,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Toujours mise à jour
    );
  }

  bool get hasImages => images.isNotEmpty;
  String? get firstImage => images.isNotEmpty ? images.first : null;

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, branchId: $branchId)';
  }
}