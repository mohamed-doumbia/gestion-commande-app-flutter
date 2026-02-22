import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/auth_provider.dart';
import 'branch_dashboard_screen.dart';

/// Écran d'ajout de succursale
class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({Key? key}) : super(key: key);

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Nouvelle Succursale',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
            // Section Informations de base
            _buildSectionTitle('Informations de base'),
            _buildTextField(
              controller: _nameController,
              label: 'Nom de la succursale',
              hint: 'Ex: Magasin Cocody',
              icon: Icons.store,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section Localisation
            _buildSectionTitle('Localisation'),
            _buildTextField(
              controller: _countryController,
              label: 'Pays',
              hint: 'Ex: Côte d\'Ivoire',
              icon: Icons.flag,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le pays';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cityController,
              label: 'Ville',
              hint: 'Ex: Abidjan',
              icon: Icons.location_city,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la ville';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _districtController,
              label: 'Quartier/Commune',
              hint: 'Ex: Cocody',
              icon: Icons.apartment,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le quartier';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section Contact
            _buildSectionTitle('Contact'),
            _buildTextField(
              controller: _emailController,
              label: 'Email (optionnel)',
              hint: 'contact@succursale.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            // Bouton Ouvrir succursale existante
            OutlinedButton.icon(
              onPressed: _openExistingBranch,
              icon: const Icon(Icons.folder_open),
              label: Text(
                'Ouvrir succursale existante',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFF1E293B), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton Enregistrer
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBranch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Enregistrer la succursale',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.currentUser?.id;

    if (vendorId == null) {
      _showError('Erreur: Utilisateur non connecté');
      setState(() => _isLoading = false);
      return;
    }

    final branchProvider = context.read<BranchProvider>();

    final branchId = await branchProvider.addBranch(
      vendorId: vendorId,
      name: _nameController.text.trim(),
      // Le code sera généré automatiquement
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      phone: null, // Téléphone retiré du formulaire
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (branchId != null) {
      if (!mounted) return;

      // Afficher message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Succursale créée avec succès !',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Rediriger vers le dashboard de la succursale créée
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BranchDashboardScreen(branchId: branchId),
        ),
      );
    } else {
      _showError('Erreur lors de la création de la succursale');
    }
  }

  /// ============================================
  /// OUVRIR UNE SUCCURSALE EXISTANTE
  /// ============================================
  /// Description : Affiche un dialogue pour saisir le code de la succursale
  /// Si le code existe, redirige vers le dashboard de cette succursale
  Future<void> _openExistingBranch() async {
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ouvrir succursale existante',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez le code de la succursale que vous avez créée précédemment',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code succursale',
                hintText: 'Ex: COC-001',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.poppins(),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            child: Text('Ouvrir', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (result == true && codeController.text.trim().isNotEmpty) {
      final code = codeController.text.trim().toUpperCase();
      
      // Charger toutes les succursales du vendeur depuis la base de données
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.currentUser?.id;
      
      if (vendorId == null) {
        _showError('Erreur: Utilisateur non connecté');
        return;
      }

      // Charger les succursales depuis la BDD
      final branchProvider = context.read<BranchProvider>();
      await branchProvider.loadBranches(vendorId);

      // Chercher la succursale par code
      final branch = branchProvider.getBranchByCode(code);

      if (branch != null) {
        // Succursale trouvée, rediriger vers le dashboard
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BranchDashboardScreen(branchId: branch.id),
          ),
        );
      } else {
        // Code non trouvé
        if (!mounted) return;
        
        _showError('Aucune succursale trouvée avec le code "$code"');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ),
    );
  }
}