/// ============================================
/// MODÈLE : PermissionRequestModel
/// ============================================
/// Description : Représente une demande de permission pour modifier/supprimer une transaction
/// Phase : Phase 4 - Gestion Employés
/// Un responsable de département doit demander permission à l'admin avant de modifier

enum RequestType {
  MODIFY_TRANSACTION,
  DELETE_TRANSACTION,
  MODIFY_EMPLOYEE,
  DELETE_EMPLOYEE,
  OTHER,
}

enum RequestStatus {
  PENDING,
  APPROVED,
  REJECTED,
}

class PermissionRequestModel {
  final String id;
  final String branchId; // ID de la succursale
  final String employeeId; // ID de l'employé qui fait la demande
  final String? transactionId; // ID de la transaction concernée (si applicable)
  final RequestType requestType; // Type de demande
  final String reason; // Raison de la demande
  final RequestStatus status; // Statut : PENDING, APPROVED, REJECTED
  final String? reviewedBy; // ID de l'admin qui a révisé
  final DateTime? reviewedAt; // Date de révision
  final DateTime createdAt; // Date de création de la demande

  PermissionRequestModel({
    required this.id,
    required this.branchId,
    required this.employeeId,
    this.transactionId,
    required this.requestType,
    required this.reason,
    this.status = RequestStatus.PENDING,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  /// ============================================
  /// CONVERSION VERS MAP (pour SQLite)
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'employee_id': employeeId,
      'transaction_id': transactionId,
      'request_type': requestType.name, // MODIFY_TRANSACTION, etc.
      'reason': reason,
      'status': status.name, // PENDING, APPROVED, REJECTED
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP (depuis SQLite)
  /// ============================================
  factory PermissionRequestModel.fromMap(Map<String, dynamic> map) {
    return PermissionRequestModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      employeeId: map['employee_id'] as String,
      transactionId: map['transaction_id'] as String?,
      requestType: RequestType.values.firstWhere(
        (e) => e.name == map['request_type'],
        orElse: () => RequestType.OTHER,
      ),
      reason: map['reason'] as String,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RequestStatus.PENDING,
      ),
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  PermissionRequestModel copyWith({
    String? id,
    String? branchId,
    String? employeeId,
    String? transactionId,
    RequestType? requestType,
    String? reason,
    RequestStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) {
    return PermissionRequestModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      employeeId: employeeId ?? this.employeeId,
      transactionId: transactionId ?? this.transactionId,
      requestType: requestType ?? this.requestType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// ============================================
  /// GETTERS UTILITAIRES
  /// ============================================
  String get displayType {
    switch (requestType) {
      case RequestType.MODIFY_TRANSACTION:
        return 'Modifier Transaction';
      case RequestType.DELETE_TRANSACTION:
        return 'Supprimer Transaction';
      case RequestType.MODIFY_EMPLOYEE:
        return 'Modifier Employé';
      case RequestType.DELETE_EMPLOYEE:
        return 'Supprimer Employé';
      case RequestType.OTHER:
        return 'Autre';
    }
  }

  String get displayStatus {
    switch (status) {
      case RequestStatus.PENDING:
        return 'En attente';
      case RequestStatus.APPROVED:
        return 'Approuvé';
      case RequestStatus.REJECTED:
        return 'Rejeté';
    }
  }

  bool get isPending => status == RequestStatus.PENDING;
  bool get isApproved => status == RequestStatus.APPROVED;
  bool get isRejected => status == RequestStatus.REJECTED;
}




