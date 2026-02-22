 import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/database_helper.dart';
import '../data/models/employee_model.dart';
import '../data/models/branch_model.dart';
import '../data/models/role_model.dart';
import '../data/models/permission_request_model.dart';
import '../utils/code_generator.dart';

/// ============================================
/// PROVIDER : BranchEmployeeProvider
/// ============================================
/// Description : Gère l'état et la logique de la gestion des employés et rôles
/// Phase : Phase 4 - Gestion Employés
class BranchEmployeeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<EmployeeModel> _employees = [];
  List<RoleModel> _roles = [];
  List<PermissionRequestModel> _permissionRequests = [];
  bool _isLoading = false;

  // Getters
  List<EmployeeModel> get employees => _employees;
  List<RoleModel> get roles => _roles;
  List<PermissionRequestModel> get permissionRequests => _permissionRequests;
  bool get isLoading => _isLoading;

  /// ============================================
  /// CHARGER LES EMPLOYÉS D'UNE SUCCURSALE
  /// ============================================
  Future<void> loadEmployees(String branchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔄 Chargement des employés pour la succursale: $branchId');
      final data = await _dbHelper.getEmployeesByBranch(branchId);
      _employees = data.map((map) => EmployeeModel.fromMap(map)).toList();
      debugPrint('✅ ${_employees.length} employé(s) chargé(s) avec succès');
    } catch (e) {
      debugPrint('❌ Erreur chargement employés: $e');
      _employees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES RÔLES D'UNE SUCCURSALE
  /// ============================================
  Future<void> loadRoles(String branchId) async {
    try {
      debugPrint('🔄 Chargement des rôles pour la succursale: $branchId');
      final data = await _dbHelper.getRoles(branchId);
      _roles = data.map((map) => RoleModel.fromMap(map)).toList();
      debugPrint('✅ ${_roles.length} rôle(s) chargé(s) avec succès');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement rôles: $e');
      _roles = [];
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES DEMANDES DE PERMISSION
  /// ============================================
  Future<void> loadPermissionRequests(String branchId) async {
    try {
      debugPrint('🔄 Chargement des demandes de permission pour la succursale: $branchId');
      final data = await _dbHelper.getPermissionRequests(branchId);
      _permissionRequests = data.map((map) => PermissionRequestModel.fromMap(map)).toList();
      debugPrint('✅ ${_permissionRequests.length} demande(s) de permission chargée(s)');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement demandes de permission: $e');
      _permissionRequests = [];
      notifyListeners();
    }
  }

  /// ============================================
  /// CHARGER LES DEMANDES EN ATTENTE
  /// ============================================
  Future<void> loadPendingPermissionRequests(String branchId) async {
    try {
      debugPrint('🔄 Chargement des demandes en attente pour la succursale: $branchId');
      final data = await _dbHelper.getPendingPermissionRequests(branchId);
      _permissionRequests = data.map((map) => PermissionRequestModel.fromMap(map)).toList();
      debugPrint('✅ ${_permissionRequests.length} demande(s) en attente trouvée(s)');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement demandes en attente: $e');
      _permissionRequests = [];
      notifyListeners();
    }
  }

  /// ============================================
  /// AJOUTER UN EMPLOYÉ
  /// ============================================
  Future<Map<String, String>?> addEmployee({
    required String branchId,
    required String vendorId,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? photo,
    String? roleId,
    String? contractType,
    double? salary,
    String? emergencyContact,
    required DateTime hireDate,
  }) async {
    try {
      debugPrint('🔄 Ajout d\'un nouvel employé: $firstName $lastName');
      
      // Générer automatiquement un code d'accès unique
      final accessCode = await CodeGenerator.generateUniqueAccessCode();
      debugPrint('🔐 Code d\'accès généré pour $firstName $lastName: $accessCode');
      
      // Option B : Le departmentCode n'est plus copié dans l'employé
      // Il reste uniquement dans le rôle et sera vérifié directement depuis là
      
      final now = DateTime.now();
      final employee = EmployeeModel(
        id: _uuid.v4(),
        branchId: branchId,
        vendorId: vendorId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        photo: photo,
        role: '', // Ancien champ, gardé pour compatibilité
        roleId: roleId,
        departmentCode: null, // Option B : Ne plus copier, vérification directe depuis le rôle
        accessCode: accessCode, // Code généré automatiquement
        contractType: contractType ?? 'CDI',
        salary: salary,
        emergencyContact: emergencyContact,
        hireDate: hireDate,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertEmployee(employee.toMap());
      await loadEmployees(branchId);
      
      debugPrint('✅ Employé ajouté avec succès: ${employee.id}');
      
      // Retourner l'ID de l'employé et le code d'accès généré
      return {
        'employeeId': employee.id,
        'accessCode': accessCode,
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de l\'employé: $e');
      return null;
    }
  }

  /// ============================================
  /// MODIFIER UN EMPLOYÉ
  /// ============================================
  Future<bool> updateEmployee({
    required String employeeId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? photo,
    String? roleId,
    String? contractType,
    double? salary,
    String? emergencyContact,
    bool? isActive,
  }) async {
    try {
      debugPrint('🔄 Mise à jour de l\'employé: $employeeId');
      
      final employee = _employees.firstWhere((e) => e.id == employeeId);
      
      // Option B : Le departmentCode n'est plus géré ici
      // Il reste uniquement dans le rôle et sera vérifié directement depuis là
      
      final updatedEmployee = employee.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        photo: photo,
        roleId: roleId,
        departmentCode: null, // Option B : Ne plus copier, vérification directe depuis le rôle
        contractType: contractType,
        salary: salary,
        emergencyContact: emergencyContact,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateEmployee(employeeId, updatedEmployee.toMap());
      await loadEmployees(employee.branchId);
      
      debugPrint('✅ Employé mis à jour avec succès: $employeeId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de l\'employé: $e');
      return false;
    }
  }

  /// ============================================
  /// RETIRER LE RÔLE D'UN EMPLOYÉ (ADMIN UNIQUEMENT)
  /// ============================================
  Future<bool> removeEmployeeRole(String employeeId) async {
    try {
      debugPrint('🔄 Retrait du rôle de l\'employé: $employeeId');
      
      final employee = _employees.firstWhere((e) => e.id == employeeId);
      final updatedEmployee = employee.copyWith(
        roleId: null,
        // Option B : departmentCode n'est plus géré ici, il reste dans le rôle
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateEmployee(employeeId, updatedEmployee.toMap());
      await loadEmployees(employee.branchId);
      
      debugPrint('✅ Rôle retiré avec succès: $employeeId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du retrait du rôle: $e');
      return false;
    }
  }

  /// ============================================
  /// SUPPRIMER UN EMPLOYÉ (SOFT DELETE)
  /// ============================================
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      debugPrint('🔄 Suppression (soft delete) de l\'employé: $employeeId');
      
      final employee = _employees.firstWhere((e) => e.id == employeeId);
      final updatedEmployee = employee.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateEmployee(employeeId, updatedEmployee.toMap());
      await loadEmployees(employee.branchId);
      
      debugPrint('✅ Employé supprimé avec succès: $employeeId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de l\'employé: $e');
      return false;
    }
  }

  /// ============================================
  /// CRÉER UN RÔLE
  /// ============================================
  /// Génère automatiquement un departmentCode unique lors de la création
  Future<String?> createRole({
    required String branchId,
    required String name,
    required String department,
    List<String>? permissions,
    required String createdBy,
  }) async {
    try {
      debugPrint('🔄 Création d\'un nouveau rôle: $name pour le département $department');
      
      // Générer automatiquement un code département unique
      final departmentCode = await CodeGenerator.generateUniqueDepartmentCode();
      debugPrint('🔐 Code département généré: $departmentCode');
      
      final now = DateTime.now();
      final role = RoleModel(
        id: _uuid.v4(),
        branchId: branchId,
        name: name,
        department: department,
        departmentCode: departmentCode, // 🆕 Code généré automatiquement
        permissions: permissions,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _dbHelper.insertRole(role.toMap());
      await loadRoles(branchId);
      
      debugPrint('✅ Rôle créé avec succès: ${role.id} (Code: $departmentCode)');
      return role.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du rôle: $e');
      return null;
    }
  }

  /// ============================================
  /// MODIFIER UN RÔLE
  /// ============================================
  Future<bool> updateRole({
    required String roleId,
    String? name,
    String? department,
    List<String>? permissions,
  }) async {
    try {
      debugPrint('🔄 Mise à jour du rôle: $roleId');
      
      final role = _roles.firstWhere((r) => r.id == roleId);
      final updatedRole = role.copyWith(
        name: name,
        department: department,
        permissions: permissions,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateRole(roleId, updatedRole.toMap());
      await loadRoles(role.branchId);
      
      debugPrint('✅ Rôle mis à jour avec succès: $roleId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du rôle: $e');
      return false;
    }
  }

  /// ============================================
  /// DÉSACTIVER UN RÔLE
  /// ============================================
  Future<bool> deactivateRole(String roleId) async {
    try {
      debugPrint('🔄 Désactivation du rôle: $roleId');
      
      final role = _roles.firstWhere((r) => r.id == roleId);
      await _dbHelper.deactivateRole(roleId);
      await loadRoles(role.branchId);
      
      debugPrint('✅ Rôle désactivé avec succès: $roleId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la désactivation du rôle: $e');
      return false;
    }
  }

  /// ============================================
  /// CRÉER UNE DEMANDE DE PERMISSION
  /// ============================================
  Future<String?> createPermissionRequest({
    required String branchId,
    required String employeeId,
    String? transactionId,
    required RequestType requestType,
    required String reason,
  }) async {
    try {
      debugPrint('🔄 Création d\'une demande de permission: $requestType');
      
      final now = DateTime.now();
      final request = PermissionRequestModel(
        id: _uuid.v4(),
        branchId: branchId,
        employeeId: employeeId,
        transactionId: transactionId,
        requestType: requestType,
        reason: reason,
        createdAt: now,
      );

      await _dbHelper.insertPermissionRequest(request.toMap());
      await loadPermissionRequests(branchId);
      
      debugPrint('✅ Demande de permission créée avec succès: ${request.id}');
      return request.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la demande de permission: $e');
      return null;
    }
  }

  /// ============================================
  /// APPROUVER UNE DEMANDE DE PERMISSION
  /// ============================================
  Future<bool> approvePermissionRequest(String requestId, String reviewedBy) async {
    try {
      debugPrint('🔄 Approbation de la demande de permission: $requestId');
      
      await _dbHelper.updatePermissionRequestStatus(
        requestId: requestId,
        status: RequestStatus.APPROVED.name,
        reviewedBy: reviewedBy,
      );
      
      final request = _permissionRequests.firstWhere((r) => r.id == requestId);
      await loadPermissionRequests(request.branchId);
      
      debugPrint('✅ Demande de permission approuvée avec succès: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'approbation de la demande: $e');
      return false;
    }
  }

  /// ============================================
  /// REJETER UNE DEMANDE DE PERMISSION
  /// ============================================
  Future<bool> rejectPermissionRequest(String requestId, String reviewedBy) async {
    try {
      debugPrint('🔄 Rejet de la demande de permission: $requestId');
      
      await _dbHelper.updatePermissionRequestStatus(
        requestId: requestId,
        status: RequestStatus.REJECTED.name,
        reviewedBy: reviewedBy,
      );
      
      final request = _permissionRequests.firstWhere((r) => r.id == requestId);
      await loadPermissionRequests(request.branchId);
      
      debugPrint('✅ Demande de permission rejetée avec succès: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du rejet de la demande: $e');
      return false;
    }
  }

  /// ============================================
  /// VÉRIFIER LE CODE D'ACCÈS PAR DÉPARTEMENT
  /// ============================================
  Future<bool> verifyDepartmentCode(String branchId, String department, String code) async {
    try {
      debugPrint('🔐 Vérification du code d\'accès pour le département $department');
      final isValid = await _dbHelper.verifyDepartmentCode(branchId, department, code);
      debugPrint(isValid ? '✅ Code valide' : '❌ Code invalide');
      return isValid;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du code: $e');
      return false;
    }
  }

  /// ============================================
  /// VÉRIFIER SI UN UTILISATEUR EST ADMIN
  /// ============================================
  Future<bool> isAdmin(String branchId, String userId) async {
    try {
      debugPrint('👤 Vérification du statut admin pour: $userId');
      final isUserAdmin = await _dbHelper.isAdmin(branchId, userId);
      debugPrint(isUserAdmin ? '✅ Utilisateur est admin' : '❌ Utilisateur n\'est pas admin');
      return isUserAdmin;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification admin: $e');
      return false;
    }
  }

  /// ============================================
  /// VÉRIFIER LE CODE D'ACCÈS D'UN EMPLOYÉ
  /// ============================================
  /// Vérifie le code d'accès unique d'un employé pour une succursale donnée
  /// 
  /// Paramètres :
  /// - code : Le code d'accès unique de l'employé (4 caractères)
  /// - branchId : L'ID de la succursale où l'employé doit travailler
  /// 
  /// Retourne : Un Map contenant 'employee' (EmployeeModel) et 'branch' (BranchModel)
  ///            si le code est valide, null sinon
  /// 
  /// Vérifications effectuées :
  /// - Le code existe dans la base de données
  /// - L'employé appartient à la succursale spécifiée
  /// - L'employé est actif et non supprimé
  /// - La succursale est active
  Future<Map<String, dynamic>?> verifyEmployeeAccessCode(String code, String branchId) async {
    try {
      debugPrint('🔐 Vérification du code d\'accès: $code pour la succursale: $branchId');
      
      final result = await _dbHelper.verifyEmployeeAccessCode(code, branchId);
      
      if (result != null) {
        // Convertir les Maps en modèles
        final employee = EmployeeModel.fromMap(result['employee'] as Map<String, dynamic>);
        final branch = BranchModel.fromMap(result['branch'] as Map<String, dynamic>);
        
        debugPrint('✅ Code d\'accès valide pour l\'employé: ${employee.fullName}');
        return {
          'employee': employee,
          'branch': branch,
        };
      }
      
      debugPrint('❌ Code d\'accès invalide ou employé non trouvé');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du code d\'accès: $e');
      return null;
    }
  }

  /// ============================================
  /// RECHERCHER UNE SUCCURSALE PAR NOM
  /// ============================================
  /// Recherche une succursale active par son nom
  /// 
  /// Paramètre : name - Le nom de la succursale
  /// Retourne : BranchModel si trouvé, null sinon
  Future<BranchModel?> getBranchByName(String name) async {
    try {
      debugPrint('🔍 Recherche de la succursale: $name');
      
      final branchMap = await _dbHelper.getBranchByName(name);
      
      if (branchMap != null) {
        final branch = BranchModel.fromMap(branchMap);
        debugPrint('✅ Succursale trouvée: ${branch.name}');
        return branch;
      }
      
      debugPrint('❌ Succursale non trouvée: $name');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de succursale: $e');
      return null;
    }
  }

  /// ============================================
  /// RÉCUPÉRER UN RÔLE PAR SON ID
  /// ============================================
  /// Récupère un rôle spécifique par son ID
  /// 
  /// Paramètre : roleId - L'ID du rôle à récupérer
  /// Retourne : RoleModel si trouvé, null sinon
  Future<RoleModel?> getRole(String roleId) async {
    try {
      debugPrint('🔍 Récupération du rôle: $roleId');
      
      final roleMap = await _dbHelper.getRole(roleId);
      
      if (roleMap != null) {
        final role = RoleModel.fromMap(roleMap);
        debugPrint('✅ Rôle trouvé: ${role.name}');
        return role;
      }
      
      debugPrint('❌ Rôle non trouvé: $roleId');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  /// ============================================
  /// RÉINITIALISER LE PROVIDER
  /// ============================================
  void reset() {
    _employees = [];
    _roles = [];
    _permissionRequests = [];
    _isLoading = false;
    notifyListeners();
  }
}

