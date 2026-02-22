import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page pour transférer des stocks entre magasins
class StockTransferScreen extends StatelessWidget {
  final String branchId;

  const StockTransferScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfert de Stock'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Text(
          'Transfert de stock entre magasins\n(À implémenter)',
          style: GoogleFonts.poppins(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

