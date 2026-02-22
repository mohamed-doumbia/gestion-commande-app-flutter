import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/marketing_expense_model.dart';
import 'package:uuid/uuid.dart';

/// ============================================
/// PROVIDER : MarketingExpenseProvider
/// ============================================
/// Description : Gère les dépenses et budgets marketing
/// Phase : Département Marketing - Onglet 2

class MarketingExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<MarketingExpenseModel> _expenses = [];
  List<MarketingBudgetModel> _budgets = [];
  bool _isLoading = false;

  // Getters
  List<MarketingExpenseModel> get expenses => _expenses;
  List<MarketingBudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;

  // Catégories disponibles
  static const List<String> categories = [
    'Marketing & Publicité',
    'Communication',
    'Événements & Relations publiques',
    'Formation & Développement',
    'Matériel & Équipement',
    'Transport & Logistique',
    'Services professionnels',
    'Location & Infrastructure',
    'Autres dépenses',
  ];

  // Types de périodes
  static const List<String> periodTypes = ['week', 'month', 'year'];

  /// ============================================
  /// CHARGER LES DÉPENSES PAR PÉRIODE
  /// ============================================
  Future<void> loadExpenses({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getMarketingExpenses(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
        category: category,
      );

      _expenses = data.map((map) => MarketingExpenseModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement dépenses marketing: $e');
      _expenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES BUDGETS PAR PÉRIODE
  /// ============================================
  Future<void> loadBudgets({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? periodType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getMarketingBudgets(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
        category: category,
        periodType: periodType,
      );

      _budgets = data.map((map) => MarketingBudgetModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement budgets marketing: $e');
      _budgets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// AJOUTER UNE DÉPENSE
  /// ============================================
  Future<bool> addExpense({
    required String branchId,
    required String category,
    required String activity,
    required double amount,
    String? description,
    required DateTime expenseDate,
  }) async {
    try {
      final now = DateTime.now();
      final expense = {
        'id': _uuid.v4(),
        'branch_id': branchId,
        'category': category,
        'activity': activity,
        'amount': amount,
        'description': description,
        'expense_date': expenseDate.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _dbHelper.insertMarketingExpense(expense);
      
      // Recharger les dépenses
      await loadExpenses(branchId: branchId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout dépense marketing: $e');
      return false;
    }
  }

  /// ============================================
  /// MODIFIER UNE DÉPENSE
  /// ============================================
  Future<bool> updateExpense(MarketingExpenseModel expense) async {
    try {
      await _dbHelper.updateMarketingExpense(expense.id, expense.toMap());
      
      // Recharger les dépenses
      final branchId = expense.branchId;
      await loadExpenses(branchId: branchId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modification dépense marketing: $e');
      return false;
    }
  }

  /// ============================================
  /// SUPPRIMER UNE DÉPENSE
  /// ============================================
  Future<bool> deleteExpense(String expenseId, String branchId) async {
    try {
      await _dbHelper.deleteMarketingExpense(expenseId);
      
      // Recharger les dépenses
      await loadExpenses(branchId: branchId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression dépense marketing: $e');
      return false;
    }
  }

  /// ============================================
  /// AJOUTER UN BUDGET
  /// ============================================
  Future<bool> addBudget({
    required String branchId,
    required String category,
    required double budgetAmount,
    required String periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final now = DateTime.now();
      final budget = {
        'id': _uuid.v4(),
        'branch_id': branchId,
        'category': category,
        'budget_amount': budgetAmount,
        'period_type': periodType,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _dbHelper.insertMarketingBudget(budget);
      
      // Recharger les budgets
      await loadBudgets(branchId: branchId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout budget marketing: $e');
      return false;
    }
  }

  /// ============================================
  /// MODIFIER UN BUDGET
  /// ============================================
  Future<bool> updateBudget(MarketingBudgetModel budget) async {
    try {
      await _dbHelper.updateMarketingBudget(budget.id, budget.toMap());
      
      // Recharger les budgets
      final branchId = budget.branchId;
      await loadBudgets(branchId: branchId);
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modification budget marketing: $e');
      return false;
    }
  }

  /// ============================================
  /// CALCULER LE TOTAL DES DÉPENSES PAR CATÉGORIE
  /// ============================================
  Map<String, double> getExpensesByCategory() {
    final Map<String, double> categoryTotals = {};
    
    for (final expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  /// ============================================
  /// CALCULER LE TOTAL DES BUDGETS PAR CATÉGORIE
  /// ============================================
  Map<String, double> getBudgetsByCategory() {
    final Map<String, double> categoryBudgets = {};
    
    for (final budget in _budgets) {
      categoryBudgets[budget.category] = 
          (categoryBudgets[budget.category] ?? 0.0) + budget.budgetAmount;
    }
    
    return categoryBudgets;
  }

  /// ============================================
  /// CALCULER LE TOTAL DES DÉPENSES
  /// ============================================
  double getTotalExpenses() {
    return _expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  /// ============================================
  /// CALCULER LE TOTAL DES BUDGETS
  /// ============================================
  double getTotalBudgets() {
    return _budgets.fold<double>(0.0, (sum, budget) => sum + budget.budgetAmount);
  }

  /// ============================================
  /// RÉINITIALISER
  /// ============================================
  void reset() {
    _expenses = [];
    _budgets = [];
    _isLoading = false;
    notifyListeners();
  }
}

