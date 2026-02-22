/// Modèle Employé (Version complète - Phase 2)
class EmployeeModel {
  final String id;
  final String branchId;
  final String vendorId; // UUID (TEXT)
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? photo; // 🆕 Photo profil
  final String? idCard; // 🆕 Photo CNI

  // Poste
  final String role; // "manager", "vendeur", "caissier" (ancien champ, gardé pour compatibilité)
  final String? roleId; // 🆕 Phase 4 : ID du rôle dans la table roles
  final String? departmentCode; // 🆕 Phase 4 : Code d'accès unique par département
  final String? accessCode; // 🆕 Code d'accès unique de 4 chiffres pour authentification
  final String contractType; // 🆕 "CDI", "CDD", "Stage", "Freelance"
  final String permissions; // JSON: ["vente","stock_read"]

  // Salaire
  final double baseSalary; // 🆕 Salaire de base (alias pour salary dans BDD)
  final double? salary; // 🆕 Phase 4 : Salaire (peut être différent de baseSalary)
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
  final bool isDeleted; // 🆕 Phase 4 : Soft delete
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
    this.roleId,
    this.departmentCode,
    this.accessCode,
    this.contractType = 'CDI',
    this.permissions = '[]',
    this.baseSalary = 0.0,
    this.salary,
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
    this.isDeleted = false,
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
      'role_id': roleId,
      'department_code': departmentCode,
      'access_code': accessCode,
      'contractType': contractType,
      'contract_type': contractType, // Pour compatibilité avec BDD
      'permissions': permissions,
      'baseSalary': baseSalary,
      'salary': salary ?? baseSalary, // Utiliser salary si défini, sinon baseSalary
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
      'is_deleted': isDeleted ? 1 : 0,
      'hireDate': hireDate.toIso8601String(),
      'terminationDate': terminationDate?.toIso8601String(),
      'emergencyContact': emergencyContact,
      'emergency_contact': emergencyContact, // Pour compatibilité avec BDD
      'emergencyPhone': emergencyPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String,
      branchId: map['branchId'] as String,
      vendorId: map['vendorId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      photo: map['photo'] as String?,
      idCard: map['idCard'] as String?,
      role: map['role'] as String,
      roleId: map['role_id'] as String?,
      departmentCode: map['department_code'] as String?,
      accessCode: map['access_code'] as String?,
      contractType: map['contractType'] as String? ?? map['contract_type'] as String? ?? 'CDI',
      permissions: map['permissions'] as String? ?? '[]',
      baseSalary: (map['baseSalary'] as num?)?.toDouble() ?? 0.0,
      salary: (map['salary'] as num?)?.toDouble(),
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
      isActive: (map['isActive'] as int? ?? 1) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      hireDate: DateTime.parse(map['hireDate'] as String),
      terminationDate: map['terminationDate'] != null
          ? DateTime.parse(map['terminationDate'] as String)
          : null,
      emergencyContact: map['emergencyContact'] as String? ?? map['emergency_contact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? branchId,
    String? vendorId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photo,
    String? idCard,
    String? role,
    String? roleId,
    String? departmentCode,
    String? accessCode,
    String? contractType,
    String? permissions,
    double? baseSalary,
    double? salary,
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
    bool? isDeleted,
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
      roleId: roleId ?? this.roleId,
      departmentCode: departmentCode ?? this.departmentCode,
      accessCode: accessCode ?? this.accessCode,
      contractType: contractType ?? this.contractType,
      permissions: permissions ?? this.permissions,
      baseSalary: baseSalary ?? this.baseSalary,
      salary: salary ?? this.salary,
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
      isDeleted: isDeleted ?? this.isDeleted,
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