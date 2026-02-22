/// Modèle Succursale (Branch)
class BranchModel {
  final String id;
  final String vendorId; // Propriétaire (UUID)
  final String name; // "Magasin Cocody"
  final String code; // "COC-001" (unique)

  // Localisation
  final String country; // "CI"
  final String city; // "Abidjan"
  final String district; // "Cocody"
  final String? address; // Adresse complète (optionnelle)
  final double? latitude;
  final double? longitude;

  // Infos contact
  final String? phone; // Téléphone (optionnel)
  final String? email;
  final String? managerId; // Manager responsable (peut être null au début)

  // Financier
  final double monthlyRent; // Loyer mensuel
  final double monthlyCharges; // Charges (eau, électricité)

  // Status
  final bool isActive;
  final DateTime openingDate;
  final DateTime? closingDate;

  // Horaires (JSON string pour SQLite)
  final String openingHours; // '{"lundi":"8h-18h","mardi":"8h-18h"}'

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.code,
    required this.country,
    required this.city,
    required this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.managerId,
    this.monthlyRent = 0.0,
    this.monthlyCharges = 0.0,
    this.isActive = true,
    required this.openingDate,
    this.closingDate,
    this.openingHours = '{}',
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters utiles
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return '$address, $district, $city, $country';
    }
    return '$district, $city, $country';
  }

  bool get hasLocation => latitude != null && longitude != null;

  double get monthlyOperatingCost => monthlyRent + monthlyCharges;

  // ============================================
  // CONVERSION VERS MAP (pour SQLite)
  // ============================================
  // Description : Convertit le modèle en Map pour insertion/mise à jour en base
  // Note : Les champs financiers (monthly_rent, monthly_charges) ne sont plus
  //        sauvegardés ici. Ils seront gérés dans la table branch_transactions (Phase 3)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'code': code,
      'country': country,
      'city': city,
      'district': district,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'manager_id': managerId,
      // monthly_rent et monthly_charges retirés - seront dans branch_transactions (Phase 3)
      'is_active': isActive ? 1 : 0,
      'opening_date': openingDate.toIso8601String(),
      'closing_date': closingDate?.toIso8601String(),
      'opening_hours': openingHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ============================================
  // CRÉATION DEPUIS MAP (depuis SQLite)
  // ============================================
  // Description : Crée une instance BranchModel depuis les données de la base
  // Note : Les champs financiers (monthly_rent, monthly_charges) peuvent ne pas
  //        exister dans la nouvelle structure. On utilise 0.0 par défaut pour compatibilité.
  factory BranchModel.fromMap(Map<String, dynamic> map) {
    return BranchModel(
      id: map['id'] as String,
      vendorId: map['vendor_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      country: map['country'] as String,
      city: map['city'] as String,
      district: map['district'] as String,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      managerId: map['manager_id'] as String?,
      // Compatibilité : Si monthly_rent/monthly_charges n'existent pas, utiliser 0.0
      // Ces valeurs seront gérées dans branch_transactions (Phase 3)
      monthlyRent: (map['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      monthlyCharges: (map['monthly_charges'] as num?)?.toDouble() ?? 0.0,
      isActive: map['is_active'] == 1,
      openingDate: DateTime.parse(map['opening_date'] as String),
      closingDate: map['closing_date'] != null
          ? DateTime.parse(map['closing_date'] as String)
          : null,
      openingHours: map['opening_hours'] as String? ?? '{}',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // CopyWith pour modifications
  BranchModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? code,
    String? country,
    String? city,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? managerId,
    double? monthlyRent,
    double? monthlyCharges,
    bool? isActive,
    DateTime? openingDate,
    DateTime? closingDate,
    String? openingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      code: code ?? this.code,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      managerId: managerId ?? this.managerId,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      monthlyCharges: monthlyCharges ?? this.monthlyCharges,
      isActive: isActive ?? this.isActive,
      openingDate: openingDate ?? this.openingDate,
      closingDate: closingDate ?? this.closingDate,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BranchModel(id: $id, name: $name, code: $code, city: $city, isActive: $isActive)';
  }
}