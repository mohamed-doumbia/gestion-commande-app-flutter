import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../data/models/client_stats_model.dart';
import '../../common/chat_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ClientProvider>(context, listen: false).loadClients(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Mes Clients", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- KPIs Clients ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpi("Total Clients", "${clientProvider.totalClients}", Colors.blue),
                _buildKpi("Clients VIP", "${clientProvider.vipClients}", Colors.orange),
                // Le Panier Moyen pourrait être calculé ici
              ],
            ),
          ),

          // --- Liste ---
          Expanded(
            child: clientProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : clientProvider.clients.isEmpty
                ? Center(child: Text("Aucun client pour le moment", style: GoogleFonts.poppins()))
                : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: clientProvider.clients.length,
              itemBuilder: (context, index) {
                final client = clientProvider.clients[index];
                return _buildClientCard(client);
              },
            ),
          ),
        ],
      ),
      // Bouton flottant pour SMS groupé (Simulation future)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Module Marketing SMS (Bientôt disponible)")));
        },
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text("SMS Groupé"),
      ),
    );
  }

  Widget _buildKpi(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildClientCard(ClientStatsModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE2E8F0),
            child: Text(client.name[0].toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(client.phone, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.blue.shade300),
                    Text(" ${client.totalOrders} achats", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade800)),
                    const SizedBox(width: 10),
                    Icon(Icons.monetization_on_outlined, size: 14, color: Colors.green.shade300),
                    Text(" ${client.totalSpent.toStringAsFixed(0)} F", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade800)),
                  ],
                )
              ],
            ),
          ),
          // Bouton Action Rapide
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showContactOptions(context, client),
          )
        ],
      ),
    );
  }

  // --- Le Modal "CRM Ivoirien" ---
  void _showContactOptions(BuildContext context, ClientStatsModel client) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Contacter ${client.name}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildContactBtn(
                        icon: Icons.call,
                        label: "Appeler",
                        color: Colors.green,
                        onTap: () => _launchUrl("tel:${client.phone}")
                    ),
                    _buildContactBtn(
                        icon: Icons.message, // Icone WhatsApp implicite ou Chat
                        label: "WhatsApp",
                        color: const Color(0xFF25D366),
                        onTap: () => _launchWhatsApp(client.phone)
                    ),
                    _buildContactBtn(
                        icon: Icons.sms,
                        label: "SMS",
                        color: Colors.blue,
                        onTap: () => _launchUrl("sms:${client.phone}")
                    ),

                    _buildContactBtn(
                        icon: Icons.chat, // Ou Icons.forum
                        label: "Chat App",
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context); // On ferme le modal avant d'aller au chat
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: client.id, otherUserName: client.name)));
                        }
                    ),
                  ],
                )
              ],
            ),
          );
        }
    );
  }

  Widget _buildContactBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))
        ],
      ),
    );
  }



  // --- Logique Url Launcher ---
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Nettoyage basique du numéro (on suppose format local, on pourrait ajouter +225 si absent)
    // API WhatsApp: https://wa.me/NUMERO
    String cleanPhone = phone.replaceAll(" ", "").replaceAll("-", "");
    if (!cleanPhone.startsWith("+")) {
      cleanPhone = "+225$cleanPhone"; // On force le code pays par défaut pour la CIV
    }

    final Uri url = Uri.parse("https://wa.me/$cleanPhone?text=Bonjour ${Uri.encodeComponent("merci pour votre fidélité !")}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Fallback si l'app n'est pas installée (ouvre le store ou navigateur)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")));
    }
  }
}