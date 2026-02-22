import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page pour comparer les performances entre magasins
class BranchComparisonScreen extends StatelessWidget {
  final String branchId;

  const BranchComparisonScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparaison des Magasins'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Text(
          'Comparaison des performances\n(À implémenter)',
          style: GoogleFonts.poppins(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

