import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../providers/auth_provider.dart';
import '../vendor/home_vendor.dart';
import '../client/home_client.dart';
import 'register_screen.dart';
import 'employee_code_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Variable pour stocker le numéro complet (+225...)
  String _fullPhoneNumber = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: Color(0xFF1E293B), shape: BoxShape.circle),
                    child: const Icon(Icons.storefront,
                        size: 60, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
                Text("Bienvenue !",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                Text("Connectez-vous pour continuer",
                    style:
                    GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),

                // CHAMP TÉLÉPHONE AVEC DRAPEAU
                _buildInput(
                  "Numéro de téléphone",
                  Icons.phone,
                  _phoneController,
                  isPhone: true,
                ),

                _buildPasswordInput(
                  "Mot de passe",
                  _passwordController,
                  _obscurePassword,
                      () => setState(() => _obscurePassword = !_obscurePassword),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                            : Text("Se connecter",
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pas encore de compte ? ",
                        style: GoogleFonts.poppins()),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: Text("S'inscrire",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                // Séparateur
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OU",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),
                // Bouton connexion par code
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmployeeCodeLoginScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E293B), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.vpn_key,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Connexion par code",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon,
      TextEditingController controller,
      {bool isNumber = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
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
                // On met à jour le numéro complet quand l'utilisateur tape
                _fullPhoneNumber = phone.completeNumber;
              },
            )
          else
            TextFormField(
              controller: controller,
              keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey),
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
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => v!.isEmpty ? "Champ requis" : null,
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput(String label, TextEditingController controller,
      bool obscure, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: toggleVisibility),
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
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (v) => v!.isEmpty ? "Champ requis" : null,
          ),
        ],
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {

      // --- LOGIQUE DE SÉCURITÉ ---
      // Si _fullPhoneNumber est vide (l'utilisateur n'a pas touché au drapeau),
      // on construit le numéro avec le code par défaut CI (+225)
      String finalNumber = _fullPhoneNumber;
      if (finalNumber.isEmpty) {
        finalNumber = "+225${_phoneController.text}";
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);

      // On envoie le numéro complet (ex: +22507...)
      final success = await auth.login(finalNumber, _passwordController.text);

      if (success && mounted) {
        final role = auth.currentUser?.role;
        if (role == 'vendor') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeVendor()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HomeClient()));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Échec : Vérifiez vos identifiants",
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red));
      }
    }
  }
}