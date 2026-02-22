/// ============================================
/// MODÈLE : BranchTransactionModel
/// ============================================
/// Description : Représente une transaction financière d'une succursale
/// Phase : Phase 3 - Comptabilité
/// Types : ENTRY (Entrée), EXIT (Sortie), EXPENSE (Dépense)
/// Catégories : RENT, CHARGES, SALARY, TRANSPORT, MARKETING, OTHER

class BranchTransactionModel {
  final String id;
  final String branchId; // ID de la succursale
  final TransactionType type; // ENTRY, EXIT, EXPENSE
  final TransactionCategory category; // RENT, CHARGES, SALARY, etc.
  final double amount; // Montant en FCFA
  final String? description; // Description/Notes
  final DateTime date; // Date de la transaction
  final String? attachment; // Chemin vers la photo facture/reçu (optionnel)
  final String createdBy; // ID de l'utilisateur qui a créé la transaction
  final DateTime createdAt; // Date de création de l'enregistrement
  final DateTime updatedAt; // Date de dernière modification

  BranchTransactionModel({
    required this.id,
    required this.branchId,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    required this.date,
    this.attachment,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ============================================
  /// CONVERSION VERS MAP (pour SQLite)
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'type': type.name, // ENTRY, EXIT, EXPENSE
      'category': category.name, // RENT, CHARGES, etc.
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'attachment': attachment,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP (depuis SQLite)
  /// ============================================
  factory BranchTransactionModel.fromMap(Map<String, dynamic> map) {
    return BranchTransactionModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.EXPENSE,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.OTHER,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      attachment: map['attachment'] as String?,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  BranchTransactionModel copyWith({
    String? id,
    String? branchId,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? attachment,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchTransactionModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      attachment: attachment ?? this.attachment,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BranchTransactionModel(id: $id, type: ${type.name}, category: ${category.name}, amount: $amount)';
  }
}

/// ============================================
/// TYPE DE TRANSACTION
/// ============================================
enum TransactionType {
  ENTRY, // Entrée d'argent (ventes, autres revenus)
  EXIT, // Sortie d'argent (retraits)
  EXPENSE, // Dépense (loyer, charges, salaires, etc.)
}

/// ============================================
/// CATÉGORIE DE TRANSACTION
/// ============================================
enum TransactionCategory {
  // Catégories pour EXPENSE
  RENT, // Loyer
  CHARGES, // Charges (eau, électricité)
  SALARY, // Salaires
  TRANSPORT, // Transport/logistique
  MARKETING, // Marketing/publicité
  OTHER, // Autre dépense
  
  // Catégories pour ENTRY
  SALES, // Ventes
  OTHER_INCOME, // Autres revenus
  
  // Catégories pour EXIT
  WITHDRAWAL, // Retrait
}

/// ============================================
/// EXTENSIONS POUR AFFICHAGE
/// ============================================
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.ENTRY:
        return 'Entrée';
      case TransactionType.EXIT:
        return 'Sortie';
      case TransactionType.EXPENSE:
        return 'Dépense';
    }
  }

  /// Couleur pour l'affichage (vert pour entrée, rouge pour sortie/dépense)
  int get colorValue {
    switch (this) {
      case TransactionType.ENTRY:
        return 0xFF4CAF50; // Vert
      case TransactionType.EXIT:
      case TransactionType.EXPENSE:
        return 0xFFF44336; // Rouge
    }
  }
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.RENT:
        return 'Loyer';
      case TransactionCategory.CHARGES:
        return 'Charges';
      case TransactionCategory.SALARY:
        return 'Salaires';
      case TransactionCategory.TRANSPORT:
        return 'Transport';
      case TransactionCategory.MARKETING:
        return 'Marketing';
      case TransactionCategory.SALES:
        return 'Ventes';
      case TransactionCategory.OTHER_INCOME:
        return 'Autres revenus';
      case TransactionCategory.WITHDRAWAL:
        return 'Retrait';
      case TransactionCategory.OTHER:
        return 'Autre';
    }
  }
}

