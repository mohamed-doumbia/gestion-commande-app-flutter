class UserModel {
  final int? id;
  final String fullName;
  final String phone;
  final String? email;
  final String password;
  final String role;
  final String? shopName;
  final String? city;
  final String? district;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.password,
    required this.role,
    this.shopName,
    this.city,
    this.district,
    this.branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
      'shopName': shopName,
      'city': city,
      'district': district,
      'branchId': branchId, // ✅ CORRIGÉ : sans underscore
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['fullName'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      shopName: map['shopName'],
      city: map['city'],
      district: map['district'],
      branchId: map['branchId'] as String?, // ✅ CORRIGÉ : sans underscore
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? role,
    String? shopName,
    String? city,
    String? district,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      city: city ?? this.city,
      district: district ?? this.district,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, role: $role, branchId: $branchId)';
  }
}