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
  final TextEditingController _searchController = TextEditingController(); // AJOUT

  @override
  void initState() {
    super.initState();
    _debugAndLoadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose(); // AJOUT
    super.dispose();
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
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
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
                        right: 6,
                        top: 6,
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
                            cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
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
              );
            },
          ),
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
        controller: _searchController, // AJOUT
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim(); // AJOUT trim()
          });
          print('🔍 Recherche: "$_searchQuery"'); // DEBUG
        },
        decoration: InputDecoration(
          hintText: "Rechercher un produit, vendeur, ville...",
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
          // AJOUT: Bouton pour effacer la recherche
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildProductsList(ProductProvider productProvider) {
    final groupedProducts = _filterAndGroupProducts(productProvider);

    print('📊 Produits groupés: ${groupedProducts.length} vendeurs'); // DEBUG

    if (groupedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: groupedProducts.length,
      itemBuilder: (context, index) {
        final vendorId = groupedProducts.keys.elementAt(index);
        final products = groupedProducts[vendorId]!;

        print('✅ Vendeur $vendorId: ${products.length} produits'); // DEBUG

        return VendorProductsSection(
          productsWithVendor: products,
          onProductTap: (product) {
            print('Clic sur produit: ${product.name}');
          },
          onAddToCart: (product) {
            // Debug pour vérifier l'ID du produit
            print('🛒 Tentative d\'ajout au panier: ${product.name}');
            print('   ID produit: ${product.id}');
            print('   ID vendeur: ${product.vendorId}');
            
            final cartProvider = Provider.of<CartProvider>(context, listen: false);
            final itemCountBefore = cartProvider.itemCount;
            
            cartProvider.addItem(product);
            
            // Vérifier si l'ajout a fonctionné
            final itemCountAfter = cartProvider.itemCount;
            
            if (itemCountAfter > itemCountBefore) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Ajouté au panier",
                    style: GoogleFonts.poppins(),
                  ),
                  duration: const Duration(milliseconds: 800),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Erreur: Le produit n'a pas pu être ajouté",
                    style: GoogleFonts.poppins(),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  Map<String, List<ProductWithVendorModel>> _filterAndGroupProducts(
      ProductProvider productProvider) {
    var products = productProvider.productsWithVendor;

    print('🔍 Filtrage - Total produits: ${products.length}'); // DEBUG
    print('🔍 Catégorie sélectionnée: $_selectedCategory'); // DEBUG
    print('🔍 Recherche: "$_searchQuery"'); // DEBUG

    // Filtre par Catégorie
    if (_selectedCategory != 'Tout') {
      products = products
          .where((p) => p.product.category == _selectedCategory)
          .toList();
      print('📁 Après filtre catégorie: ${products.length} produits'); // DEBUG
    }

    // Filtre par Recherche
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final productName = p.product.name.toLowerCase();
        final vendorName = p.vendorInfo.name.toLowerCase();
        final shopName = (p.vendorInfo.shopName ?? '').toLowerCase();
        final city = (p.vendorInfo.city ?? '').toLowerCase();

        final matches = productName.contains(_searchQuery) ||
            vendorName.contains(_searchQuery) ||
            shopName.contains(_searchQuery) ||
            city.contains(_searchQuery);

        if (matches) {
          print('✅ Match: ${p.product.name} - Vendeur: ${p.vendorInfo.name}'); // DEBUG
        }

        return matches;
      }).toList();

      print('🔎 Après recherche: ${products.length} produits'); // DEBUG
    }

    final grouped = productProvider.groupByVendor(products);
    print('👥 Vendeurs après groupement: ${grouped.length}'); // DEBUG

    return grouped;
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
                  _searchController.clear(); // IMPORTANT: Vider le controller
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