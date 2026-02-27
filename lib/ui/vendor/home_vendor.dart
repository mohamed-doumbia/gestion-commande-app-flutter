import 'package:flutter/material.dart';
import 'package:gestion_commandes/ui/vendor/stocks/stock_management_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../branch/add_branch_screen.dart';
import '../common/chat_screen.dart';
import 'clients/client_list_screen.dart';
import 'orders/vendor_orders_screen.dart';
import 'products/product_list_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Recherche (à implémenter)
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour,",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              user?.fullName ?? "Vendeur",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (user?.shopName != null)
              Text(
                user!.shopName!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 30),

            // Grille des options
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 15,
                childAspectRatio: 2.5,
                children: [
                  // 1. GESTION COMMANDES
                  _buildDashboardCard(
                    context,
                    "Commandes",
                    "En cours",
                    Icons.shopping_cart_outlined,
                    Colors.blue.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VendorOrdersScreen(),
                        ),
                      );
                    },
                  ),

                  // 2. GESTION PRODUITS
                  _buildDashboardCard(
                    context,
                    "Produits",
                    "Gérer le catalogue",
                    Icons.inventory_2_outlined,
                    Colors.green.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      );
                    },
                  ),

                  // 3. GESTION DES STOCKS (NOUVEAU)
                  _buildDashboardCard(
                    context,
                    "Stocks",
                    "Gérer les stocks",
                    Icons.warehouse_outlined,
                    Colors.teal.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StockManagementScreen(),
                        ),
                      );
                    },
                  ),

                  // 4. GESTION CLIENTS
                  _buildDashboardCard(
                    context,
                    "Clients",
                    "Gérer mon répertoire",
                    Icons.people_outline,
                    Colors.purple.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientListScreen(),
                        ),
                      );
                    },
                  ),

                  // 5. MESSAGES
                  _buildDashboardCard(
                    context,
                    "Messages",
                    "Discussions",
                    Icons.chat_bubble_outline,
                    const Color(0xFFE0F2F1),
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatScreen(
                            otherUserId: 2,
                            otherUserName: "Client Démo",
                          ),
                        ),
                      );
                    },
                  ),

                  // 6. STATISTIQUES (MAINTENANT FONCTIONNEL)
                  _buildDashboardCard(
                    context,
                    "Statistiques",
                    "Voir les KPI",
                    Icons.bar_chart,
                    Colors.orange.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDashboardCard(
                    context,
                    "Gerer mes succursale",
                    "Manager vos endpoints depuis la maison",
                    Icons.bar_chart,
                    Colors.orange.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddBranchScreen(),
                        ),
                      );
                    },
                  ),

                  // 7. HISTORIQUE (MAINTENANT FONCTIONNEL)
                  _buildDashboardCard(
                    context,
                    "Historique",
                    "Activités passées",
                    Icons.history,
                    Colors.red.shade50,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductListScreen()),
          );
        },
        label: Text(
          "Produits",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color bgColor,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            )
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
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            accountName: Text(
              user?.fullName ?? "Vendeur",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.shopName ?? user?.phone ?? "",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName[0].toUpperCase() ?? 'V',
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

          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text('Commandes', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorOrdersScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.inventory),
            title: Text('Mes Produits', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductListScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.warehouse),
            title: Text('Gestion Stocks', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockManagementScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: Text('Clients', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientListScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text('Statistiques', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: Text('Historique', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: Text(
              "Déconnexion",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
    );
  }
}