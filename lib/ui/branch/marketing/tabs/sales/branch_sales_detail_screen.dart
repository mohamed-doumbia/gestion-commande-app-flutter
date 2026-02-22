import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../providers/product_provider.dart';
import '../../../../../providers/order_provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../data/models/product_model.dart';
import '../../../../../data/models/order_model.dart';

/// ============================================
/// PAGE DE DÉTAILS D'UNE SUCCURSALE
/// ============================================
/// Description : Affiche tous les détails d'une succursale :
/// - Produits/stocks avec dates d'ajout
/// - Stock restant
/// - Clients qui ont acheté
/// - Dates d'achat
/// - Chiffre d'affaires généré
class BranchSalesDetailScreen extends StatefulWidget {
  final String branchId;
  final String branchName;

  const BranchSalesDetailScreen({
    Key? key,
    required this.branchId,
    required this.branchName,
  }) : super(key: key);

  @override
  State<BranchSalesDetailScreen> createState() => _BranchSalesDetailScreenState();
}

class _BranchSalesDetailScreenState extends State<BranchSalesDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductProvider>();
    
    final user = authProvider.currentUser;
    if (user?.id != null) {
      await productProvider.loadVendorProducts(user!.id!);
      // TODO: Charger les commandes par succursale
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.branchName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Stocks'),
            Tab(text: 'Ventes'),
            Tab(text: 'Clients'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStocksTab(),
          _buildSalesTab(),
          _buildClientsTab(),
        ],
      ),
    );
  }

  /// ============================================
  /// ONGLET STOCKS
  /// ============================================
  Widget _buildStocksTab() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final allProducts = productProvider.products
            .where((p) => p.branchId == widget.branchId)
            .toList();

        // Filtrer par recherche
        final filteredProducts = _searchQuery.isEmpty
            ? allProducts
            : allProducts.where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        // Filtrer par catégorie
        final products = _selectedCategory == null
            ? filteredProducts
            : filteredProducts.where((p) => p.category == _selectedCategory).toList();

        // Calculer les totaux
        final totalStock = products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
        final totalProducts = products.length;
        final lowStockProducts = products.where((p) => p.stockQuantity <= 5 && p.stockQuantity > 0).length;
        final outOfStockProducts = products.where((p) => p.stockQuantity == 0).length;

        return Column(
          children: [
            // KPIs
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Produits',
                          '$totalProducts',
                          Icons.inventory_2,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Stock Total',
                          '$totalStock',
                          Icons.warehouse,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Stock Faible',
                          '$lowStockProducts',
                          Icons.warning_amber,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Rupture',
                          '$outOfStockProducts',
                          Icons.error_outline,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Barre de recherche et filtre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtre par catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: Text(
                          'Catégorie',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          ...productProvider.categories.map((cat) => DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des produits
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun produit trouvé',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// CARTE PRODUIT
  /// ============================================
  Widget _buildProductCard(ProductModel product) {
    final isLowStock = product.stockQuantity <= 5 && product.stockQuantity > 0;
    final isOutOfStock = product.stockQuantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isOutOfStock
            ? Border.all(color: Colors.red, width: 2)
            : isLowStock
                ? Border.all(color: Colors.orange, width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.red.withOpacity(0.1)
                      : isLowStock
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOutOfStock
                      ? 'Rupture'
                      : isLowStock
                          ? 'Stock faible'
                          : 'Disponible',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOutOfStock
                        ? Colors.red
                        : isLowStock
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProductInfoItem(
                  'Stock',
                  '${product.stockQuantity}',
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildProductInfoItem(
                  'Prix',
                  '${product.price.toStringAsFixed(0)} FCFA',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildProductInfoItem(
                  'Ajouté le',
                  DateFormat('dd/MM/yyyy').format(product.createdAt),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// ONGLET VENTES
  /// ============================================
  Widget _buildSalesTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Filtrer les commandes par succursale
        // TODO: Implémenter le filtrage par succursale dans OrderProvider
        final orders = orderProvider.orders; // Pour l'instant, toutes les commandes

        // Calculer les statistiques
        final totalRevenue = orders
            .where((o) => o.status == 'Livrée')
            .fold<double>(0, (sum, o) => sum + o.totalAmount);
        final totalOrders = orders.length;
        final deliveredOrders = orders.where((o) => o.status == 'Livrée').length;

        return Column(
          children: [
            // KPIs Ventes
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Chiffre d\'affaires',
                          _formatCurrency(totalRevenue),
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Commandes',
                          '$totalOrders',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Commandes livrées',
                    '$deliveredOrders',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Liste des ventes
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune vente enregistrée',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// CARTE COMMANDE
  /// ============================================
  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.clientName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(order.date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOrderInfoItem(
                  'Montant',
                  _formatCurrency(order.totalAmount),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildOrderInfoItem(
                  'Articles',
                  '${order.items.length}',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Livrée':
        return Colors.green;
      case 'En cours':
        return Colors.blue;
      case 'En attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// ============================================
  /// ONGLET CLIENTS
  /// ============================================
  Widget _buildClientsTab() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Extraire les clients uniques qui ont acheté dans cette succursale
        final orders = orderProvider.orders; // TODO: Filtrer par succursale
        final uniqueClients = <String, Map<String, dynamic>>{};

        for (final order in orders) {
          if (!uniqueClients.containsKey(order.clientId)) {
            uniqueClients[order.clientId] = {
              'name': order.clientName,
              'totalOrders': 0,
              'totalSpent': 0.0,
              'lastOrderDate': order.date,
            };
          }
          final clientData = uniqueClients[order.clientId]!;
          clientData['totalOrders'] = (clientData['totalOrders'] as int) + 1;
          clientData['totalSpent'] = (clientData['totalSpent'] as double) + order.totalAmount;
          if (order.date.isAfter(clientData['lastOrderDate'] as DateTime)) {
            clientData['lastOrderDate'] = order.date;
          }
        }

        final clientsList = uniqueClients.values.toList();
        clientsList.sort((a, b) => (b['totalSpent'] as double).compareTo(a['totalSpent'] as double));

        return Column(
          children: [
            // KPI Clients
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: _buildStatCard(
                'Total Clients',
                '${clientsList.length}',
                Icons.people,
                Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            // Liste des clients
            Expanded(
              child: clientsList.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun client enregistré',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: clientsList.length,
                      itemBuilder: (context, index) {
                        final client = clientsList[index];
                        return _buildClientCard(client);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// CARTE CLIENT
  /// ============================================
  Widget _buildClientCard(Map<String, dynamic> client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.purple,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dernier achat: ${DateFormat('dd/MM/yyyy').format(client['lastOrderDate'] as DateTime)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildClientInfoItem(
                  'Commandes',
                  '${client['totalOrders']}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildClientInfoItem(
                  'Total dépensé',
                  _formatCurrency(client['totalSpent'] as double),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// CARTE STATISTIQUE
  /// ============================================
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// FORMATER UNE DEVISE
  /// ============================================
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
