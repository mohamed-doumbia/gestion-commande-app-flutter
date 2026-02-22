import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../providers/branch_employee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/role_model.dart';

// ============================================
// DIALOGUE DÉTAILS EMPLOYÉ
// ============================================
class EmployeeDetailDialog extends StatelessWidget {
  final EmployeeModel employee;

  const EmployeeDetailDialog({required this.employee});

  Widget _buildEmployeePhoto(EmployeeModel employee, {double radius = 40}) {
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
                  fontSize: radius * 0.8,
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
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Détails Employé',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo et nom
            Center(
              child: Column(
                children: [
                  _buildEmployeePhoto(employee, radius: 40),
                  const SizedBox(height: 12),
                  Text(
                    employee.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: employee.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      employee.isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: employee.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Informations
            _buildDetailRow('Rôle', employee.roleLabel),
            const SizedBox(height: 12),
            _buildDetailRow('Téléphone', employee.phone),
            if (employee.email != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Email', employee.email!),
            ],
            const SizedBox(height: 12),
            _buildDetailRow('Type contrat', employee.contractType),
            if (employee.salary != null || employee.baseSalary > 0) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Salaire',
                '${(employee.salary ?? employee.baseSalary).toStringAsFixed(0)} FCFA',
              ),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
              'Date d\'embauche',
              '${employee.hireDate.day}/${employee.hireDate.month}/${employee.hireDate.year}',
            ),
            if (employee.departmentCode != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Code département', employee.departmentCode!),
            ],
            if (employee.emergencyContact != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Contact urgence', employee.emergencyContact!),
            ],
            // Performance
            const SizedBox(height: 24),
            Text(
              'Performance',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Ventes', '${employee.totalSales}', Icons.shopping_cart),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'CA généré',
                    '${employee.totalRevenue.toStringAsFixed(0)} F',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DIALOGUE ÉDITION EMPLOYÉ
// ============================================
class EditEmployeeDialog extends StatefulWidget {
  final String branchId;
  final EmployeeModel employee;
  final VoidCallback onSaved;

  const EditEmployeeDialog({
    required this.branchId,
    required this.employee,
    required this.onSaved,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String? _selectedRoleId;
  String _contractType = 'CDI';
  bool _isActive = true;
  bool _isLoading = false;

  List<RoleModel> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs
    _firstNameController.text = widget.employee.firstName;
    _lastNameController.text = widget.employee.lastName;
    _phoneController.text = widget.employee.phone;
    _emailController.text = widget.employee.email ?? '';
    _salaryController.text = (widget.employee.salary ?? widget.employee.baseSalary).toStringAsFixed(0);
    _emergencyContactController.text = widget.employee.emergencyContact ?? '';
    _selectedRoleId = widget.employee.roleId;
    _contractType = widget.employee.contractType;
    _isActive = widget.employee.isActive;
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
    if (mounted) {
      setState(() {
        _availableRoles = provider.roles;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<BranchEmployeeProvider>();
    final success = await provider.updateEmployee(
      employeeId: widget.employee.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      roleId: _selectedRoleId,
      // departmentCode sera assigné automatiquement depuis le rôle
      contractType: _contractType,
      salary: _salaryController.text.trim().isEmpty
          ? null
          : double.tryParse(_salaryController.text.trim()),
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      isActive: _isActive,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employé modifié avec succès !', style: GoogleFonts.poppins()),
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier Employé',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom *',
                validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le prénom' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom *',
                validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le nom' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone *',
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le téléphone' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 16),
              _buildContractTypeDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _salaryController,
                label: 'Salaire (FCFA)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Contact urgence',
              ),
              const SizedBox(height: 16),
              // Statut actif/inactif
              Row(
                children: [
                  Text(
                    'Statut: ',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  Text(
                    _isActive ? 'Actif' : 'Inactif',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Modifier', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
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

  Widget _buildRoleDropdown() {
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
        items: _availableRoles.map((role) {
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

// ============================================
// DIALOGUE AJOUT/ÉDITION RÔLE
// ============================================
class RoleDialog extends StatefulWidget {
  final String branchId;
  final RoleModel? existingRole;
  final VoidCallback onSaved;

  const RoleDialog({
    required this.branchId,
    this.existingRole,
    required this.onSaved,
  });

  @override
  State<RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedDepartment = 'COMPTABILITE';
  List<String> _selectedPermissions = [];
  bool _isLoading = false;

  // Liste des départements disponibles
  final List<String> _departments = [
    'COMPTABILITE',
    'RH',
    'VENTE',
    'STOCK',
    'MARKETING',
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
        Navigator.pop(context);
        widget.onSaved();
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
        Navigator.pop(context);
        widget.onSaved();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingRole != null ? 'Modifier le rôle' : 'Ajouter un rôle',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    return DropdownMenuItem(
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
              const SizedBox(height: 16),
              // Permissions
              Text(
                'Permissions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: _availablePermissions.map((permission) {
                      return CheckboxListTile(
                        title: Text(permission, style: GoogleFonts.poppins(fontSize: 13)),
                        value: _selectedPermissions.contains(permission),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedPermissions.add(permission);
                            } else {
                              _selectedPermissions.remove(permission);
                            }
                          });
                        },
                        activeColor: const Color(0xFF1E293B),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  widget.existingRole != null ? 'Modifier' : 'Créer',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                ),
        ),
      ],
    );
  }
}

