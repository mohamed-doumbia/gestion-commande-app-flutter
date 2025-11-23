import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../vendor/home_vendor.dart';
import '../client/home_client.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.storefront, size: 80, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 40),
              Text(
                "Bienvenue !",
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              Text("Connectez-vous pour continuer", style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 30),

              _buildInput("Numéro de téléphone", Icons.phone, _phoneController, isNumber: true),
              _buildInput("Mot de passe", Icons.lock, _passwordController, isPassword: true),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("Se connecter", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pas encore de compte ? ", style: GoogleFonts.poppins()),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text("S'inscrire", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool isPassword = false, bool isNumber = false}) {
    // ... (Même code que dans RegisterScreen pour le style)
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v!.isEmpty ? "Champs requis" : null,
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.login(_phoneController.text, _passwordController.text);

      if (success && mounted) {
        // Redirection Intelligente
        final role = auth.currentUser?.role;
        if (role == 'vendor') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeVendor()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeClient()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec : Vérifiez vos identifiants")));
      }
    }
  }
}