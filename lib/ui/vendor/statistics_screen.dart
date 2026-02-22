import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id != null) {
      await Future.wait([
        Provider.of<OrderProvider>(context, listen: false)
            .loadVendorOrders(user!.id!),
        Provider.of<ClientProvider>(context, listen: false)
            .loadClients(user.id ?? ''),
        Provider.of<ProductProvider>(context, listen: false)
            .loadVendorProducts(user.id!),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Statistiques",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer3<OrderProvider, ClientProvider, ProductProvider>(
        builder: (context, orderProvider, clientProvider, productProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chiffre d'affaires
                _buildBigStatCard(
                  "Chiffre d'affaires total",
                  "${orderProvider.totalRevenue.toStringAsFixed(0)} FCFA",
                  Icons.attach_money,
                  Colors.green,
                ),
                const SizedBox(height: 20),

                // Grid des KPIs
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  // --- CORRECTION ICI ---
                  // Un ratio < 1 rend les cartes plus hautes que larges.
                  // Cela donne de la place au texte pour ne pas déborder.
                  childAspectRatio: 0.85,
                  // ---------------------

                  children: [
                    _buildStatCard(
                      "Commandes en attente",
                      "${orderProvider.pendingCount}",
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      "Commandes actives",
                      "${orderProvider.activeOrders.length}",
                      Icons.local_shipping,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      "Total clients",
                      "${clientProvider.totalClients}",
                      Icons.people,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      "Clients VIP",
                      "${clientProvider.vipClients}",
                      Icons.star,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      "Produits",
                      "${productProvider.products.length}",
                      Icons.inventory,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      "Commandes livrées",
                      "${orderProvider.historyOrders.length}",
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBigStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 15),

          // J'ai ajouté FittedBox pour que si le chiffre est énorme (ex: 100000), il rétrécisse au lieu de casser
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Limite à 2 lignes
            overflow: TextOverflow.ellipsis, // Met "..." si c'est trop long
          ),
        ],
      ),
    );
  }
}