import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/database_helper.dart';
import '../data/models/branch_model.dart';

/// Provider pour gérer les succursales
class BranchProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<BranchModel> _branches = [];
  BranchModel? _selectedBranch;
  bool _isLoading = false;

  // Getters
  List<BranchModel> get branches => _branches;
  BranchModel? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;
  int get branchCount => _branches.length;

  List<BranchModel> get activeBranches =>
      _branches.where((b) => b.isActive).toList();

  int get activeBranchCount => activeBranches.length;

  // Charger toutes les succursales d'un vendeur
  Future<void> loadBranches(String vendorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getBranchesByVendor(vendorId as int);
      _branches = data.map((map) => BranchModel.fromMap(map)).toList();

      // Sélectionner la première succursale par défaut
      if (_branches.isNotEmpty && _selectedBranch == null) {
        _selectedBranch = _branches.first;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement succursales: $e');
      _branches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une nouvelle succursale
  Future<String?> addBranch({
    required int vendorId,
    required String name,
    required String code,
    required String country,
    required String city,
    required String district,
    required String address,
    double? latitude,
    double? longitude,
    required String phone,
    String? email,
    String? managerId,
    double monthlyRent = 0.0,
    double monthlyCharges = 0.0,
    String openingHours = '{}',
  }) async {
    try {
      // Vérifier si le code existe déjà
      if (_branches.any((b) => b.code == code)) {
        throw Exception('Code succursale déjà utilisé');
      }

      final now = DateTime.now();
      final branch = BranchModel(
        id: _uuid.v4(),
        vendorId: vendorId,
        name: name,
        code: code,
        country: country,
        city: city,
        district: district,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        email: email,
        managerId: managerId,
        monthlyRent: monthlyRent,
        monthlyCharges: monthlyCharges,
        isActive: true,
        openingDate: now,
        openingHours: openingHours,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertBranch(branch.toMap());
      _branches.insert(0, branch);

      // Sélectionner automatiquement si c'est la première
      if (_branches.length == 1) {
        _selectedBranch = branch;
      }

      notifyListeners();
      return branch.id;
    } catch (e) {
      debugPrint('❌ Erreur ajout succursale: $e');
      return null;
    }
  }

  // Modifier une succursale
  Future<bool> updateBranch({
    required String branchId,
    String? name,
    String? code,
    String? country,
    String? city,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? managerId,
    double? monthlyRent,
    double? monthlyCharges,
    bool? isActive,
    String? openingHours,
  }) async {
    try {
      final index = _branches.indexWhere((b) => b.id == branchId);
      if (index == -1) throw Exception('Succursale non trouvée');

      final oldBranch = _branches[index];
      final updatedBranch = oldBranch.copyWith(
        name: name,
        code: code,
        country: country,
        city: city,
        district: district,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        email: email,
        managerId: managerId,
        monthlyRent: monthlyRent,
        monthlyCharges: monthlyCharges,
        isActive: isActive,
        openingHours: openingHours,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateBranch(branchId, updatedBranch.toMap());
      _branches[index] = updatedBranch;

      // Mettre à jour selectedBranch si c'est celle-là
      if (_selectedBranch?.id == branchId) {
        _selectedBranch = updatedBranch;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Erreur modification succursale: $e');
      return false;
    }
  }

  // Supprimer une succursale (soft delete)
  Future<bool> deleteBranch(String branchId) async {
    try {
      final success = await updateBranch(branchId: branchId, isActive: false);

      if (success) {
        // Si c'était la succursale sélectionnée, en sélectionner une autre
        if (_selectedBranch?.id == branchId) {
          final activeBranches = _branches.where((b) => b.isActive && b.id != branchId).toList();
          _selectedBranch = activeBranches.isNotEmpty ? activeBranches.first : null;
        }
      }

      return success;
    } catch (e) {
      debugPrint('❌ Erreur suppression succursale: $e');
      return false;
    }
  }

  // Sélectionner une succursale
  void selectBranch(String branchId) {
    _selectedBranch = _branches.firstWhere(
          (b) => b.id == branchId,
      orElse: () => _branches.first,
    );
    notifyListeners();
  }

  // Obtenir une succursale par ID
  BranchModel? getBranchById(String branchId) {
    try {
      return _branches.firstWhere((b) => b.id == branchId);
    } catch (e) {
      return null;
    }
  }

  // Obtenir succursales par ville
  List<BranchModel> getBranchesByCity(String city) {
    return _branches.where((b) =>
    b.city.toLowerCase() == city.toLowerCase() && b.isActive
    ).toList();
  }

  // Rechercher succursales
  List<BranchModel> searchBranches(String query) {
    if (query.isEmpty) return activeBranches;

    final lowerQuery = query.toLowerCase();
    return _branches.where((b) =>
    b.isActive &&
        (b.name.toLowerCase().contains(lowerQuery) ||
            b.code.toLowerCase().contains(lowerQuery) ||
            b.city.toLowerCase().contains(lowerQuery) ||
            b.district.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  // Réinitialiser
  void reset() {
    _branches = [];
    _selectedBranch = null;
    _isLoading = false;
    notifyListeners();
  }
}