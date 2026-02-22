import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../providers/branch_employee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/employee_model.dart';
import 'edit_employee_screen.dart';

/// ============================================
/// PAGE DÉTAILS EMPLOYÉ
/// ============================================
class EmployeeDetailScreen extends StatelessWidget {
  final EmployeeModel employee;
  final String branchId;

  const EmployeeDetailScreen({
    Key? key,
    required this.employee,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Charger les rôles pour pouvoir afficher le nom du rôle
    final employeeProvider = context.read<BranchEmployeeProvider>();
    employeeProvider.loadRoles(branchId);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Détails Employé',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Menu actions (admin seulement)
          Consumer<BranchEmployeeProvider>(
            builder: (context, provider, _) {
              return FutureBuilder<bool>(
                future: _checkAdminStatus(context),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return PopupMenuButton(
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
                          onTap: () => _editEmployee(context),
                        ),
                        if (employee.roleId != null)
                          PopupMenuItem(
                            child: Row(
                              children: [
                                const Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text('Retirer le rôle', style: GoogleFonts.poppins()),
                              ],
                            ),
                            onTap: () => _removeRole(context),
                          ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                employee.isActive ? Icons.block : Icons.check_circle,
                                size: 18,
                                color: employee.isActive ? Colors.orange : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                employee.isActive ? 'Désactiver' : 'Activer',
                                style: GoogleFonts.poppins(
                                  color: employee.isActive ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (employee.isActive) {
                              _deactivateEmployee(context);
                            } else {
                              _activateEmployee(context);
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
                            ],
                          ),
                          onTap: () => _deleteEmployee(context),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header avec photo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Photo
                  _buildPhoto(employee.photo),
                  const SizedBox(height: 16),
                  // Nom
                  Text(
                    employee.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: employee.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      employee.isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: employee.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Informations personnelles
            _buildSection(
              context,
              'Informations Personnelles',
              [
                _buildRoleRow(context),
                _buildInfoRow('Téléphone', employee.phone),
                if (employee.email != null) _buildInfoRow('Email', employee.email!),
                _buildInfoRow('Type contrat', employee.contractType),
                if (employee.salary != null || employee.baseSalary > 0)
                  _buildInfoRow(
                    'Salaire',
                    '${(employee.salary ?? employee.baseSalary).toStringAsFixed(0)} FCFA',
                  ),
                _buildInfoRow(
                  'Date d\'embauche',
                  '${employee.hireDate.day}/${employee.hireDate.month}/${employee.hireDate.year}',
                ),
                if (employee.accessCode != null)
                  _buildInfoRow('Code d\'accès', employee.accessCode!,
                      isImportant: true),
                if (employee.emergencyContact != null)
                  _buildInfoRow('Contact urgence', employee.emergencyContact!),
                if (employee.emergencyPhone != null)
                  _buildInfoRow('Téléphone urgence', employee.emergencyPhone!),
              ],
            ),
            // Performance
            _buildSection(
              context,
              'Performance',
              [
                _buildStatCard(
                  context,
                  'Ventes totales',
                  '${employee.totalSales}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  context,
                  'CA généré',
                  '${employee.totalRevenue.toStringAsFixed(0)} FCFA',
                  Icons.attach_money,
                  Colors.green,
                ),
                if (employee.customerRating != null) ...[
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    'Note clients',
                    '${employee.customerRating!.toStringAsFixed(1)}/5',
                    Icons.star,
                    Colors.orange,
                  ),
                ],
              ],
            ),
            // Congés
            if (employee.annualLeaveDays > 0)
              _buildSection(
                context,
                'Congés',
                [
                  _buildInfoRow('Jours annuels', '${employee.annualLeaveDays} jours'),
                  _buildInfoRow('Jours utilisés', '${employee.usedLeaveDays} jours'),
                  _buildInfoRow('Jours restants', '${employee.annualLeaveDays - employee.usedLeaveDays} jours'),
                  if (employee.sickLeaveDays > 0)
                    _buildInfoRow('Congés maladie', '${employee.sickLeaveDays} jours'),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      // Vérifier si c'est un chemin de fichier local
      if (photoPath.startsWith('/') || photoPath.startsWith('file://')) {
        final file = File(photoPath.replaceFirst('file://', ''));
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: FileImage(file),
          );
        }
      }
      // Sinon, essayer comme URL réseau
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(photoPath),
        onBackgroundImageError: (exception, stackTrace) {
          // En cas d'erreur, afficher l'initiale
        },
      );
    }
    // Pas de photo, afficher l'initiale
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        employee.firstName[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRoleRow(BuildContext context) {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, provider, _) {
        String roleDisplay = employee.roleLabel; // Par défaut, utiliser roleLabel
        
        // Si l'employé a un roleId, chercher le rôle dans la liste
        if (employee.roleId != null && provider.roles.isNotEmpty) {
          try {
            final role = provider.roles.firstWhere(
              (r) => r.id == employee.roleId,
            );
            roleDisplay = '${role.name} (${role.department})';
          } catch (e) {
            // En cas d'erreur, utiliser roleLabel
            roleDisplay = employee.roleLabel;
          }
        }
        
        return _buildInfoRow('Rôle', roleDisplay);
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isImportant
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAdminStatus(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id?.toString() ?? '';
    
    if (userId.isEmpty) return false;
    
    final employeeProvider = context.read<BranchEmployeeProvider>();
    return await employeeProvider.isAdmin(branchId, userId);
  }

  void _editEmployee(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEmployeeScreen(
          branchId: branchId,
          employee: employee,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Recharger les données si nécessaire
        Navigator.pop(context, true); // Retourner à la liste avec un signal de rafraîchissement
      }
    });
  }

  Future<void> _removeRole(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer le rôle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment retirer le rôle de ${employee.fullName} ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Retirer', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchEmployeeProvider>();
      final success = await provider.removeEmployeeRole(employee.id);
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rôle retiré avec succès', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à la liste
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du retrait du rôle', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteEmployee(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer employé', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment supprimer ${employee.fullName} ? Cette action est irréversible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchEmployeeProvider>();
      final success = await provider.deleteEmployee(employee.id);
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Employé supprimé avec succès', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à la liste
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Désactiver un employé
  Future<void> _deactivateEmployee(BuildContext context) async {
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
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Employé désactivé. Son code d\'accès n\'est plus utilisable.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour à la liste avec rafraîchissement
      }
    }
  }

  /// Activer un employé
  Future<void> _activateEmployee(BuildContext context) async {
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
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Employé réactivé. Son code d\'accès est maintenant utilisable.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour à la liste avec rafraîchissement
      }
    }
  }
}

