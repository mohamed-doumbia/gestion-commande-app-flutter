import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
import 'cart_screen.dart'; // On va le créer juste après

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    // Note: Idéalement on chargerait TOUS les produits ou par géolocalisation
    // Ici on charge les produits d'un ID vendeur arbitraire ou tous (simulation)
    // Pour l'exemple, assure-toi d'avoir ajouté des produits côté vendeur
    // Ici on triche un peu pour récupérer la liste stockée en mémoire du provider si déjà chargée
    // Dans une vraie app, on ferait une méthode getAllProducts()
  }

  @override
  Widget build(BuildContext context) {
    // Astuce : On accède à la liste des produits via le provider (assure-toi qu'ils sont chargés)
    final products = Provider.of<ProductProvider>(context).products;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Catalogue", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: products.isEmpty
          ? Center(child: Text("Aucun produit disponible\n(Connectez-vous en vendeur pour en ajouter)", textAlign: TextAlign.center, style: GoogleFonts.poppins()))
          : Padding(
        padding: const EdgeInsets.all(15.0),
        child: GridView.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 colonnes pour mieux voir
            childAspectRatio: 0.75, // Hauteur des cartes
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (ctx, i) => _buildProductItem(context, products[i]),
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel product) {
    bool isOutOfStock = product.stockQuantity <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (Simulée)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Icon(Icons.shopping_bag, size: 50, color: Colors.blue.shade200),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(product.category, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${product.price.toInt()} F", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    GestureDetector(
                      // 1. Logique du clic (C'est bon, tu l'avais bien fait)
                      onTap: isOutOfStock
                          ? null
                          : () {
                        Provider.of<CartProvider>(context, listen: false).addItem(product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("${product.name} ajouté au panier"),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF1E293B),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          // 2. CORRECTION VISUELLE : Gris si vide, Bleu si dispo
                            color: isOutOfStock ? Colors.grey.shade400 : const Color(0xFF1E293B),
                            shape: BoxShape.circle
                        ),
                        child: Icon(
                          // 3. CORRECTION ICONE : Sens interdit si vide, Plus si dispo
                            isOutOfStock ? Icons.block : Icons.add,
                            color: Colors.white,
                            size: 18
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}