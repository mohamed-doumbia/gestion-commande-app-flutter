class VendorInfoModel {
  final int id;
  final String name;
  final String? shopName;
  final String? phone;
  final String? city;
  final String? district;

  VendorInfoModel({
    required this.id,
    required this.name,
    this.shopName,
    this.phone,
    this.city,
    this.district,
  });

  // Nom d'affichage (priorité au shopName)
  String get displayName => "Vendeur $name";

  // Localisation formatée
  String get location {
    if (city != null && city!.isNotEmpty) {
      return district != null ? '$city, $district' : city!;
    }
    return 'Non spécifié';
  }

  factory VendorInfoModel.fromMap(Map<String, dynamic> map) {
    return VendorInfoModel(
      id: map['id'] as int,
      name: map['name'] as String,
      shopName: map['shopName'] as String?,
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shopName': shopName,
      'phone': phone,
      'city': city,
      'district': district,
    };
  }
}