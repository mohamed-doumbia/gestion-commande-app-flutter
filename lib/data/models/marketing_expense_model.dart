/// ============================================
/// MODÈLE : MarketingExpenseModel
/// ============================================
/// Description : Représente une dépense marketing/activité
/// Phase : Département Marketing - Onglet 2

class MarketingExpenseModel {
  final String id;
  final String branchId;
  final String category; // Catégorie de dépense
  final String activity; // Activité spécifique (ex: "Facebook Ads", "Formation équipe")
  final double amount; // Montant dépensé
  final String? description; // Description/notes
  final DateTime expenseDate; // Date de la dépense
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketingExpenseModel({
    required this.id,
    required this.branchId,
    required this.category,
    required this.activity,
    required this.amount,
    this.description,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ============================================
  /// CONVERSION VERS MAP
  /// ============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'category': category,
      'activity': activity,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// ============================================
  /// CRÉATION DEPUIS MAP
  /// ============================================
  factory MarketingExpenseModel.fromMap(Map<String, dynamic> map) {
    return MarketingExpenseModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      category: map['category'] as String,
      activity: map['activity'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// ============================================
  /// COPYWITH POUR MODIFICATIONS
  /// ============================================
  MarketingExpenseModel copyWith({
    String? id,
    String? branchId,
    String? category,
    String? activity,
    double? amount,
    String? description,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketingExpenseModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      activity: activity ?? this.activity,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// ============================================
/// MODÈLE : MarketingBudgetModel
/// ============================================
/// Description : Budget prévu par catégorie pour une période
class MarketingBudgetModel {
  final String id;
  final String branchId;
  final String category; // Catégorie de dépense
  final double budgetAmount; // Montant du budget
  final String periodType; // 'week', 'month', 'year'
  final DateTime periodStart; // Début de la période
  final DateTime periodEnd; // Fin de la période
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketingBudgetModel({
    required this.id,
    required this.branchId,
    required this.category,
    required this.budgetAmount,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'category': category,
      'budget_amount': budgetAmount,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MarketingBudgetModel.fromMap(Map<String, dynamic> map) {
    return MarketingBudgetModel(
      id: map['id'] as String,
      branchId: map['branch_id'] as String,
      category: map['category'] as String,
      budgetAmount: (map['budget_amount'] as num).toDouble(),
      periodType: map['period_type'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

