/// ============================================
/// MODÈLE : BranchSalesSummaryModel
/// ============================================
/// Description : Résumé des ventes par succursale pour les KPIs
/// Phase : Département Marketing - Onglet 1

class BranchSalesSummaryModel {
  final String branchId;
  final String branchName;
  final String city;
  final String district;
  final int totalProducts; // Nombre de produits différents
  final int totalStock; // Stock total
  final int lowStockCount; // Nombre de produits en stock faible
  final int outOfStockCount; // Nombre de produits en rupture
  final int soldQuantity; // Quantité vendue (période)
  final double revenue; // Chiffre d'affaires (période)
  final double growthRate; // Taux de croissance vs période précédente (%)
  final DateTime lastUpdated;

  BranchSalesSummaryModel({
    required this.branchId,
    required this.branchName,
    required this.city,
    required this.district,
    required this.totalProducts,
    required this.totalStock,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.soldQuantity = 0,
    this.revenue = 0.0,
    this.growthRate = 0.0,
    required this.lastUpdated,
  });

  /// ============================================
  /// CONVERSION VERS MAP
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'branch_id': branchId,
      'branch_name': branchName,
      'city': city,
      'district': district,
      'total_products': totalProducts,
      'total_stock': totalStock,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'sold_quantity': soldQuantity,
      'revenue': revenue,
      'growth_rate': growthRate,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP
  /// ============================================
  factory BranchSalesSummaryModel.fromMap(Map<String, dynamic> map) {
    return BranchSalesSummaryModel(
      branchId: map['branch_id'] as String,
      branchName: map['branch_name'] as String,
      city: map['city'] as String,
      district: map['district'] as String,
      totalProducts: map['total_products'] as int,
      totalStock: map['total_stock'] as int,
      lowStockCount: map['low_stock_count'] as int? ?? 0,
      outOfStockCount: map['out_of_stock_count'] as int? ?? 0,
      soldQuantity: map['sold_quantity'] as int? ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  /// ============================================
  /// GETTERS UTILITAIRES
  /// ============================================
  String get location => '$district, $city';
  
  bool get hasAlerts => lowStockCount > 0 || outOfStockCount > 0;
  
  String get stockStatus {
    if (outOfStockCount > 0) return 'Rupture';
    if (lowStockCount > 0) return 'Stock faible';
    return 'Normal';
  }
}

