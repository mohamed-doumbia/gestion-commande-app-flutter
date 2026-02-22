class VendorInfoModel {
  final String id; // UUID (TEXT)
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

  // Nom d'affichage (priorité au shopName avec ville entre parenthèses)
  String get displayName {
    if (shopName != null && shopName!.isNotEmpty) {
      // Si on a un nom de magasin et une ville, afficher "Magasin (Ville)"
      if (city != null && city!.isNotEmpty) {
        return "$shopName ($city)";
      }
      // Si on a seulement le nom du magasin
      return shopName!;
    }
    // Sinon, afficher "Vendeur Nom"
    return "Vendeur $name";
  }

  // Localisation formatée
  String get location {
    if (city != null && city!.isNotEmpty) {
      return district != null ? '$city, $district' : city!;
    }
    return 'Non spécifié';
  }

  factory VendorInfoModel.fromMap(Map<String, dynamic> map) {
    return VendorInfoModel(
      id: map['id'] as String,
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