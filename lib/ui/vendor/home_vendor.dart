import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../common/chat_screen.dart';
// Assure-toi que les imports correspondent bien à tes dossiers
import 'clients/client_list_screen.dart';
import 'orders/vendor_orders_screen.dart';
import 'products/product_list_screen.dart';

class HomeVendor extends StatelessWidget {
  const HomeVendor({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bonjour,", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
            Text(
              user?.fullName ?? "Vendeur",
              style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            if (user?.shopName != null)
              Text(user!.shopName!, style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.w600)),

            const SizedBox(height: 30),

            // Grille des options
            Expanded(
              child: GridView.count(
                crossAxisCount: 1, // Une colonne (liste verticale)
                mainAxisSpacing: 15,
                childAspectRatio: 2.5, // Format rectangulaire large
                children: [

                  // 1. GESTION COMMANDES
                  _buildDashboardCard(context, "Commandes", "En cours", Icons.shopping_cart_outlined, Colors.blue.shade50, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorOrdersScreen()));
                  }),

                  // 2. GESTION PRODUITS
                  _buildDashboardCard(context, "Produits", "Gérer le stock", Icons.inventory_2_outlined, Colors.green.shade50, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                  }),

                  // 3. GESTION CLIENTS
                  _buildDashboardCard(context, "Clients", "Gérer mon répertoire", Icons.people_outline, Colors.purple.shade50, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientListScreen()));
                  }),

                  // 4. MESSAGES (C'est ici que j'ai corrigé l'erreur)
                  _buildDashboardCard(context, "Messages", "Discussions", Icons.chat_bubble_outline, const Color(0xFFE0F2F1), () {
                    // On ouvre le chat (Ici on simule une discussion avec un client ID 2)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(otherUserId: 2, otherUserName: "Client Démo")));
                  }),

                  // 5. STATISTIQUES (Placeholder)
                  _buildDashboardCard(context, "Statistiques", "Voir les KPI", Icons.bar_chart, Colors.orange.shade50, () {
                    // Nav vers Stats à venir
                  }),

                  // 6. HISTORIQUE (Placeholder)
                  _buildDashboardCard(context, "Historique", "Activités passées", Icons.history, Colors.red.shade50, () {
                    // Nav vers Historique à venir
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Raccourci vers ajout produit ou scanner
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
        },
        label: const Text("Produits"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  // C'est cette méthode que tu dois utiliser partout dans cette classe
  Widget _buildDashboardCard(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
            ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 30, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            accountName: Text(user?.fullName ?? ""),
            accountEmail: Text(user?.phone ?? ""),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Déconnexion", style: TextStyle(color: Colors.red)),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          )
        ],
      ),
    );
  }
}