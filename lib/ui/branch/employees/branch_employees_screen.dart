import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/branch_employee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/department_drawer.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/role_model.dart';
import 'employee_detail_screen.dart';
import 'edit_employee_screen.dart';
import 'add_role_screen.dart';

/// ============================================
/// PAGE GESTION EMPLOYÉS SUCCURSALE
/// ============================================
/// Description : Gestion complète des employés d'une succursale
/// Phase : Phase 4 - Gestion Employés
/// Contenu : 5 onglets (Liste, Ajouter, Import, Rôles, Performance)
class BranchEmployeesScreen extends StatefulWidget {
  final String branchId;

  const BranchEmployeesScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<BranchEmployeesScreen> createState() => _BranchEmployeesScreenState();
}

class _BranchEmployeesScreenState extends State<BranchEmployeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================
  /// CHARGER LES DONNÉES
  /// ============================================
  Future<void> _loadData() async {
    final employeeProvider = context.read<BranchEmployeeProvider>();
    await Future.wait([
      employeeProvider.loadEmployees(widget.branchId),
      employeeProvider.loadRoles(widget.branchId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.currentEmployee;
    final branch = authProvider.currentEmployeeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DepartmentDrawer(
        departmentName: 'Ressources Humaines',
        employeeName: employee?.fullName,
        branchName: branch?.name,
      ),
      appBar: AppBar(
        title: Text(
          'Gestion Employés',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Liste'),
            Tab(text: 'Ajouter'),
            Tab(text: 'Import'),
            Tab(text: 'Rôles'),
            Tab(text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeesListTab(),
          _buildAddEmployeeTab(),
          _buildImportTab(),
          _buildRolesTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }

  /// ============================================
  /// ONGLET 1 : LISTE EMPLOYÉS
  /// ============================================
  Widget _buildEmployeesListTab() {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucun employé',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez votre premier employé',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEmployees(widget.branchId),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.employees.length,
            itemBuilder: (context, index) {
              final employee = provider.employees[index];
            return Consumer<BranchEmployeeProvider>(
              builder: (context, empProvider, child) {
                return _EmployeeCard(
                  employee: employee,
                  provider: empProvider,
                  onView: () => _viewEmployeeDetails(employee),
                  onEdit: () => _editEmployee(employee),
                  onDeactivate: () => _deactivateEmployee(employee),
                  onActivate: () => _activateEmployee(employee),
                );
              },
            );
            },
          ),
        );
      },
    );
  }

  /// ============================================
  /// ONGLET 2 : AJOUTER EMPLOYÉ
  /// ============================================
  Widget _buildAddEmployeeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AddEmployeeForm(branchId: widget.branchId),
    );
  }

  /// ============================================
  /// ONGLET 3 : IMPORT FICHIER
  /// ============================================
  Widget _buildImportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Import Fichier',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fonctionnalité disponible avec Spring Boot',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Import Excel - Bientôt disponible avec Spring Boot', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.file_upload),
            label: Text('Choisir fichier', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// ONGLET 4 : RÔLES & PERMISSIONS
  /// ============================================
  Widget _buildRolesTab() {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Bouton ajouter rôle
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Vérifier si l'utilisateur est admin
                  final authProvider = context.read<AuthProvider>();
                  final userId = authProvider.currentUser?.id.toString() ?? '';
                  
                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final isUserAdmin = await provider.isAdmin(widget.branchId, userId);

                  if (!isUserAdmin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Seul un administrateur peut ajouter un rôle', style: GoogleFonts.poppins()),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Admin peut ajouter - Naviguer vers la page
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddRoleScreen(branchId: widget.branchId),
                    ),
                  );
                  if (result == true) {
                    // Recharger les rôles si création/modification réussie
                    provider.loadRoles(widget.branchId);
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Ajouter un rôle', style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), // Fond noir
                  foregroundColor: Colors.white, // Texte blanc
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            // Liste des rôles
            Expanded(
              child: provider.roles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun rôle',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadRoles(widget.branchId),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.roles.length,
                        itemBuilder: (context, index) {
                          final role = provider.roles[index];
                          return _RoleCard(
                            role: role,
                            onEdit: () => _editRole(role),
                            onDeactivate: () => _deactivateRole(role),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// ONGLET 5 : PERFORMANCE EMPLOYÉS
  /// ============================================
  Widget _buildPerformanceTab() {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée de performance',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // Trier les employés par CA généré
        final sortedEmployees = List<EmployeeModel>.from(provider.employees)
          ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Classement par CA généré',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEmployees.asMap().entries.map((entry) {
              final index = entry.key;
              final employee = entry.value;
              return _PerformanceCard(
                employee: employee,
                rank: index + 1,
              );
            }),
          ],
        );
      },
    );
  }

  // ============================================
  // MÉTHODES HELPER
  // ============================================

  void _viewEmployeeDetails(EmployeeModel employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailScreen(
          employee: employee,
          branchId: widget.branchId,
        ),
      ),
    ).then((_) {
      // Recharger les données après retour
      _loadData();
    });
  }

  /// ============================================
  /// ÉDITER UN EMPLOYÉ (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _editEmployee(EmployeeModel employee) async {
    // Vérifier si l'utilisateur est admin
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut modifier un employé', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut modifier
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEmployeeScreen(
          branchId: widget.branchId,
          employee: employee,
        ),
      ),
    );
    
    if (result == true) {
      // Recharger la liste des employés
      context.read<BranchEmployeeProvider>().loadEmployees(widget.branchId);
    }
  }

  /// ============================================
  /// DÉSACTIVER UN EMPLOYÉ (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _deactivateEmployee(EmployeeModel employee) async {
    // Vérifier si l'utilisateur est admin
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut désactiver un employé', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut désactiver
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Désactiver', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment désactiver ${employee.fullName} ?\n\n'
          '⚠️ Cette action va :\n'
          '• Rendre son code d\'accès inutilisable\n'
          '• L\'empêcher de mener des actions dans le système\n'
          '• Conserver ses données (soft delete)\n\n'
          'Vous pourrez le réactiver plus tard.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Désactiver', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchEmployeeProvider>();
      final success = await provider.updateEmployee(
        employeeId: employee.id,
        isActive: false,
      );
      if (success && mounted) {
        // Recharger la liste des employés
        context.read<BranchEmployeeProvider>().loadEmployees(widget.branchId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Employé désactivé. Son code d\'accès n\'est plus utilisable.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// ============================================
  /// RÉACTIVER UN EMPLOYÉ (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _activateEmployee(EmployeeModel employee) async {
    // Vérifier si l'utilisateur est admin
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut réactiver un employé', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut réactiver
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réactiver', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment réactiver ${employee.fullName} ?\n\nSon code d\'accès redeviendra utilisable.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Réactiver', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchEmployeeProvider>();
      final success = await provider.updateEmployee(
        employeeId: employee.id,
        isActive: true,
      );
      if (success && mounted) {
        // Recharger la liste des employés
        context.read<BranchEmployeeProvider>().loadEmployees(widget.branchId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employé réactivé. Son code d\'accès est maintenant utilisable.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// ============================================
  /// ÉDITER UN RÔLE (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _editRole(RoleModel role) async {
    // Vérifier si l'utilisateur est admin
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut modifier un rôle', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut modifier - Naviguer vers la page au lieu d'ouvrir un dialog
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoleScreen(
          branchId: widget.branchId,
          existingRole: role,
        ),
      ),
    );
    
    if (result == true && mounted) {
      // Recharger les rôles si modification réussie
      employeeProvider.loadRoles(widget.branchId);
    }
  }

  /// ============================================
  /// DÉSACTIVER UN RÔLE (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _deactivateRole(RoleModel role) async {
    // Vérifier si l'utilisateur est admin
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut désactiver un rôle', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut désactiver
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Désactiver', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment désactiver le rôle "${role.name}" ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Désactiver', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchEmployeeProvider>();
      final success = await provider.deactivateRole(role.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle désactivé', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// ============================================
// WIDGETS HELPER
// ============================================

/// Carte employé
class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final BranchEmployeeProvider provider;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onActivate;

  const _EmployeeCard({
    required this.employee,
    required this.provider,
    required this.onView,
    required this.onEdit,
    required this.onDeactivate,
    required this.onActivate,
  });

  Widget _buildEmployeePhoto(EmployeeModel employee, {double radius = 30}) {
    if (employee.photo != null && employee.photo!.isNotEmpty) {
      // Vérifier si c'est un chemin de fichier local
      if (employee.photo!.startsWith('/') || employee.photo!.startsWith('file://')) {
        final file = File(employee.photo!.replaceFirst('file://', ''));
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: FileImage(file),
          );
        }
      }
      // Sinon, essayer comme URL réseau
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(employee.photo!),
        onBackgroundImageError: (exception, stackTrace) {
          // En cas d'erreur, l'initiale sera affichée
        },
        child: employee.photo == null
            ? Text(
                employee.firstName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
      );
    }
    // Pas de photo, afficher l'initiale
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        employee.firstName[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo
            _buildEmployeePhoto(employee, radius: 30),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      // Afficher le nom du rôle depuis la liste des rôles si disponible
                      if (employee.roleId != null) {
                        try {
                          final role = provider.roles.firstWhere((r) => r.id == employee.roleId);
                          return Text(
                            role.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          );
                        } catch (e) {
                          // Rôle non trouvé, utiliser roleLabel
                        }
                      }
                      return Text(
                        employee.roleLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        employee.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  // Code département (récupéré depuis le rôle)
                  if (employee.roleId != null) ...[
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        try {
                          final role = provider.roles.firstWhere((r) => r.id == employee.roleId);
                          if (role.departmentCode != null && role.departmentCode!.isNotEmpty) {
                            return Row(
                              children: [
                                Icon(Icons.vpn_key, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Code: ${role.departmentCode}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }
                        } catch (e) {
                          // Rôle non trouvé ou pas de code département
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  // Code d'accès de l'employé
                  if (employee.accessCode != null && employee.accessCode!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_pin, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Accès: ${employee.accessCode}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      employee.isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: employee.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 18),
                      const SizedBox(width: 8),
                      Text('Voir détails', style: GoogleFonts.poppins()),
                    ],
                  ),
                  onTap: onView,
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text('Modifier', style: GoogleFonts.poppins()),
                    ],
                  ),
                  onTap: onEdit,
                ),
                if (employee.isActive)
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Désactiver', style: GoogleFonts.poppins()),
                      ],
                    ),
                    onTap: onDeactivate,
                  )
                else
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Réactiver', style: GoogleFonts.poppins()),
                      ],
                    ),
                    onTap: onActivate,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire d'ajout d'employé
class _AddEmployeeForm extends StatefulWidget {
  final String branchId;

  const _AddEmployeeForm({required this.branchId});

  @override
  State<_AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends State<_AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  String? _selectedRoleId;
  String _contractType = 'CDI';
  DateTime _hireDate = DateTime.now();
  bool _isLoading = false;
  File? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    final provider = context.read<BranchEmployeeProvider>();
    await provider.loadRoles(widget.branchId);
  }

  Future<void> _selectHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _hireDate = picked);
    }
  }

  /// ============================================
  /// SÉLECTIONNER UNE PHOTO DEPUIS LA GALERIE
  /// ============================================
  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de la photo: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.currentUser?.id?.toString() ?? '';

    final provider = context.read<BranchEmployeeProvider>();
    final result = await provider.addEmployee(
      branchId: widget.branchId,
      vendorId: vendorId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      photo: _selectedPhoto?.path, // Chemin de la photo sélectionnée
      roleId: _selectedRoleId,
      // departmentCode sera assigné automatiquement depuis le rôle
      contractType: _contractType,
      salary: _salaryController.text.trim().isEmpty
          ? null
          : double.tryParse(_salaryController.text.trim()),
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      hireDate: _hireDate,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      final accessCode = result['accessCode'] ?? '';
      
      // Afficher le code d'accès généré dans un dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Employé ajouté avec succès !',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le code d\'accès unique de l\'employé est :',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      accessCode,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Copier le code dans le presse-papiers
                        // Note: Nécessite le package clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Code copié : $accessCode', style: GoogleFonts.poppins()),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Important : Notez ce code, il sera nécessaire pour la connexion de l\'employé.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      
      _formKey.currentState!.reset();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _salaryController.clear();
      _emergencyContactController.clear();
      _selectedRoleId = null;
      _selectedPhoto = null;
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prénom
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom *',
                validator: (value) => value?.isEmpty ?? true ? 'Veuillez entrer le prénom' : null,
              ),
              const SizedBox(height: 16),
              // Nom
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom *',
                validator: (value) => value?.isEmpty ?? true ? 'Veuillez entrer le nom' : null,
              ),
              const SizedBox(height: 16),
              // Téléphone
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone *',
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Veuillez entrer le téléphone' : null,
              ),
              const SizedBox(height: 16),
              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email (optionnel)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Photo (optionnel)
              Text(
                'Photo (optionnel)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedPhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Cliquer pour ajouter une photo',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Rôle
              _buildRoleDropdown(provider.roles),
              const SizedBox(height: 16),
              // Type contrat
              _buildContractTypeDropdown(),
              const SizedBox(height: 16),
              // Salaire
              _buildTextField(
                controller: _salaryController,
                label: 'Salaire (FCFA)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Date d'embauche
              InkWell(
                onTap: _selectHireDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Date d\'embauche: ${_hireDate.day}/${_hireDate.month}/${_hireDate.year}',
                          style: GoogleFonts.poppins(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Contact urgence
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Contact urgence (optionnel)',
              ),
              const SizedBox(height: 24),
              // Bouton enregistrer
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Enregistrer', style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
        ),
      ),
      style: GoogleFonts.poppins(color: Colors.black),
    );
  }

  Widget _buildRoleDropdown(List<RoleModel> roles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRoleId,
        decoration: InputDecoration(
          labelText: 'Rôle',
          labelStyle: GoogleFonts.poppins(color: Colors.black),
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(color: Colors.black),
        dropdownColor: Colors.white,
        items: roles.map((role) {
          return DropdownMenuItem(
            value: role.id,
            child: Text(role.name, style: GoogleFonts.poppins(color: Colors.black)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRoleId = value;
            // Le departmentCode sera assigné automatiquement depuis le rôle
          });
        },
        validator: (value) => value == null ? 'Veuillez sélectionner un rôle' : null,
      ),
    );
  }

  Widget _buildContractTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _contractType,
        decoration: InputDecoration(
          labelText: 'Type contrat',
          labelStyle: GoogleFonts.poppins(color: Colors.black),
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(color: Colors.black),
        dropdownColor: Colors.white,
        items: const [
          DropdownMenuItem(value: 'CDI', child: Text('CDI', style: TextStyle(color: Colors.black))),
          DropdownMenuItem(value: 'CDD', child: Text('CDD', style: TextStyle(color: Colors.black))),
          DropdownMenuItem(value: 'Stage', child: Text('Stage', style: TextStyle(color: Colors.black))),
          DropdownMenuItem(value: 'Freelance', child: Text('Freelance', style: TextStyle(color: Colors.black))),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _contractType = value);
          }
        },
      ),
    );
  }
}

/// Carte rôle
class _RoleCard extends StatelessWidget {
  final RoleModel role;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Département: ${role.department}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text('Modifier', style: GoogleFonts.poppins()),
                        ],
                      ),
                      onTap: onEdit,
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.block, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('Désactiver', style: GoogleFonts.poppins()),
                        ],
                      ),
                      onTap: onDeactivate,
                    ),
                  ],
                ),
              ],
            ),
            if (role.permissions != null && role.permissions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: role.permissions!.map((permission) {
                  return Chip(
                    label: Text(permission, style: GoogleFonts.poppins(fontSize: 11)),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: GoogleFonts.poppins(color: Colors.blue.shade700),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte performance
class _PerformanceCard extends StatelessWidget {
  final EmployeeModel employee;
  final int rank;

  const _PerformanceCard({
    required this.employee,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rang
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3 ? Colors.amber.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.amber.shade900 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.roleLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${employee.totalRevenue.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${employee.totalSales} ventes',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

