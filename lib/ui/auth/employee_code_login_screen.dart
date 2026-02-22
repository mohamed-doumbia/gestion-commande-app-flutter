import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/branch_employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/role_model.dart';
import '../vendor/home_vendor.dart';
import '../branch/branch_dashboard_screen.dart';
import '../branch/accounting/branch_accounting_screen.dart';
import '../branch/employees/branch_employees_screen.dart';
import '../branch/marketing/branch_marketing_screen.dart';

/// ============================================
/// ÉCRAN DE CONNEXION PAR CODE POUR EMPLOYÉS
/// ============================================
/// Description : Permet aux employés de se connecter avec leur code d'accès unique
/// Formulaire : Code d'accès (4 caractères) + Sélection du magasin
/// Phase : Phase 4 - Authentification employés
class EmployeeCodeLoginScreen extends StatefulWidget {
  const EmployeeCodeLoginScreen({super.key});

  @override
  State<EmployeeCodeLoginScreen> createState() => _EmployeeCodeLoginScreenState();
}

class _EmployeeCodeLoginScreenState extends State<EmployeeCodeLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _selectedBranchId;
  List<BranchModel> _branches = [];
  bool _isLoading = false;
  bool _isLoadingBranches = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// ============================================
  /// CHARGER TOUTES LES SUCCURSALES ACTIVES
  /// ============================================
  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final db = DatabaseHelper.instance;
      final branchesData = await db.getAllActiveBranches();
      _branches = branchesData.map((map) => BranchModel.fromMap(map)).toList();
      
      if (_branches.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune succursale active trouvée';
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des succursales: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des succursales';
      });
    } finally {
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  /// ============================================
  /// VÉRIFIER LE CODE ET CONNECTER L'EMPLOYÉ
  /// ============================================
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBranchId == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner un magasin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employeeProvider = context.read<BranchEmployeeProvider>();
      final code = _codeController.text.trim().toUpperCase();
      
      // Vérifier le code d'accès
      final result = await employeeProvider.verifyEmployeeAccessCode(code, _selectedBranchId!);
      
      if (result != null && mounted) {
        final employee = result['employee'] as EmployeeModel;
        final branch = result['branch'] as BranchModel;
        
        // Connecter l'employé via AuthProvider
        final authProvider = context.read<AuthProvider>();
        await authProvider.loginAsEmployee(employee, branch);
        
        // Récupérer le rôle de l'employé pour déterminer la redirection
        RoleModel? role;
        if (employee.roleId != null) {
          role = await employeeProvider.getRole(employee.roleId!);
        }
        
        // Rediriger selon le rôle
        await _redirectBasedOnRole(employee, branch, role);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Code d\'accès invalide ou employé non trouvé pour ce magasin';
        });
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du code: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la vérification. Veuillez réessayer.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ============================================
  /// REDIRIGER SELON LE RÔLE DE L'EMPLOYÉ
  /// ============================================
  Future<void> _redirectBasedOnRole(EmployeeModel employee, BranchModel branch, RoleModel? role) async {
    // TODO: Implémenter la connexion dans AuthProvider (étape suivante)
    // Pour l'instant, on redirige directement
    
    String? department;
    if (role != null) {
      department = role.department;
    }

    // Redirection selon le département du rôle
    Widget destination;
    
    if (department == 'ADMIN' || (role?.hasPermission('ADMIN') ?? false)) {
      // Admin : Accès complet comme le vendeur
      destination = const HomeVendor();
    } else if (department == 'MANAGER') {
      // Manager : Dashboard avec permissions manager
      destination = BranchDashboardScreen(branchId: branch.id);
    } else if (department == 'COMPTABILITE') {
      // Comptabilité : Page comptabilité
      destination = BranchAccountingScreen(branchId: branch.id);
    } else if (department == 'RH') {
      // RH : Page gestion employés
      destination = BranchEmployeesScreen(branchId: branch.id);
    } else if (department == 'MARKETING') {
      // Marketing : Page marketing
      destination = BranchMarketingScreen(branchId: branch.id);
    } else {
      // Autres départements (EMPLOYER, VENTE, STOCK) ou pas de rôle : Dashboard par défaut
      destination = BranchDashboardScreen(branchId: branch.id);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Connexion par code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Icône
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Titre
                Text(
                  'Connexion employé',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre code d\'accès et sélectionnez votre magasin',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),

                // Champ sélection magasin
                _buildBranchDropdown(),

                const SizedBox(height: 20),

                // Champ code d'accès
                _buildCodeInput(),

                // Message d'erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Bouton vérifier
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLoadingBranches) ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            'Vérifier',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Lien retour
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Retour à la connexion',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// DROPDOWN SÉLECTION MAGASIN
  /// ============================================
  Widget _buildBranchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Magasin',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _isLoadingBranches
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chargement des magasins...',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.store, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  hint: Text(
                    'Sélectionnez votre magasin',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem<String>(
                      value: branch.id,
                      child: Text(
                        branch.name,
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBranchId = value;
                      _errorMessage = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner un magasin';
                    }
                    return null;
                  },
                ),
        ),
      ],
    );
  }

  /// ============================================
  /// CHAMP CODE D'ACCÈS
  /// ============================================
  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code d\'accès',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          obscureText: true,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
            hintText: '••••',
            hintStyle: GoogleFonts.poppins(
              fontSize: 24,
              letterSpacing: 8,
            ),
            counterText: '',
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre code d\'accès';
            }
            if (value.length != 4) {
              return 'Le code doit contenir 4 caractères';
            }
            return null;
          },
          onChanged: (_) {
            setState(() {
              _errorMessage = null;
            });
          },
        ),
      ],
    );
  }
}

