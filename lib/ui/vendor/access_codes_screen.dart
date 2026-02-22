import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/branch_employee_provider.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/role_model.dart';

/// ============================================
/// PAGE LISTE DES CODES D'ACCÈS
/// ============================================
/// Description : Affiche tous les codes d'accès pour succursales et employés
/// Permet de retrouver facilement les codes d'accès
class AccessCodesScreen extends StatefulWidget {
  const AccessCodesScreen({Key? key}) : super(key: key);

  @override
  State<AccessCodesScreen> createState() => _AccessCodesScreenState();
}

class _AccessCodesScreenState extends State<AccessCodesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _branchesData = [];
  List<Map<String, dynamic>> _employeesData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Charger toutes les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.currentUser?.id;

      if (vendorId != null) {
        // Charger les succursales avec leurs gérants
        await _loadBranchesWithManagers(vendorId);

        // Charger les employés avec leurs rôles
        await _loadEmployeesWithRoles(vendorId);
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des codes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Charger les succursales avec leurs gérants (responsables de département)
  Future<void> _loadBranchesWithManagers(String vendorId) async {
    try {
      final branchProvider = context.read<BranchProvider>();
      
      // Charger toutes les succursales du vendeur
      await branchProvider.loadBranches(vendorId);
      final branches = branchProvider.activeBranches;

      _branchesData = [];

      for (final branch in branches) {
        // Chercher le gérant (responsable de département) de cette succursale
        String? managerName;
        String? managerDepartment;

        // Chercher dans les employés actifs de cette succursale
        final employees = await DatabaseHelper.instance.getEmployeesByBranch(branch.id);
        for (final empMap in employees) {
          final employee = EmployeeModel.fromMap(empMap);
          if (employee.roleId != null && employee.isActive) {
            final roleMap = await DatabaseHelper.instance.getRole(employee.roleId!);
            if (roleMap != null) {
              final role = RoleModel.fromMap(roleMap);
              // Vérifier si c'est un responsable (nom du rôle contient "Responsable" ou "Manager")
              final roleName = role.name.toLowerCase();
              if (roleName.contains('responsable') || 
                  roleName.contains('manager') ||
                  roleName.contains('gérant')) {
                managerName = employee.fullName;
                managerDepartment = role.department;
                break;
              }
            }
          }
        }

        _branchesData.add({
          'branch': branch,
          'code': branch.code,
          'city': branch.city,
          'country': branch.country,
          'managerName': managerName,
          'managerDepartment': managerDepartment,
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des succursales: $e');
    }
  }

  /// Charger les employés avec leurs rôles
  Future<void> _loadEmployeesWithRoles(String vendorId) async {
    try {
      final employeeProvider = context.read<BranchEmployeeProvider>();

      _employeesData = [];

      // Charger toutes les succursales pour obtenir tous les employés
      final branchProvider = context.read<BranchProvider>();
      await branchProvider.loadBranches(vendorId);
      final branches = branchProvider.activeBranches;

      for (final branch in branches) {
        // Charger les employés de cette succursale
        await employeeProvider.loadEmployees(branch.id);
        final employees = employeeProvider.employees;

        for (final employee in employees) {
          if (employee.isActive && employee.accessCode != null) {
            String? roleName;
            String? department;

            if (employee.roleId != null) {
              final role = await employeeProvider.getRole(employee.roleId!);
              if (role != null) {
                roleName = role.name;
                department = role.department;
              }
            }

            _employeesData.add({
              'employee': employee,
              'code': employee.accessCode,
              'name': employee.fullName,
              'role': roleName ?? 'Aucun rôle',
              'department': department ?? 'N/A',
              'branchName': branch.name,
              'branchCity': branch.city,
            });
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des employés: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Codes d\'accès',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Succursales'),
            Tab(text: 'Employés'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBranchesTab(),
                _buildEmployeesTab(),
              ],
            ),
    );
  }

  /// Onglet Succursales
  Widget _buildBranchesTab() {
    if (_branchesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune succursale trouvée',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _branchesData.length,
        itemBuilder: (context, index) {
          final data = _branchesData[index];
          final branch = data['branch'] as BranchModel;
          final code = data['code'] as String;
          final city = data['city'] as String;
          final country = data['country'] as String;
          final managerName = data['managerName'] as String?;
          final managerDepartment = data['managerDepartment'] as String?;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$city, $country',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          code,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (managerName != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gérant',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$managerName (${managerDepartment ?? 'N/A'})',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Onglet Employés
  Widget _buildEmployeesTab() {
    if (_employeesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun employé trouvé',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _employeesData.length,
        itemBuilder: (context, index) {
          final data = _employeesData[index];
          final code = data['code'] as String;
          final name = data['name'] as String;
          final role = data['role'] as String;
          final department = data['department'] as String;
          final branchName = data['branchName'] as String;
          final branchCity = data['branchCity'] as String;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$role - $department',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$branchName ($branchCity)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      code,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

