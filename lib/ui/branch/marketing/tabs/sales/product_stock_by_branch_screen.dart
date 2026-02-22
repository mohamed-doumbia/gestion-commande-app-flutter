import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page pour voir un produit dans tous les magasins
class ProductStockByBranchScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductStockByBranchScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Text(
          'Stock de $productName par magasin\n(À implémenter)',
          style: GoogleFonts.poppins(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

