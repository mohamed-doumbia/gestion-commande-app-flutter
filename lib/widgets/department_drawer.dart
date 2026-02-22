import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/employee_code_login_screen.dart';

/// ============================================
/// WIDGET : DRAWER POUR PAGES DÉPARTEMENT
/// ============================================
/// Description : Drawer réutilisable pour toutes les pages de département
/// Permet la déconnexion et la fermeture de l'app

class DepartmentDrawer extends StatelessWidget {
  final String departmentName;
  final String? employeeName;
  final String? branchName;

  const DepartmentDrawer({
    Key? key,
    required this.departmentName,
    this.employeeName,
    this.branchName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isEmployeeSession = authProvider.isEmployeeSession;
    final employee = authProvider.currentEmployee;
    final branch = authProvider.currentEmployeeBranch;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            accountName: Text(
              employeeName ?? employee?.fullName ?? 'Employé',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              branchName ?? branch?.name ?? departmentName,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (employeeName ?? employee?.fullName ?? 'E')[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: Text('Accueil', style: GoogleFonts.poppins()),
            onTap: () => Navigator.pop(context),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: Text(
              'Déconnexion',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation(context, isEmployeeSession);
            },
          ),

          ListTile(
            leading: const Icon(Icons.close, color: Colors.orange),
            title: Text(
              'Quitter l\'application',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
            onTap: () {
              Navigator.pop(context);
              _showExitConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONFIRMATION DE DÉCONNEXION
  /// ============================================
  void _showLogoutConfirmation(BuildContext context, bool isEmployeeSession) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Déconnexion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              
              // Rediriger vers la page de connexion appropriée
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => isEmployeeSession
                      ? const EmployeeCodeLoginScreen()
                      : const LoginScreen(),
                ),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Déconnexion',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONFIRMATION DE FERMETURE DE L'APP
  /// ============================================
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Quitter l\'application',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir quitter l\'application ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Fermer l'application
              // Note: Cette fonctionnalité nécessite import 'dart:io' et SystemNavigator.pop()
              // Pour Android/iOS, on peut utiliser exit(0) mais ce n'est pas recommandé
              // La meilleure pratique est de laisser l'OS gérer la fermeture
              // Ici, on déconnecte simplement et retourne à la page de login
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(
              'Quitter',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

