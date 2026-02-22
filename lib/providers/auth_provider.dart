import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/database_helper.dart';
import '../data/models/branch_model.dart';
import '../data/models/user_model.dart';
import '../data/models/employee_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  // Variables pour succursales
  BranchModel? _currentBranch;
  List<BranchModel> _userBranches = [];

  // Variables pour sessions employés
  EmployeeModel? _currentEmployee;
  BranchModel? _currentEmployeeBranch;
  String? _sessionType; // "user" ou "employee"

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  BranchModel? get currentBranch => _currentBranch;
  List<BranchModel> get userBranches => _userBranches;
  
  // Getters pour sessions employés
  EmployeeModel? get currentEmployee => _currentEmployee;
  BranchModel? get currentEmployeeBranch => _currentEmployeeBranch;
  bool get isEmployeeSession => _sessionType == 'employee';
  bool get isUserSession => _sessionType == 'user' || (_sessionType == null && _currentUser != null);

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
        _currentEmployee = null; // Réinitialiser la session employé
        _currentEmployeeBranch = null;
        _sessionType = 'user'; // Marquer comme session utilisateur

        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', user.id ?? '');
        await prefs.setString('userPhone', user.phone);
        await prefs.setString('userRole', user.role);
        await prefs.setString('sessionType', 'user');
        // Nettoyer les données employé si elles existent
        await prefs.remove('employeeId');
        await prefs.remove('employeeBranchId');

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
    _currentEmployee = null;
    _currentEmployeeBranch = null;
    _sessionType = null;
    resetBranches();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print('👋 Déconnexion réussie');
    notifyListeners();
  }

  // ============================================
  // SUPPRIMER LE COMPTE (SOFT DELETE)
  // ============================================
  /// Supprime le compte utilisateur (soft delete)
  /// Marque is_deleted = 1 dans la base de données
  /// Les données restent en base mais l'utilisateur ne peut plus se connecter
  /// 
  /// Retourne : true si la suppression a réussi, false sinon
  Future<bool> deleteAccount() async {
    if (_currentUser == null || _currentUser!.id == null) {
      print('❌ Aucun utilisateur connecté');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await DatabaseHelper.instance.softDeleteUser(_currentUser!.id!);
      
      if (success) {
        // Déconnecter l'utilisateur après suppression
        await logout();
        print('✅ Compte supprimé avec succès');
      } else {
        print('❌ Erreur lors de la suppression du compte');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('🔥 ERREUR SUPPRESSION COMPTE : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

      final sessionType = prefs.getString('sessionType') ?? 'user';

      // NE RESTAURER QUE LES SESSIONS CLIENT (pas vendeur, pas employé)
      if (sessionType == 'employee') {
        // Ne pas restaurer les sessions employé - ils doivent toujours entrer leur code
        print('ℹ Session employé détectée - non restaurée (sécurité)');
        await logout();
        return false;
      } else {
        // Restaurer uniquement si c'est un client et vérifier l'expiration
        return await _restoreClientSession(prefs);
      }
    } catch (e) {
      print('❌ ERREUR RESTAURATION SESSION : $e');
      return false;
    }
  }

  /// ============================================
  /// RESTAURER SESSION CLIENT UNIQUEMENT (avec expiration 3h)
  /// ============================================
  Future<bool> _restoreClientSession(SharedPreferences prefs) async {
    try {
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        print('Session client invalide');
        return false;
      }

      // Vérifier l'expiration de la session (3 heures)
      final loginTimestamp = prefs.getInt('loginTimestamp');
      if (loginTimestamp != null) {
        final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
        final now = DateTime.now();
        final difference = now.difference(loginTime);
        
        if (difference.inHours >= 3) {
          print('⏰ Session client expirée (${difference.inHours}h)');
          await logout();
          return false;
        }
      }

      // Charger l'utilisateur depuis la DB
      final user = await DatabaseHelper.instance.getUserById(userId);

      if (user != null) {
        // Vérifier que c'est bien un client (pas un vendeur)
        if (user.role != 'client') {
          print('❌ Session vendeur détectée - non restaurée (sécurité)');
          await logout();
          return false;
        }

        _currentUser = user;
        _currentEmployee = null;
        _currentEmployeeBranch = null;
        _sessionType = 'user';
        print('✅ Session client restaurée : ${user.fullName}');
        notifyListeners();
        return true;
      } else {
        print('❌ Client introuvable en DB');
        await logout();
        return false;
      }
    } catch (e) {
      print('❌ ERREUR RESTAURATION SESSION CLIENT : $e');
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

  // ============================================
  // CONNEXION EN TANT QU'EMPLOYÉ
  // ============================================
  /// Connecte un employé avec son code d'accès
  /// 
  /// Paramètres :
  /// - employee : L'employé à connecter
  /// - branch : La succursale où l'employé travaille
  /// 
  /// Sauvegarde la session dans SharedPreferences pour restauration ultérieure
  Future<void> loginAsEmployee(EmployeeModel employee, BranchModel branch) async {
    try {
      _currentEmployee = employee;
      _currentEmployeeBranch = branch;
      _currentUser = null; // Réinitialiser la session utilisateur
      _sessionType = 'employee'; // Marquer comme session employé

      // NE PAS sauvegarder la session employé (sécurité)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('employeeId');
      await prefs.remove('employeeBranchId');
      await prefs.remove('sessionType');
      // Nettoyer les données utilisateur si elles existent
      await prefs.remove('userId');
      await prefs.remove('userPhone');
      await prefs.remove('userRole');
      await prefs.remove('loginTimestamp');

      print('✅ Employé connecté : ${employee.fullName} (${branch.name}) - Session non sauvegardée');
      notifyListeners();
    } catch (e) {
      print('❌ ERREUR CONNEXION EMPLOYÉ : $e');
      rethrow;
    }
  }
}