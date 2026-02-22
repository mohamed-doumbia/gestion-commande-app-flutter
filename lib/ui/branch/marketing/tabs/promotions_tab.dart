import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet 4 : Promotions & Offres
class PromotionsTab extends StatelessWidget {
  final String branchId;

  const PromotionsTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Promotions & Offres\n(À implémenter)',
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

