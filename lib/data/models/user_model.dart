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
  });

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
    );
  }
}