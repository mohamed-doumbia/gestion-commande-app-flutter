import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widget/category_filter_widget.dart';
import '../../../widget/vendor_products_section.dart';
import 'cart_screen.dart';
import '../../../data/models/product_with_vendor_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _selectedCategory = 'Tout';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _debugAndLoadProducts();
  }

  Future<void> _debugAndLoadProducts() async {
    await DatabaseHelper.instance.debugDatabase();
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    await Provider.of<ProductProvider>(context, listen: false)
        .loadAllProductsWithVendor();
    await Provider.of<ProductProvider>(context, listen: false)
        .loadCategories();

    final productProvider =
    Provider.of<ProductProvider>(context, listen: false);
    print(
        '🔍 Nombre de produits chargés: ${productProvider.productsWithVendor.length}');

    if (productProvider.productsWithVendor.isNotEmpty) {
      print(
          '✅ Premier produit: ${productProvider.productsWithVendor.first.product.name}');
      print(
          '✅ Vendeur: ${productProvider.productsWithVendor.first.vendorInfo.name}');
    } else {
      print('❌ AUCUN PRODUIT CHARGÉ !');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Catalogue",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.itemCount}',
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
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildSearchBar(),
                CategoryFilterWidget(
                  categories: ['Tout', ...productProvider.categories],
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
                Expanded(
                  child: _buildProductsList(productProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Rechercher un produit, vendeur, ville...",
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductsList(ProductProvider productProvider) {
    final groupedProducts = _filterAndGroupProducts(productProvider);

    if (groupedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: groupedProducts.length,
      itemBuilder: (context, index) {
        final products = groupedProducts.values.elementAt(index);

        return VendorProductsSection(
          productsWithVendor: products,
          onProductTap: (product) {
            print('Clic sur produit: ${product.name}');
          },
          onAddToCart: (product) {
            Provider.of<CartProvider>(context, listen: false).addItem(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Ajouté au panier",
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(milliseconds: 800),
              ),
            );
          },
        );
      },
    );
  }

  Map<int, List<ProductWithVendorModel>> _filterAndGroupProducts(
      ProductProvider productProvider) {
    var products = productProvider.productsWithVendor;

    if (_selectedCategory != 'Tout') {
      products = products
          .where((p) => p.product.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final productName = p.product.name.toLowerCase();
        final productCategory = p.product.category.toLowerCase();
        final vendorName = p.vendorInfo.name.toLowerCase();
        final vendorCity = (p.vendorInfo.city ?? '').toLowerCase();

        return productName.contains(_searchQuery) ||
            productCategory.contains(_searchQuery) ||
            vendorName.contains(_searchQuery) ||
            vendorCity.contains(_searchQuery);
      }).toList();
    }

    return productProvider.groupByVendor(products);
  }

  Widget _buildEmptyState() {
    final hasFilters = _selectedCategory != 'Tout' || _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? "Aucun résultat" : "Aucun produit disponible",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? "Essayez d'autres filtres"
                : "Les produits apparaîtront ici",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Tout';
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Réinitialiser les filtres",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}