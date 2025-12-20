/// Modèle Employé (Version complète - Phase 2)
class EmployeeModel {
  final String id;
  final String branchId;
  final int vendorId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? photo; // 🆕 Photo profil
  final String? idCard; // 🆕 Photo CNI

  // Poste
  final String role; // "manager", "vendeur", "caissier"
  final String contractType; // 🆕 "CDI", "CDD", "Stage", "Freelance"
  final String permissions; // JSON: ["vente","stock_read"]

  // Salaire
  final double baseSalary; // 🆕 Salaire de base
  final String paymentFrequency; // 🆕 "monthly", "weekly", "daily"
  final String? paymentMethod; // 🆕 "cash", "mobile_money", "bank"
  final double? commissionRate; // 🆕 % commission (ex: 0.02 = 2%)
  final double? bonus; // 🆕 Prime fixe

  // Congés
  final int annualLeaveDays; // 🆕 Jours congés annuels (22)
  final int usedLeaveDays; // 🆕 Jours utilisés
  final int sickLeaveDays; // 🆕 Jours maladie utilisés

  // Performance
  final int totalSales; // 🆕 Total ventes
  final double totalRevenue; // 🆕 CA généré
  final double? customerRating; // 🆕 Note clients

  // Status
  final bool isActive;
  final DateTime hireDate;
  final DateTime? terminationDate;

  // Contacts urgence
  final String? emergencyContact; // 🆕 Nom contact
  final String? emergencyPhone; // 🆕 Téléphone contact

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.branchId,
    required this.vendorId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.photo,
    this.idCard,
    required this.role,
    this.contractType = 'CDI',
    this.permissions = '[]',
    this.baseSalary = 0.0,
    this.paymentFrequency = 'monthly',
    this.paymentMethod,
    this.commissionRate,
    this.bonus,
    this.annualLeaveDays = 30,
    this.usedLeaveDays = 0,
    this.sickLeaveDays = 0,
    this.totalSales = 0,
    this.totalRevenue = 0.0,
    this.customerRating,
    this.isActive = true,
    required this.hireDate,
    this.terminationDate,
    this.emergencyContact,
    this.emergencyPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters
  String get fullName => '$firstName $lastName';

  String get roleLabel {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'vendeur':
        return 'Vendeur';
      case 'caissier':
        return 'Caissier';
      default:
        return role;
    }
  }

  int get remainingLeaveDays => annualLeaveDays - usedLeaveDays;

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchId': branchId,
      'vendorId': vendorId,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'photo': photo,
      'idCard': idCard,
      'role': role,
      'contractType': contractType,
      'permissions': permissions,
      'baseSalary': baseSalary,
      'paymentFrequency': paymentFrequency,
      'paymentMethod': paymentMethod,
      'commissionRate': commissionRate,
      'bonus': bonus,
      'annualLeaveDays': annualLeaveDays,
      'usedLeaveDays': usedLeaveDays,
      'sickLeaveDays': sickLeaveDays,
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'customerRating': customerRating,
      'isActive': isActive ? 1 : 0,
      'hireDate': hireDate.toIso8601String(),
      'terminationDate': terminationDate?.toIso8601String(),
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String,
      branchId: map['branchId'] as String,
      vendorId: map['vendorId'] as int,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      photo: map['photo'] as String?,
      idCard: map['idCard'] as String?,
      role: map['role'] as String,
      contractType: map['contractType'] as String? ?? 'CDI',
      permissions: map['permissions'] as String? ?? '[]',
      baseSalary: (map['baseSalary'] as num?)?.toDouble() ?? 0.0,
      paymentFrequency: map['paymentFrequency'] as String? ?? 'monthly',
      paymentMethod: map['paymentMethod'] as String?,
      commissionRate: (map['commissionRate'] as num?)?.toDouble(),
      bonus: (map['bonus'] as num?)?.toDouble(),
      annualLeaveDays: map['annualLeaveDays'] as int? ?? 22,
      usedLeaveDays: map['usedLeaveDays'] as int? ?? 0,
      sickLeaveDays: map['sickLeaveDays'] as int? ?? 0,
      totalSales: map['totalSales'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      customerRating: (map['customerRating'] as num?)?.toDouble(),
      isActive: map['isActive'] == 1,
      hireDate: DateTime.parse(map['hireDate'] as String),
      terminationDate: map['terminationDate'] != null
          ? DateTime.parse(map['terminationDate'] as String)
          : null,
      emergencyContact: map['emergencyContact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? branchId,
    int? vendorId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photo,
    String? idCard,
    String? role,
    String? contractType,
    String? permissions,
    double? baseSalary,
    String? paymentFrequency,
    String? paymentMethod,
    double? commissionRate,
    double? bonus,
    int? annualLeaveDays,
    int? usedLeaveDays,
    int? sickLeaveDays,
    int? totalSales,
    double? totalRevenue,
    double? customerRating,
    bool? isActive,
    DateTime? hireDate,
    DateTime? terminationDate,
    String? emergencyContact,
    String? emergencyPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      vendorId: vendorId ?? this.vendorId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      idCard: idCard ?? this.idCard,
      role: role ?? this.role,
      contractType: contractType ?? this.contractType,
      permissions: permissions ?? this.permissions,
      baseSalary: baseSalary ?? this.baseSalary,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      commissionRate: commissionRate ?? this.commissionRate,
      bonus: bonus ?? this.bonus,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      usedLeaveDays: usedLeaveDays ?? this.usedLeaveDays,
      sickLeaveDays: sickLeaveDays ?? this.sickLeaveDays,
      totalSales: totalSales ?? this.totalSales,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      customerRating: customerRating ?? this.customerRating,
      isActive: isActive ?? this.isActive,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'EmployeeModel(id: $id, name: $fullName, role: $role, branch: $branchId)';
  }
}