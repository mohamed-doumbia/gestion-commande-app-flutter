class UserModel {
  final int? id;
  final String fullName;
  final String phone;
  final String? email;
  final String password;
  final String role; // 'vendor' ou 'client'
  final String? shopName; // Null si c'est un client

  UserModel({
    this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.password,
    required this.role,
    this.shopName,
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
    );
  }
}