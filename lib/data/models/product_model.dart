class ProductModel {
  final int? id;
  final int vendorId; // Pour savoir à qui appartient le produit
  final String name;
  final String category;
  final double price;
  final String? description;
  final int stockQuantity;

  ProductModel({
    this.id,
    required this.vendorId,
    required this.name,
    required this.category,
    required this.price,
    this.description,
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
      'stockQuantity': stockQuantity,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      vendorId: map['vendorId'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
      description: map['description'],
      stockQuantity: map['stockQuantity'],
    );
  }
}