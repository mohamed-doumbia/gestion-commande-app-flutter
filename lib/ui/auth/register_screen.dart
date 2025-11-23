import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart'; // Crée un fichier basic avec tes couleurs

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = 'client'; // 'client' ou 'vendor'
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Créer un compte",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                "Créez votre compte pour commencer",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Selecteur de Type de Compte (Custom Widget)
              Text("Type de compte", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildRoleCard('Vendeur', Icons.store, 'vendor')),
                  const SizedBox(width: 15),
                  Expanded(child: _buildRoleCard('Client', Icons.person, 'client')),
                ],
              ),
              const SizedBox(height: 25),

              // Champs
              _buildInput("Nom complet", Icons.person_outline, _nameController),
              _buildInput("Numéro de téléphone", Icons.phone_outlined, _phoneController, isNumber: true),
              _buildInput("Email (optionnel)", Icons.email_outlined, _emailController),

              // Affichage conditionnel pour le Vendeur
              if (_selectedRole == 'vendor')
                _buildInput("Nom de la boutique", Icons.store_mall_directory_outlined, _shopNameController),

              _buildInput("Mot de passe", Icons.lock_outline, _passwordController, isPassword: true),

              const SizedBox(height: 30),

              // Bouton d'inscription
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B), // Bleu foncé
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text("S'inscrire", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                      );
                    }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour le choix Vendeur/Client
  Widget _buildRoleCard(String title, IconData icon, String roleValue) {
    bool isSelected = _selectedRole == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleValue;
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3F5878) : Colors.white, // Couleur active vs inactive
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
            boxShadow: [
              if(isSelected) BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : const Color(0xFF3F5878)),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool isPassword = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                if (label.contains("optionnel")) return null;
                return 'Ce champ est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        fullName: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        shopName: _selectedRole == 'vendor' ? _shopNameController.text : null,
      );

      final success = await Provider.of<AuthProvider>(context, listen: false).register(user);

      if (success) {
        // Navigation vers la page de login ou dashboard
        Navigator.pop(context); // Retour au login pour simplifier
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compte créé ! Connectez-vous.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur : Ce numéro existe peut-être déjà.")));
      }
    }
  }
}