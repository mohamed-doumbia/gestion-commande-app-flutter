/// ============================================
/// MODÈLE : RoleModel
/// ============================================
/// Description : Représente un rôle dans une succursale
/// Phase : Phase 4 - Gestion Employés
/// Un rôle est spécifique à une succursale et définit les permissions d'un département

class RoleModel {
  final String id;
  final String branchId; // ID de la succursale
  final String name; // Nom du rôle (ex: "Responsable Comptable")
  final String department; // Département (ex: "COMPTABILITE", "RH", "VENTE")
  final String? departmentCode; // 🆕 Code d'accès unique du département (généré automatiquement)
  final List<String>? permissions; // Liste des permissions (JSON array)
  final String createdBy; // ID de l'admin qui a créé ce rôle
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  RoleModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.department,
    this.departmentCode,
    this.permissions,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// ============================================
  /// CONVERSION VERS MAP (pour SQLite)
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'department': department,
      'department_code': departmentCode, // 🆕 Code d'accès département
      'permissions': permissions?.join(','),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP (depuis SQLite)
  /// ============================================
  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      name: map['name'] as String,
      department: map['department'] as String,
      departmentCode: map['department_code'] as String?, // 🆕 Code d'accès département
      permissions: map['permissions'] != null
          ? (map['permissions'] as String).split(',').where((p) => p.isNotEmpty).toList()
          : null,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  RoleModel copyWith({
    String? id,
    String? branchId,
    String? name,
    String? department,
    String? departmentCode,
    List<String>? permissions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return RoleModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      department: department ?? this.department,
      departmentCode: departmentCode ?? this.departmentCode,
      permissions: permissions ?? this.permissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// ============================================
  /// GETTERS UTILITAIRES
  /// ============================================
  String get displayName => name;
  
  bool hasPermission(String permission) {
    return permissions?.contains(permission) ?? false;
  }
}

