import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = 'client';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Variable pour le numéro complet
  String _fullPhoneNumber = "";

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Créer un compte",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                const SizedBox(height: 10),
                Text("Gérez vos activités en un clin d'oeil",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                Text("Type de compte",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildRoleCard('Vendeur', Icons.store, 'vendor')),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _buildRoleCard('Client', Icons.person, 'client')),
                  ],
                ),
                const SizedBox(height: 25),

                _buildInput("Nom complet", Icons.person_outline, _nameController),

                // CHAMP TÉLÉPHONE AVEC DRAPEAU
                _buildInput("Numéro de téléphone", Icons.phone_outlined,
                    _phoneController,
                    isPhone: true),

                if (_selectedRole == 'vendor')
                  _buildInput("Nom de la boutique",
                      Icons.store_mall_directory_outlined, _shopNameController),

                _buildInput("Email (optionnel)", Icons.email_outlined,
                    _emailController,
                    isEmail: true),
                _buildPasswordInput(
                    "Mot de passe",
                    _passwordController,
                    _obscurePassword,
                        () => setState(() => _obscurePassword = !_obscurePassword)),
                _buildPasswordInput(
                    "Confirmer le mot de passe",
                    _confirmPasswordController,
                    _obscureConfirmPassword,
                        () => setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    isConfirm: true),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : Text(
                          "S'inscrire",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vous avez déjà un compte ? ",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Se connecter",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          color: isSelected ? const Color(0xFF3F5878) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : const Color(0xFF3F5878),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon,
      TextEditingController controller,
      {bool isNumber = false, bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (isPhone)
            IntlPhoneField(
              controller: controller,
              initialCountryCode: 'CI',
              languageCode: 'fr',
              disableLengthCheck: true,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 10),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFF1E293B), width: 2)),
              ),
              onChanged: (phone) {
                _fullPhoneNumber = phone.completeNumber;
              },
            )
          else
            TextFormField(
              controller: controller,
              keyboardType: isNumber
                  ? TextInputType.phone
                  : isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey),
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
                  borderSide: const BorderSide(
                    color: Color(0xFF1E293B),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (label.contains("optionnel")) return null;
                if (value == null || value.isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput(String label, TextEditingController controller,
      bool obscure, VoidCallback toggleVisibility,
      {bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleVisibility,
              ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF1E293B),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              if (!isConfirm && value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              if (isConfirm && value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
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

      // --- LOGIQUE DE SÉCURITÉ ---
      String finalNumber = _fullPhoneNumber;
      if (finalNumber.isEmpty) {
        finalNumber = "+225${_phoneController.text}";
      }

      final user = UserModel(
        fullName: _nameController.text,
        phone: finalNumber, // On envoie le numéro complet
        email: _emailController.text.isEmpty ? null : _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        shopName:
        _selectedRole == 'vendor' ? _shopNameController.text : null,
      );

      final success = await Provider.of<AuthProvider>(context, listen: false)
          .register(user);

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Compte créé ! Connectez-vous.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ce numéro existe peut-être déjà.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}