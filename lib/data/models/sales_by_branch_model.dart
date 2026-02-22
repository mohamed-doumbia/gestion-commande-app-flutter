/// ============================================
/// MODÈLE : SalesByBranchModel
/// ============================================
/// Description : Représente les ventes et stocks par succursale
/// Phase : Département Marketing - Onglet 1

class SalesByBranchModel {
  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final String category;
  final int quantity; // Quantité en stock dans cette succursale
  final int soldQuantity; // Quantité vendue (période donnée)
  final double revenue; // Chiffre d'affaires généré
  final String city; // Ville de la succursale
  final String district; // Quartier de la succursale
  final DateTime lastUpdated;
  final DateTime? periodStart; // Début de la période analysée
  final DateTime? periodEnd; // Fin de la période analysée

  SalesByBranchModel({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    this.soldQuantity = 0,
    this.revenue = 0.0,
    required this.city,
    required this.district,
    required this.lastUpdated,
    this.periodStart,
    this.periodEnd,
  });

  /// ============================================
  /// CONVERSION VERS MAP (pour SQLite)
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'quantity': quantity,
      'sold_quantity': soldQuantity,
      'revenue': revenue,
      'city': city,
      'district': district,
      'last_updated': lastUpdated.toIso8601String(),
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP (depuis SQLite)
  /// ============================================
  factory SalesByBranchModel.fromMap(Map<String, dynamic> map) {
    return SalesByBranchModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      soldQuantity: map['sold_quantity'] as int? ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      city: map['city'] as String,
      district: map['district'] as String,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      periodStart: map['period_start'] != null
          ? DateTime.parse(map['period_start'] as String)
          : null,
      periodEnd: map['period_end'] != null
          ? DateTime.parse(map['period_end'] as String)
          : null,
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  SalesByBranchModel copyWith({
    String? id,
    String? branchId,
    String? productId,
    String? productName,
    String? category,
    int? quantity,
    int? soldQuantity,
    double? revenue,
    String? city,
    String? district,
    DateTime? lastUpdated,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return SalesByBranchModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      revenue: revenue ?? this.revenue,
      city: city ?? this.city,
      district: district ?? this.district,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }

  /// ============================================
  /// GETTERS UTILITAIRES
  /// ============================================
  String get location => '$district, $city';
  
  bool get isLowStock => quantity <= 5 && quantity > 0;
  bool get isOutOfStock => quantity == 0;
  
  double get averagePrice => soldQuantity > 0 ? revenue / soldQuantity : 0.0;
}

