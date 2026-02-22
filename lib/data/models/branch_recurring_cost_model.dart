/// ============================================
/// MODÈLE : BranchRecurringCostModel
/// ============================================
/// Description : Représente un coût récurrent d'une succursale
/// Phase : Phase 3 - Comptabilité
/// Exemples : Loyer mensuel, Charges mensuelles, etc.
import 'branch_transaction_model.dart';

class BranchRecurringCostModel {
  final String id;
  final String branchId; // ID de la succursale
  final String name; // Nom du coût (ex: "Loyer mensuel")
  final TransactionCategory category; // Catégorie (RENT, CHARGES, etc.)
  final double amount; // Montant en FCFA
  final RecurringFrequency frequency; // Mensuel, Trimestriel, Annuel
  final DateTime startDate; // Date de début
  final DateTime? endDate; // Date de fin (null si toujours actif)
  final bool isActive; // Actif ou non
  final String? notes; // Notes optionnelles
  final DateTime createdAt; // Date de création
  final DateTime updatedAt; // Date de dernière modification

  BranchRecurringCostModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
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
      'name': name,
      'category': category.name,
      'amount': amount,
      'frequency': frequency.name, // MONTHLY, QUARTERLY, YEARLY
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP (depuis SQLite)
  /// ============================================
  factory BranchRecurringCostModel.fromMap(Map<String, dynamic> map) {
    return BranchRecurringCostModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      name: map['name'] as String,
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.OTHER,
      ),
      amount: (map['amount'] as num).toDouble(),
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.MONTHLY,
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: map['is_active'] == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  BranchRecurringCostModel copyWith({
    String? id,
    String? branchId,
    String? name,
    TransactionCategory? category,
    double? amount,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchRecurringCostModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BranchRecurringCostModel(id: $id, name: $name, amount: $amount, frequency: ${frequency.name})';
  }
}

/// ============================================
/// FRÉQUENCE RÉCURRENTE
/// ============================================
enum RecurringFrequency {
  MONTHLY, // Mensuel
  QUARTERLY, // Trimestriel
  YEARLY, // Annuel
}

/// ============================================
/// EXTENSION POUR AFFICHAGE
/// ============================================
extension RecurringFrequencyExtension on RecurringFrequency {
  String get displayName {
    switch (this) {
      case RecurringFrequency.MONTHLY:
        return 'Mensuel';
      case RecurringFrequency.QUARTERLY:
        return 'Trimestriel';
      case RecurringFrequency.YEARLY:
        return 'Annuel';
    }
  }

  /// Nombre de fois par an
  int get timesPerYear {
    switch (this) {
      case RecurringFrequency.MONTHLY:
        return 12;
      case RecurringFrequency.QUARTERLY:
        return 4;
      case RecurringFrequency.YEARLY:
        return 1;
    }
  }
}

