import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_employee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/role_model.dart';

/// ============================================
/// PAGE : AJOUT/ÉDITION DE RÔLE
/// ============================================
/// Description : Page complète pour créer ou modifier un rôle
/// Remplace le modal par une page dédiée
class AddRoleScreen extends StatefulWidget {
  final String branchId;
  final RoleModel? existingRole;

  const AddRoleScreen({
    Key? key,
    required this.branchId,
    this.existingRole,
  }) : super(key: key);

  @override
  State<AddRoleScreen> createState() => _AddRoleScreenState();
}

class _AddRoleScreenState extends State<AddRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedExistingRoleId; // Pour réutiliser un rôle existant
  String _selectedDepartment = 'COMPTABILITE';
  List<String> _selectedPermissions = [];
  bool _isLoading = false;
  bool _isAdmin = false;

  // Liste des départements disponibles
  final List<String> _departments = [
    'COMPTABILITE',
    'RH',
    'VENTE',
    'STOCK',
    'MARKETING',
    'TECHNIQUE',
    'AUTRE',
  ];

  // Liste des permissions disponibles
  final List<String> _availablePermissions = [
    'Voir ventes',
    'Créer ventes',
    'Modifier ventes',
    'Voir stock',
    'Modifier stock',
    'Voir comptabilité',
    'Modifier comptabilité',
    'Voir rapports',
    'Gérer employés',
    'Gérer rôles',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRole != null) {
      _nameController.text = widget.existingRole!.name;
      _selectedDepartment = widget.existingRole!.department;
      _selectedPermissions = widget.existingRole!.permissions ?? [];
    }
    _checkAdminStatus();
  }

  /// Vérifier si l'utilisateur est admin
  Future<void> _checkAdminStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id?.toString() ?? '';
    
    if (userId.isEmpty) {
      setState(() => _isAdmin = false);
      return;
    }
    
    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isAdmin = await employeeProvider.isAdmin(widget.branchId, userId);
    
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// ============================================
  /// SOUMETTRE LE FORMULAIRE
  /// ============================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final createdBy = authProvider.currentUser?.id.toString() ?? 'unknown';

    final provider = context.read<BranchEmployeeProvider>();

    if (widget.existingRole != null) {
      // Mode édition
      final success = await provider.updateRole(
        roleId: widget.existingRole!.id,
        name: _nameController.text.trim(),
        department: _selectedDepartment,
        permissions: _selectedPermissions.isEmpty ? null : _selectedPermissions,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true); // Retourner true pour indiquer succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle modifié avec succès !', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Mode ajout
      final roleId = await provider.createRole(
        branchId: widget.branchId,
        name: _nameController.text.trim(),
        department: _selectedDepartment,
        permissions: _selectedPermissions.isEmpty ? null : _selectedPermissions,
        createdBy: createdBy,
      );

      setState(() => _isLoading = false);

      if (roleId != null && mounted) {
        Navigator.pop(context, true); // Retourner true pour indiquer succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle créé avec succès !', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ============================================
  /// CHARGER UN RÔLE EXISTANT
  /// ============================================
  void _loadExistingRole(String? roleId) {
    if (roleId == null) {
      // Réinitialiser le formulaire
      _nameController.clear();
      _selectedDepartment = 'COMPTABILITE';
      _selectedPermissions = [];
      setState(() {});
      return;
    }

    final provider = context.read<BranchEmployeeProvider>();
    final role = provider.roles.firstWhere((r) => r.id == roleId);
    
    setState(() {
      _nameController.text = role.name;
      _selectedDepartment = role.department;
      _selectedPermissions = role.permissions ?? [];
    });
  }

  /// ============================================
  /// AFFICHER LE DIALOGUE DE SUPPRESSION
  /// ============================================
  Future<void> _showDeleteRoleDialog(BuildContext context, BranchEmployeeProvider provider) async {
    if (_selectedExistingRoleId == null) return;

    final role = provider.roles.firstWhere(
      (r) => r.id == _selectedExistingRoleId,
      orElse: () => RoleModel(
        id: '',
        branchId: widget.branchId,
        name: 'Rôle inconnu',
        department: '',
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimer le rôle',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous vraiment supprimer ce rôle ?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Rôle:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Département:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.department,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action désactivera le rôle. Les employés ayant ce rôle ne pourront plus l\'utiliser.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedExistingRoleId != null) {
      setState(() => _isLoading = true);
      
      final success = await provider.deactivateRole(_selectedExistingRoleId!);
      
      setState(() => _isLoading = false);

      if (success && mounted) {
        // Réinitialiser la sélection
        setState(() {
          _selectedExistingRoleId = null;
          _nameController.clear();
          _selectedDepartment = 'COMPTABILITE';
          _selectedPermissions = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rôle supprimé avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression du rôle',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.existingRole != null ? 'Modifier le rôle' : 'Ajouter un rôle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<BranchEmployeeProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nom du rôle
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du rôle *',
                      labelStyle: GoogleFonts.poppins(color: Colors.black),
                      hintText: 'Ex: Responsable Comptable',
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
                    validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un nom' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown pour sélectionner un rôle existant (uniquement en mode ajout)
                  if (widget.existingRole == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onLongPress: _selectedExistingRoleId != null && _isAdmin
                                ? () => _showDeleteRoleDialog(context, provider)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedExistingRoleId,
                                isExpanded: true, // Évite l'overflow
                                decoration: InputDecoration(
                                  labelText: 'Réutiliser un rôle existant (optionnel)',
                                  labelStyle: GoogleFonts.poppins(color: Colors.black),
                                  border: InputBorder.none,
                                  hintText: _isAdmin && _selectedExistingRoleId != null
                                      ? 'Maintenez pour supprimer'
                                      : null,
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                style: GoogleFonts.poppins(color: Colors.black),
                                dropdownColor: Colors.white,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'Créer un nouveau rôle',
                                      style: TextStyle(color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ...provider.roles.map((role) => DropdownMenuItem<String>(
                                    value: role.id,
                                    child: Text(
                                      '${role.name} (${role.department})',
                                      style: GoogleFonts.poppins(color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExistingRoleId = value;
                                  });
                                  _loadExistingRole(value);
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_selectedExistingRoleId != null && _isAdmin) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Supprimer ce rôle',
                            onPressed: () => _showDeleteRoleDialog(context, provider),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Département
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        labelText: 'Département *',
                        labelStyle: GoogleFonts.poppins(color: Colors.black),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.poppins(color: Colors.black),
                      dropdownColor: Colors.white,
                      items: _departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept, style: GoogleFonts.poppins(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedDepartment = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Permissions
                  Text(
                    'Permissions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: _availablePermissions.map((permission) {
                        final isSelected = _selectedPermissions.contains(permission);
                        return CheckboxListTile(
                          title: Text(
                            permission,
                            style: GoogleFonts.poppins(color: Colors.black),
                          ),
                          value: isSelected,
                          activeColor: const Color(0xFF1E293B),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedPermissions.add(permission);
                              } else {
                                _selectedPermissions.remove(permission);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Bouton Enregistrer
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B), // Fond noir
                      foregroundColor: Colors.white, // Texte blanc
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.existingRole != null ? 'Modifier' : 'Créer',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Bouton Annuler
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF1E293B), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
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

