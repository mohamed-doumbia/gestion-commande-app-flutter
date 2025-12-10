import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_order_provider.dart'; // <--- Import
import '../auth/login_screen.dart';
import 'orders/lient_orders_screen.dart';
import 'shop/catalog_screen.dart';


class HomeClient extends StatefulWidget {
  const HomeClient({super.key});

  @override
  State<HomeClient> createState() => _HomeClientState();
}

class _HomeClientState extends State<HomeClient> {

  @override
  void initState() {
    super.initState();
    // Recharger les données à chaque fois qu'on arrive sur l'accueil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ClientOrderProvider>(context, listen: false).loadClientOrders(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    // On écoute les changements des commandes pour mettre à jour les stats
    final orderData = Provider.of<ClientOrderProvider>(context);

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
                          // Affichage dynamique du niveau (Bronze, Argent...)
                          Text(" ${getLoyaltyStatus(orderData.loyaltyPoints)} ${orderData.loyaltyPoints} pts",
                              style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                      onPressed: () {
                        Provider.of<AuthProvider>(context, listen: false).logout();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      },
                      icon: const Icon(Icons.logout, color: Colors.red)
                  ),
                ],
              ),
            ),

            // Liste des options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildClientCard(
                      "Mes Commandes",
                      "${orderData.activeOrdersCount} en cours", // Dynamique
                      Icons.receipt_long,
                      const Color(0xFFE3F2FD),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersScreen()))
                  ),
                  _buildClientCard(
                      "Catalogue Produits",
                      "Découvrez nos produits",
                      Icons.shopping_bag,
                      const Color(0xFFE8F5E9),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()))
                  ),
                  _buildClientCard("Messages", "Contactez le vendeur", Icons.chat_bubble_outline, const Color(0xFFE0F2F1)),
                  _buildClientCard("Réservations", "Réserver une place", Icons.calendar_today, const Color(0xFFFFF3E0)),
                ],
              ),
            ),

            // Bloc Statistiques DYNAMIQUE
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3F5878),
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
                      _buildStatItem("${orderData.totalOrdersCount}", "Achats (Livrés)"),
                      _buildStatItem("${orderData.totalSpent.toStringAsFixed(0)} F", "Dépensé"),
                      _buildStatItem("${orderData.loyaltyPoints}", "Points"),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getLoyaltyStatus(int points) {
    if (points >= 50) return "OR";
    if (points >= 20) return "ARGENT";
    return "BRONZE";
  }

  Widget _buildClientCard(String title, String subtitle, IconData icon, Color iconBg, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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