import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class HomeClient extends StatelessWidget {
  const HomeClient({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.person, color: Colors.black)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bonjour, ${user?.fullName ?? 'Client'}", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.orange, size: 16),
                          Text(" BRONZE 0 pts", style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){}, icon: const Icon(Icons.search)),
                ],
              ),
            ),

            // Liste des options (Scrollable)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildClientCard("Mes Commandes", "0 commandes", Icons.receipt_long, const Color(0xFFE3F2FD)),
                  _buildClientCard("Catalogue Produits", "Découvrez nos produits", Icons.shopping_bag, const Color(0xFFE8F5E9)),
                  _buildClientCard("Messages", "Contactez le vendeur", Icons.chat_bubble_outline, const Color(0xFFE0F2F1)),
                  _buildClientCard("Réservations", "Réserver une place", Icons.calendar_today, const Color(0xFFFFF3E0)),
                ],
              ),
            ),

            // Bloc Statistiques (Bas de page - Bleu foncé)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F5878), // Bleu gris foncé
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mes Statistiques", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("0", "Achats"),
                      _buildStatItem("0 FCFA", "Dépensé"),
                      _buildStatItem("0", "Points"),
                    ],
                  )
                ],
              ),
            ),
            // Bouton déconnexion temporaire pour test
            TextButton.icon(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Déconnexion", style: TextStyle(color: Colors.red))
            )
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(String title, String subtitle, IconData icon, Color iconBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}