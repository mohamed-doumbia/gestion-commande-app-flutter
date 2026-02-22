import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet 6 : Statistiques Marketing
class MarketingStatisticsTab extends StatelessWidget {
  final String branchId;

  const MarketingStatisticsTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Statistiques Marketing\n(À implémenter)',
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

