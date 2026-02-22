import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/database_helper.dart';
import '../data/models/branch_transaction_model.dart';
import '../data/models/branch_recurring_cost_model.dart';

/// ============================================
/// PROVIDER : BranchAccountingProvider
/// ============================================
/// Description : Gère l'état et la logique de la comptabilité des succursales
/// Phase : Phase 3 - Comptabilité
class BranchAccountingProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<BranchTransactionModel> _transactions = [];
  List<BranchRecurringCostModel> _recurringCosts = [];
  bool _isLoading = false;

  // Getters
  List<BranchTransactionModel> get transactions => _transactions;
  List<BranchRecurringCostModel> get recurringCosts => _recurringCosts;
  bool get isLoading => _isLoading;

  /// ============================================
  /// CHARGER LES TRANSACTIONS D'UNE SUCCURSALE
  /// ============================================
  Future<void> loadTransactions(String branchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBranchTransactions(branchId);
      _transactions = data.map((map) => BranchTransactionModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES TRANSACTIONS FILTRÉES
  /// ============================================
  Future<void> loadTransactionsFiltered({
    required String branchId,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBranchTransactionsFiltered(
        branchId: branchId,
        type: type?.name,
        category: category?.name,
        startDate: startDate,
        endDate: endDate,
      );
      _transactions = data.map((map) => BranchTransactionModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement transactions filtrées: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// AJOUTER UNE TRANSACTION
  /// ============================================
  Future<String?> addTransaction({
    required String branchId,
    required TransactionType type,
    required TransactionCategory category,
    required double amount,
    required DateTime date,
    String? description,
    String? attachment,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now();
      final transaction = BranchTransactionModel(
        id: _uuid.v4(),
        branchId: branchId,
        type: type,
        category: category,
        amount: amount,
        description: description,
        date: date,
        attachment: attachment,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertBranchTransaction(transaction.toMap());
      _transactions.insert(0, transaction);
      notifyListeners();
      return transaction.id;
    } catch (e) {
      debugPrint('❌ Erreur ajout transaction: $e');
      return null;
    }
  }

  /// ============================================
  /// MODIFIER UNE TRANSACTION
  /// ============================================
  Future<bool> updateTransaction({
    required String transactionId,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? attachment,
  }) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index == -1) throw Exception('Transaction non trouvée');

      final oldTransaction = _transactions[index];
      final updatedTransaction = oldTransaction.copyWith(
        type: type,
        category: category,
        amount: amount,
        date: date,
        description: description,
        attachment: attachment,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateBranchTransaction(transactionId, updatedTransaction.toMap());
      _transactions[index] = updatedTransaction;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modification transaction: $e');
      return false;
    }
  }

  /// ============================================
  /// SUPPRIMER UNE TRANSACTION
  /// ============================================
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _dbHelper.deleteBranchTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression transaction: $e');
      return false;
    }
  }

  /// ============================================
  /// CHARGER LES COÛTS RÉCURRENTS
  /// ============================================
  Future<void> loadRecurringCosts(String branchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBranchRecurringCosts(branchId);
      _recurringCosts = data.map((map) => BranchRecurringCostModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement coûts récurrents: $e');
      _recurringCosts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// AJOUTER UN COÛT RÉCURRENT
  /// ============================================
  Future<String?> addRecurringCost({
    required String branchId,
    required String name,
    required TransactionCategory category,
    required double amount,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final cost = BranchRecurringCostModel(
        id: _uuid.v4(),
        branchId: branchId,
        name: name,
        category: category,
        amount: amount,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertBranchRecurringCost(cost.toMap());
      _recurringCosts.insert(0, cost);
      notifyListeners();
      return cost.id;
    } catch (e) {
      debugPrint('❌ Erreur ajout coût récurrent: $e');
      return null;
    }
  }

  /// ============================================
  /// MODIFIER UN COÛT RÉCURRENT
  /// ============================================
  Future<bool> updateRecurringCost({
    required String costId,
    String? name,
    TransactionCategory? category,
    double? amount,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final index = _recurringCosts.indexWhere((c) => c.id == costId);
      if (index == -1) throw Exception('Coût récurrent non trouvé');

      final oldCost = _recurringCosts[index];
      final updatedCost = oldCost.copyWith(
        name: name,
        category: category,
        amount: amount,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateBranchRecurringCost(costId, updatedCost.toMap());
      _recurringCosts[index] = updatedCost;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modification coût récurrent: $e');
      return false;
    }
  }

  /// ============================================
  /// SUPPRIMER UN COÛT RÉCURRENT
  /// ============================================
  Future<bool> deleteRecurringCost(String costId) async {
    try {
      await _dbHelper.deleteBranchRecurringCost(costId);
      _recurringCosts.removeWhere((c) => c.id == costId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression coût récurrent: $e');
      return false;
    }
  }

  /// ============================================
  /// CALCULER LE BILAN FINANCIER
  /// ============================================
  Future<Map<String, double>> calculateFinancialSummary({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final totalEntries = await _dbHelper.getTotalEntries(branchId, startDate, endDate);
      final totalExits = await _dbHelper.getTotalExits(branchId, startDate, endDate);
      final totalExpenses = await _dbHelper.getTotalExpenses(branchId, startDate, endDate);
      final totalOutflows = totalExits + totalExpenses;
      final netProfit = totalEntries - totalOutflows;
      final profitMargin = totalEntries > 0 ? (netProfit / totalEntries) * 100 : 0.0;

      return {
        'totalEntries': totalEntries,
        'totalExits': totalExits,
        'totalExpenses': totalExpenses,
        'totalOutflows': totalOutflows,
        'netProfit': netProfit,
        'profitMargin': profitMargin,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul bilan: $e');
      return {
        'totalEntries': 0.0,
        'totalExits': 0.0,
        'totalExpenses': 0.0,
        'totalOutflows': 0.0,
        'netProfit': 0.0,
        'profitMargin': 0.0,
      };
    }
  }

  /// ============================================
  /// RÉINITIALISER
  /// ============================================
  void reset() {
    _transactions = [];
    _recurringCosts = [];
    _isLoading = false;
    notifyListeners();
  }
}




