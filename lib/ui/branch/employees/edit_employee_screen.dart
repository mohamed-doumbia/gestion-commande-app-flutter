import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_employee_provider.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/role_model.dart';

/// ============================================
/// PAGE ÉDITION EMPLOYÉ
/// ============================================
class EditEmployeeScreen extends StatefulWidget {
  final String branchId;
  final EmployeeModel employee;

  const EditEmployeeScreen({
    Key? key,
    required this.branchId,
    required this.employee,
  }) : super(key: key);

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employé modifié avec succès !', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retourner true pour indiquer succès
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Modifier Employé',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              controller: _firstNameController,
              label: 'Prénom *',
              icon: Icons.person,
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le prénom' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: 'Nom *',
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le nom' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer le téléphone' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
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
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emergencyContactController,
              label: 'Contact urgence',
              icon: Icons.emergency,
            ),
            const SizedBox(height: 16),
            // Statut actif/inactif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statut',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _isActive ? 'Actif' : 'Inactif',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bouton Enregistrer
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Enregistrer',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1E293B)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.poppins(),
      ),
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
        isExpanded: true, // Évite l'overflow
        decoration: InputDecoration(
          labelText: 'Rôle',
          labelStyle: GoogleFonts.poppins(color: Colors.black),
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(color: Colors.black),
        dropdownColor: Colors.white,
        items: _availableRoles.map((role) {
          return DropdownMenuItem<String>(
            value: role.id,
            child: Text(
              role.name,
              style: GoogleFonts.poppins(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRoleId = value;
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
          labelText: 'Type de contrat',
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
            setState(() {
              _contractType = value;
            });
          }
        },
      ),
    );
  }
}

