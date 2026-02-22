import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import 'dart:io';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategoryFilter = 'Tout';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id != null) {
      await Provider.of<ProductProvider>(context, listen: false)
          .loadVendorProducts(user!.id!);
      await Provider.of<ProductProvider>(context, listen: false)
          .loadCategories();
    }
  }

  // didChangeDependencies supprimé - le Consumer<ProductProvider> écoute automatiquement les changements

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Gestion des Stocks",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: "Tous"),
            Tab(text: "Alerte"),
            Tab(text: "Rupture"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(),

          // Filtre par catégorie
          _buildCategoryFilter(),

          // Liste des produits selon l'onglet
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(filter: 'all'),
                _buildProductList(filter: 'low'),
                _buildProductList(filter: 'out'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products;

        final totalProducts = products.length;
        final totalStock =
        products.fold<int>(0, (sum, p) => sum + p.stockQuantity);
        final lowStock =
            products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).length;
        final outOfStock = products.where((p) => p.stockQuantity == 0).length;

        return Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    "Total Produits",
                    "$totalProducts",
                    Icons.inventory,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    "Stock Total",
                    "$totalStock",
                    Icons.warehouse,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    "Alerte Stock",
                    "$lowStock",
                    Icons.warning,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    "Rupture",
                    "$outOfStock",
                    Icons.remove_circle,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final categories = ['Tout', ...productProvider.categories];

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategoryFilter == category;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategoryFilter = category);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF1E293B),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductList({required String filter}) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        var products = productProvider.products;

        // Filtrage par catégorie
        if (_selectedCategoryFilter != 'Tout') {
          products = products
              .where((p) => p.category == _selectedCategoryFilter)
              .toList();
        }

        // Filtrage par type de stock
        switch (filter) {
          case 'low':
            products = products
                .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5)
                .toList();
            break;
          case 'out':
            products = products.where((p) => p.stockQuantity == 0).toList();
            break;
          default:
            break;
        }

        if (products.isEmpty) {
          return _buildEmptyState(filter);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final stockLevel = _getStockLevel(product.stockQuantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: stockLevel.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Image du produit
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(product.images.first),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.inventory,
                          size: 30, color: Colors.grey.shade400);
                    },
                  ),
                )
                    : Icon(Icons.inventory,
                    size: 30, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 15),

              // Infos produit
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${product.price.toInt()} FCFA",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge stock
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: stockLevel.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "${product.stockQuantity}",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: stockLevel.color,
                          ),
                        ),
                        Text(
                          "en stock",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: stockLevel.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    stockLevel.icon,
                    color: stockLevel.color,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAdjustStockDialog(product, decrease: true),
                  icon: const Icon(Icons.remove, size: 18),
                  label: Text(
                    "Retirer",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAdjustStockDialog(product),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    "Ajouter",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'low':
        message = "Aucun produit en alerte stock";
        icon = Icons.check_circle;
        break;
      case 'out':
        message = "Aucun produit en rupture";
        icon = Icons.inventory_2;
        break;
      default:
        message = "Aucun produit";
        icon = Icons.inventory;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(ProductModel product, {bool decrease = false}) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              decrease ? Icons.remove_circle : Icons.add_circle,
              color: decrease ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(
              decrease ? "Retirer du stock" : "Ajouter au stock",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Stock actuel: ${product.stockQuantity}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Quantité",
                hintText: "Ex: 10",
                prefixIcon: Icon(
                  decrease ? Icons.remove : Icons.add,
                  color: decrease ? Colors.red : Colors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: decrease ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Annuler",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Veuillez entrer une quantité valide",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _adjustStock(product, quantity, decrease);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: decrease ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Confirmer",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(
      ProductModel product, int quantity, bool decrease) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id == null) return;

    final newStock = decrease
        ? (product.stockQuantity - quantity).clamp(0, double.infinity).toInt()
        : product.stockQuantity + quantity;

    // Mise à jour via le provider
    await Provider.of<ProductProvider>(context, listen: false)
        .updateProductStock(product.id!, newStock);

    // Recharger les produits
    await Provider.of<ProductProvider>(context, listen: false)
        .loadVendorProducts(user!.id!);

    // Feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decrease
              ? "Stock réduit de $quantity"
              : "Stock augmenté de $quantity",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: decrease ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  StockLevel _getStockLevel(int quantity) {
    if (quantity == 0) {
      return StockLevel(
        color: Colors.red,
        icon: Icons.error,
        label: 'Rupture',
      );
    } else if (quantity <= 5) {
      return StockLevel(
        color: Colors.orange,
        icon: Icons.warning,
        label: 'Alerte',
      );
    } else {
      return StockLevel(
        color: Colors.green,
        icon: Icons.check_circle,
        label: 'Disponible',
      );
    }
  }
}

class StockLevel {
  final Color color;
  final IconData icon;
  final String label;

  StockLevel({
    required this.color,
    required this.icon,
    required this.label,
  });
}