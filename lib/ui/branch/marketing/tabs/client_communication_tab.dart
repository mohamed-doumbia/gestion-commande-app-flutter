import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet 5 : Communication Clients
class ClientCommunicationTab extends StatelessWidget {
  final String branchId;

  const ClientCommunicationTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Communication Clients\n(À implémenter)',
        style: GoogleFonts.poppins(),
        textAlign: TextAlign.center,
      ),
    );
  }
}

