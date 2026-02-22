import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet 3 : Analyse Clients
class ClientAnalysisTab extends StatelessWidget {
  final String branchId;

  const ClientAnalysisTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Analyse Clients\n(À implémenter)',
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

