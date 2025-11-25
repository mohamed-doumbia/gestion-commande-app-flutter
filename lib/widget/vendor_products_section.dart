import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/product_with_vendor_model.dart';
import '../data/models/product_model.dart';
import 'product_card_widget.dart';

class VendorProductsSection extends StatelessWidget {
  final List<ProductWithVendorModel> productsWithVendor;
  final Function(ProductModel) onProductTap;
  final Function(ProductModel) onAddToCart;

  const VendorProductsSection({
    Key? key,
    required this.productsWithVendor,
    required this.onProductTap,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (productsWithVendor.isEmpty) return const SizedBox.shrink();

    final vendorInfo = productsWithVendor.first.vendorInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête vendeur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E293B),
                  radius: 25,
                  child: Text(
                    vendorInfo.name[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorInfo.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendorInfo.location,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${productsWithVendor.length} produits",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigation vers page vendeur (à implémenter)
                  },
                  child: Text(
                    "Voir tout",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Liste horizontale des produits
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: productsWithVendor.length,
              itemBuilder: (context, index) {
                final productWithVendor = productsWithVendor[index];
                return ProductCardWidget(
                  product: productWithVendor.product,
                  onTap: () => onProductTap(productWithVendor.product),
                  onAddToCart: () => onAddToCart(productWithVendor.product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}