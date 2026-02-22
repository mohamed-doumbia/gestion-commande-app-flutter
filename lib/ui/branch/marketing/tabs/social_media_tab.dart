import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet 7 : Réseaux Sociaux & Publicité
class SocialMediaTab extends StatelessWidget {
  final String branchId;

  const SocialMediaTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Réseaux Sociaux & Publicité\n(À implémenter)',
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

