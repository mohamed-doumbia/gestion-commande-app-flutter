import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/database_helper.dart';
import '../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Inscription
  Future<bool> register(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseHelper.instance.createUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false; // Probablement numéro déjà existant
    }
  }

  // Connexion
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await DatabaseHelper.instance.loginUser(phone, password);

    if (user != null) {
      _currentUser = user;
      // Sauvegarder la session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', user.phone); // On utilise le phone comme ID simple ici
      await prefs.setString('userRole', user.role);

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}