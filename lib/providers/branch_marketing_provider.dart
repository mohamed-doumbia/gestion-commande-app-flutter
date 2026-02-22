import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/sales_by_branch_model.dart';
import '../data/models/branch_sales_summary_model.dart';

/// ============================================
/// PROVIDER : BranchMarketingProvider
/// ============================================
/// Description : Gère toutes les données du département Marketing
/// Phase : Département Marketing

class BranchMarketingProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Données pour l'onglet Gestion des Ventes
  List<SalesByBranchModel> _salesByBranch = [];
  List<BranchSalesSummaryModel> _branchSummaries = [];
  bool _isLoading = false;
  String? _selectedCity;
  String? _selectedBranchId;
  DateTime? _selectedPeriodStart;
  DateTime? _selectedPeriodEnd;

  // Getters
  List<SalesByBranchModel> get salesByBranch => _salesByBranch;
  List<BranchSalesSummaryModel> get branchSummaries => _branchSummaries;
  bool get isLoading => _isLoading;
  String? get selectedCity => _selectedCity;
  String? get selectedBranchId => _selectedBranchId;

  /// ============================================
  /// CHARGER LES VENTES PAR SUCCURSALE
  /// ============================================
  Future<void> loadSalesByBranch({
    String? branchId,
    String? city,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedBranchId = branchId;
      _selectedCity = city;
      _selectedPeriodStart = periodStart;
      _selectedPeriodEnd = periodEnd;

      // Pour l'instant, on va utiliser les données existantes
      // TODO: Implémenter la requête SQL complète dans database_helper
      final data = await _dbHelper.getSalesByBranch(
        branchId: branchId,
        city: city,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      _salesByBranch = data.map((map) => SalesByBranchModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement ventes par succursale: $e');
      _salesByBranch = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES RÉSUMÉS PAR SUCCURSALE
  /// ============================================
  Future<void> loadBranchSummaries({
    String? city,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBranchSalesSummaries(
        city: city,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      _branchSummaries = data.map((map) => BranchSalesSummaryModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement résumés succursales: $e');
      _branchSummaries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// FILTRER PAR VILLE
  /// ============================================
  void filterByCity(String? city) {
    _selectedCity = city;
    notifyListeners();
    loadSalesByBranch(
      branchId: _selectedBranchId,
      city: city,
      periodStart: _selectedPeriodStart,
      periodEnd: _selectedPeriodEnd,
    );
  }

  /// ============================================
  /// FILTRER PAR SUCCURSALE
  /// ============================================
  void filterByBranch(String? branchId) {
    _selectedBranchId = branchId;
    notifyListeners();
    loadSalesByBranch(
      branchId: branchId,
      city: _selectedCity,
      periodStart: _selectedPeriodStart,
      periodEnd: _selectedPeriodEnd,
    );
  }

  /// ============================================
  /// RÉINITIALISER
  /// ============================================
  void reset() {
    _salesByBranch = [];
    _branchSummaries = [];
    _selectedCity = null;
    _selectedBranchId = null;
    _selectedPeriodStart = null;
    _selectedPeriodEnd = null;
    _isLoading = false;
    notifyListeners();
  }
}

