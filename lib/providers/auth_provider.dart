import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/database_helper.dart';
import '../data/models/branch_model.dart';
import '../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  // Variables pour succursales
  BranchModel? _currentBranch;
  List<BranchModel> _userBranches = [];

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  BranchModel? get currentBranch => _currentBranch;
  List<BranchModel> get userBranches => _userBranches;

  // ============================================
  // INSCRIPTION
  // ============================================
  Future<bool> register(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier si le téléphone existe déjà
      final existing = await DatabaseHelper.instance.getUserByPhone(user.phone);

      if (existing != null) {
        print('❌ Téléphone déjà utilisé : ${user.phone}');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Créer l'utilisateur
      await DatabaseHelper.instance.createUser(user);
      print('✅ Utilisateur créé : ${user.fullName}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('🔥 ERREUR CRÉATION : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // CONNEXION
  // ============================================
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔍 Tentative de connexion : $phone');

      final user = await DatabaseHelper.instance.loginUser(phone, password);

      if (user != null) {
        _currentUser = user;

        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', user.id ?? 0);
        await prefs.setString('userPhone', user.phone);
        await prefs.setString('userRole', user.role);

        print('✅ Login réussi : ${user.fullName} (${user.role})');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Utilisateur non trouvé ou mot de passe incorrect');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('🔥 ERREUR LOGIN : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // DÉCONNEXION
  // ============================================
  Future<void> logout() async {
    _currentUser = null;
    resetBranches();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print('👋 Déconnexion réussie');
    notifyListeners();
  }

  // ============================================
  // RESTAURER SESSION
  // ============================================
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!isLoggedIn) {
        print('ℹ Aucune session sauvegardée');
        return false;
      }

      final userId = prefs.getInt('userId');

      if (userId == null) {
        print('Session invalide');
        return false;
      }

      // Charger l'utilisateur depuis la DB
      final user = await DatabaseHelper.instance.getUserById(userId);

      if (user != null) {
        _currentUser = user;
        print(' Session restaurée : ${user.fullName}');
        notifyListeners();
        return true;
      } else {
        print(' Utilisateur introuvable en DB');
        await logout();
        return false;
      }
    } catch (e) {
      print(' ERREUR RESTAURATION SESSION : $e');
      return false;
    }
  }

  // ============================================
  // GESTION SUCCURSALES
  // ============================================
  void selectBranch(BranchModel branch) {
    _currentBranch = branch;
    notifyListeners();
  }

  Future<void> loadUserBranches() async {
    if (currentUser?.role == 'vendeur') {
      // Les succursales seront chargées par BranchProvider
      notifyListeners();
    }
  }

  void resetBranches() {
    _currentBranch = null;
    _userBranches = [];
  }
}