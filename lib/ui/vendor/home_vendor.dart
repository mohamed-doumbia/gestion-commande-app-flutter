import 'package:flutter/material.dart';
import 'package:gestion_commandes/ui/vendor/stocks/stock_management_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import '../branch/add_branch_screen.dart';
import '../common/chat_screen.dart';
import 'access_codes_screen.dart';
import 'clients/client_list_screen.dart';
import 'orders/vendor_orders_screen.dart';
import 'products/product_list_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';

class HomeVendor extends StatefulWidget {
  const HomeVendor({super.key});

  @override
  State<HomeVendor> createState() => _HomeVendorState();
}

class _HomeVendorState extends State<HomeVendor> {
  @override
  void initState() {
    super.initState();
    // Charger les commandes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<OrderProvider>(context, listen: false).loadVendorOrders(user.id ?? '');
      }
    });
  }

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
                  Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                      return _buildOrdersCard(
                        context,
                        orderProvider,
                        user?.id ?? '',
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
                          builder: (_) => ChatScreen(
                            otherUserId: 'demo-client-id',
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

  Widget _buildOrdersCard(
    BuildContext context,
    OrderProvider orderProvider,
    String vendorId,
  ) {
    final pendingCount = orderProvider.pendingOrders.length;
    final activeCount = orderProvider.activeOrders.length;
    final totalOrders = orderProvider.orders.length;
    
    // Debug logs
    print('📊 Commandes - Total: $totalOrders, En attente: $pendingCount, En cours: $activeCount');
    
    String subtitle;
    if (pendingCount > 0 && activeCount > 0) {
      subtitle = "$pendingCount attente • $activeCount cours";
    } else if (pendingCount > 0) {
      subtitle = "$pendingCount en attente";
    } else if (activeCount > 0) {
      subtitle = "$activeCount en cours";
    } else {
      subtitle = "Aucune commande";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VendorOrdersScreen(),
          ),
        );
      },
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 30,
                    color: Color(0xFF1E293B),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Commandes",
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text('Codes d\'accès', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccessCodesScreen(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              "Supprimer le magasin",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            onTap: () => _showDeleteAccountDialog(context),
          ),

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

  /// Afficher le dialogue de confirmation de suppression
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Supprimer le magasin',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer votre magasin ?',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Cette action va :',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Rendre votre compte inaccessible\n'
                      '• Empêcher toute connexion future\n'
                      '• Conserver toutes vos données en base\n'
                      '• Vous déconnecter immédiatement',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette action est irréversible. Vous devrez créer un nouveau compte pour continuer.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteAccount(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Supprimer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Supprimer le compte et rediriger vers la page de connexion
  Future<void> _deleteAccount(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final success = await authProvider.deleteAccount();

    if (context.mounted) {
      Navigator.pop(context); // Fermer l'indicateur de chargement
      
      if (success) {
        // Rediriger vers la page de connexion
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        
        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Votre magasin a été supprimé avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression. Veuillez réessayer.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}