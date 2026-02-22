import 'dart:math';
import '../data/local/database_helper.dart';

/// ============================================
/// GÉNÉRATEUR DE CODE D'ACCÈS UNIQUE
/// ============================================
/// Description : Génère un code d'accès unique de 4 caractères pour les employés
/// Format : 4 caractères aléatoires (lettres majuscules A-Z + chiffres 0-9)
/// Exemples : "A3B7", "X2Y8", "M5N9", "1A2B"
/// Vérifie l'unicité dans la base de données avant de retourner le code
/// 
/// Nombre de combinaisons possibles : 36^4 = 1,679,616

class CodeGenerator {
  static final Random _random = Random();

  /// ============================================
  /// GÉNÉRER UN CODE UNIQUE DE 4 CARACTÈRES
  /// ============================================
  /// Génère un code aléatoire de 4 caractères (lettres + chiffres) et vérifie son unicité
  /// Réessaie jusqu'à trouver un code unique (maximum 100 tentatives)
  /// 
  /// Retourne : Le code unique sous forme de String (ex: "A3B7", "X2Y8")
  /// 
  /// Exception : Lance une exception si aucun code unique n'est trouvé après 100 tentatives
  static Future<String> generateUniqueAccessCode() async {
    const int maxAttempts = 100; // Maximum de tentatives pour éviter une boucle infinie
    int attempts = 0;

    while (attempts < maxAttempts) {
      // Générer un code de 4 caractères (lettres + chiffres)
      final code = _generateFourDigitCode();
      
      // Vérifier l'unicité dans la base de données
      final isUnique = await _isCodeUnique(code);
      
      if (isUnique) {
        print('✅ Code d\'accès unique généré : $code');
        return code;
      }
      
      attempts++;
      print('⚠️ Code $code déjà utilisé, tentative ${attempts}/$maxAttempts');
    }

    // Si on arrive ici, aucun code unique n'a été trouvé après 100 tentatives
    // (très improbable avec 36^4 = 1,679,616 combinaisons possibles)
    throw Exception(
      'Impossible de générer un code d\'accès unique après $maxAttempts tentatives. '
      'Veuillez réessayer ou contacter le support.'
    );
  }

  /// ============================================
  /// GÉNÉRER UN CODE DE 4 CARACTÈRES (LETTRES + CHIFFRES)
  /// ============================================
  /// Génère un code aléatoire de 4 caractères composé de lettres majuscules et chiffres
  /// Format : Mélange aléatoire (ex: "A3B7", "X2Y8", "M5N9", "1A2B")
  /// 
  /// Caractères possibles : A-Z (26 lettres) + 0-9 (10 chiffres) = 36 caractères
  /// Nombre de combinaisons possibles : 36^4 = 1,679,616
  static String _generateFourDigitCode() {
    // Caractères possibles : lettres majuscules A-Z et chiffres 0-9
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    
    // Générer 4 caractères aléatoires
    final code = StringBuffer();
    for (int i = 0; i < 4; i++) {
      final randomIndex = _random.nextInt(chars.length);
      code.write(chars[randomIndex]);
    }
    
    return code.toString();
  }

  /// ============================================
  /// VÉRIFIER L'UNICITÉ DU CODE
  /// ============================================
  /// Vérifie si le code existe déjà dans la table employees
  /// 
  /// Paramètre : code - Le code à vérifier (String de 4 caractères)
  /// Retourne : true si le code est unique, false sinon
  static Future<bool> _isCodeUnique(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Rechercher si le code existe déjà
      final result = await db.query(
        'employees',
        columns: ['id'],
        where: 'access_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      // Le code est unique s'il n'existe pas dans la base
      return result.isEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'unicité du code: $e');
      // En cas d'erreur, considérer le code comme non unique pour réessayer
      return false;
    }
  }

  /// ============================================
  /// VÉRIFIER SI UN CODE EXISTE (MÉTHODE PUBLIQUE)
  /// ============================================
  /// Méthode publique pour vérifier si un code existe déjà
  /// Utile pour la validation dans les formulaires
  /// 
  /// Paramètre : code - Le code à vérifier
  /// Retourne : true si le code existe, false sinon
  static Future<bool> codeExists(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final result = await db.query(
        'employees',
        columns: ['id'],
        where: 'access_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'existence du code: $e');
      return false;
    }
  }

  /// ============================================
  /// GÉNÉRER UN CODE DÉPARTEMENT UNIQUE
  /// ============================================
  /// Génère un code unique de 4 caractères pour un département
  /// Vérifie l'unicité dans la table roles (department_code)
  /// Réessaie jusqu'à trouver un code unique (maximum 100 tentatives)
  /// 
  /// Retourne : Le code unique sous forme de String (ex: "A3B7", "X2Y8")
  /// 
  /// Exception : Lance une exception si aucun code unique n'est trouvé après 100 tentatives
  static Future<String> generateUniqueDepartmentCode() async {
    const int maxAttempts = 100; // Maximum de tentatives pour éviter une boucle infinie
    int attempts = 0;

    while (attempts < maxAttempts) {
      // Générer un code de 4 caractères (lettres + chiffres)
      final code = _generateFourDigitCode();
      
      // Vérifier l'unicité dans la base de données (table roles)
      final isUnique = await _isDepartmentCodeUnique(code);
      
      if (isUnique) {
        print('✅ Code département unique généré : $code');
        return code;
      }
      
      attempts++;
      print('⚠️ Code département $code déjà utilisé, tentative ${attempts}/$maxAttempts');
    }

    // Si on arrive ici, aucun code unique n'a été trouvé après 100 tentatives
    throw Exception(
      'Impossible de générer un code département unique après $maxAttempts tentatives. '
      'Veuillez réessayer ou contacter le support.'
    );
  }

  /// ============================================
  /// VÉRIFIER L'UNICITÉ DU CODE DÉPARTEMENT
  /// ============================================
  /// Vérifie si le code département existe déjà dans la table roles
  /// 
  /// Paramètre : code - Le code à vérifier (String de 4 caractères)
  /// Retourne : true si le code est unique, false sinon
  static Future<bool> _isDepartmentCodeUnique(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Rechercher si le code existe déjà dans la table roles
      final result = await db.query(
        'roles',
        columns: ['id'],
        where: 'department_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      // Le code est unique s'il n'existe pas dans la base
      return result.isEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'unicité du code département: $e');
      // En cas d'erreur, considérer le code comme non unique pour réessayer
      return false;
    }
  }

  /// ============================================
  /// GÉNÉRER UN CODE SUCCURSALE UNIQUE
  /// ============================================
  /// Génère un code unique de 4 caractères pour une succursale
  /// Vérifie l'unicité dans la table branches (code)
  /// Réessaie jusqu'à trouver un code unique (maximum 100 tentatives)
  /// 
  /// Retourne : Le code unique sous forme de String (ex: "A3B7", "X2Y8")
  /// 
  /// Exception : Lance une exception si aucun code unique n'est trouvé après 100 tentatives
  static Future<String> generateUniqueBranchCode() async {
    const int maxAttempts = 100; // Maximum de tentatives pour éviter une boucle infinie
    int attempts = 0;

    while (attempts < maxAttempts) {
      // Générer un code de 4 caractères (lettres + chiffres)
      final code = _generateFourDigitCode();
      
      // Vérifier l'unicité dans la base de données (table branches)
      final isUnique = await _isBranchCodeUnique(code);
      
      if (isUnique) {
        print('✅ Code succursale unique généré : $code');
        return code;
      }
      
      attempts++;
      print('⚠️ Code succursale $code déjà utilisé, tentative ${attempts}/$maxAttempts');
    }

    // Si on arrive ici, aucun code unique n'a été trouvé après 100 tentatives
    throw Exception(
      'Impossible de générer un code succursale unique après $maxAttempts tentatives. '
      'Veuillez réessayer ou contacter le support.'
    );
  }

  /// ============================================
  /// VÉRIFIER L'UNICITÉ DU CODE SUCCURSALE
  /// ============================================
  /// Vérifie si le code succursale existe déjà dans la table branches
  /// 
  /// Paramètre : code - Le code à vérifier (String de 4 caractères)
  /// Retourne : true si le code est unique, false sinon
  static Future<bool> _isBranchCodeUnique(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Rechercher si le code existe déjà dans la table branches
      final result = await db.query(
        'branches',
        columns: ['id'],
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      
      // Le code est unique s'il n'existe pas dans la base
      return result.isEmpty;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'unicité du code succursale: $e');
      // En cas d'erreur, considérer le code comme non unique pour réessayer
      return false;
    }
  }
}

