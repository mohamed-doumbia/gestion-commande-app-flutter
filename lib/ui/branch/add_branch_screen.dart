import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/auth_provider.dart';

/// Écran d'ajout de succursale
class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({Key? key}) : super(key: key);

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _rentController = TextEditingController();
  final _chargesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rentController.dispose();
    _chargesController.dispose();
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
            const SizedBox(height: 16),
            _buildTextField(
              controller: _codeController,
              label: 'Code unique',
              hint: 'Ex: COC-001',
              icon: Icons.qr_code,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un code';
                }
                if (value.length < 3) {
                  return 'Code trop court (min 3 caractères)';
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
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Adresse complète',
              hint: 'Ex: Rue des Jardins, près du carrefour',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une adresse';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Section Contact
            _buildSectionTitle('Contact'),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              hint: '+225 XX XX XX XX XX',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email (optionnel)',
              hint: 'contact@succursale.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            // Section Financier
            _buildSectionTitle('Informations Financières'),
            _buildTextField(
              controller: _rentController,
              label: 'Loyer mensuel (FCFA)',
              hint: '0',
              icon: Icons.home,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _chargesController,
              label: 'Charges mensuelles (FCFA)',
              hint: '0',
              icon: Icons.bolt,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Info facturation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Facturation : 1000 FCFA/mois par succursale',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
      code: _codeController.text.trim().toUpperCase(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      monthlyRent: double.tryParse(_rentController.text) ?? 0.0,
      monthlyCharges: double.tryParse(_chargesController.text) ?? 0.0,
    );

    setState(() => _isLoading = false);

    if (branchId != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Succursale créée avec succès !',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Retour avec succès
    } else {
      _showError('Erreur lors de la création de la succursale');
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