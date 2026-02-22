import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../data/models/client_stats_model.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
    });
  }

  Future<void> _loadClients() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id != null) {
      await Provider.of<ClientProvider>(context, listen: false)
          .loadClients(user!.id ?? '');
    }
  }

  Color _getLevelColor(String colorName) {
    switch (colorName) {
      case 'amber': return Colors.amber;
      case 'yellow': return const Color(0xFFFFD700);
      case 'grey': return Colors.grey;
      default: return const Color(0xFFCD7F32);
    }
  }

  List<ClientStatsModel> _filterClients(List<ClientStatsModel> clients) {
    var filtered = clients;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
      c.name.toLowerCase().contains(_searchQuery) ||
          c.phone.toLowerCase().contains(_searchQuery)).toList();
    }
    if (_filterType == 'vip') {
      filtered = filtered.where((c) => c.isVip).toList();
    } else if (_filterType == 'regular') {
      filtered = filtered.where((c) => !c.isVip).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
          _buildGlobalStats(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                if (clientProvider.isLoading) return const Center(child: CircularProgressIndicator());

                var clients = _filterClients(clientProvider.clients);
                if (clients.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  onRefresh: _loadClients,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: clients.length,
                    itemBuilder: (context, index) => _buildClientCard(clients[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildGlobalStats() {
    return Consumer<ClientProvider>(
      builder: (context, cp, _) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Text("Vue d'ensemble", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("Total", "${cp.totalClients}", Icons.people, Colors.blue),
                _buildStatColumn("VIP", "${cp.vipClients}", Icons.star, Colors.amber),
                _buildStatColumn("Nouveaux", "${cp.newClients}", Icons.person_add, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(hintText: "Rechercher...", border: InputBorder.none, icon: const Icon(Icons.search, color: Colors.grey)),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip("Tous", 'all', Icons.people),
          const SizedBox(width: 10),
          _buildChip("VIP", 'vip', Icons.star),
          const SizedBox(width: 10),
          _buildChip("Réguliers", 'regular', Icons.person),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, IconData icon) {
    bool isSelected = _filterType == value;
    return FilterChip(
      label: Row(children: [Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black), const SizedBox(width: 5), Text(label)]),
      selected: isSelected,
      onSelected: (v) => setState(() => _filterType = value),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildClientCard(ClientStatsModel client) {
    Color levelColor = _getLevelColor(client.levelColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: client.isVip ? Border.all(color: levelColor, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF1E293B),
                child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(client.phone, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 5),
                    if (client.isVip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: levelColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(client.clientLevel, style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callClient(client.phone),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text("Appeler"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMessagingModal(context, client), // MODIFIE ICI
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text("Message"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              IconButton(onPressed: () => _showClientDetails(client), icon: const Icon(Icons.more_vert, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text("Aucun client trouvé", style: GoogleFonts.poppins(color: Colors.grey)));
  }

  // --- ACTIONS ---

  void _callClient(String phone) async {
    final Uri url = Uri.parse("tel:${phone.replaceAll(' ', '')}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  // --- MODAL DETAILS (CORRIGE : SCROLLABLE POUR EVITER OVERFLOW) ---
  void _showClientDetails(ClientStatsModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet de prendre plus de place et d'éviter overflow
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView( // SCROLLABLE ICI
          controller: controller,
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              CircleAvatar(radius: 40, backgroundColor: const Color(0xFF1E293B), child: Text(client.name[0], style: const TextStyle(fontSize: 30, color: Colors.white))),
              const SizedBox(height: 10),
              Text(client.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.phone, "Téléphone", client.phone),
              _buildDetailRow(Icons.shopping_bag, "Commandes", "${client.totalOrders}"),
              _buildDetailRow(Icons.attach_money, "Dépenses", "${client.totalSpent} F"),
              _buildDetailRow(Icons.calendar_today, "Dernière commande", client.lastOrderDate ?? "-"),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer"))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Text("$label:", style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- NOUVEAU MODAL DE MESSAGE (Unique ou Groupé) ---
  void _showMessagingModal(BuildContext context, ClientStatsModel? targetClient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const MessageTypeSelector(),
    );
  }
}

// --- WIDGET SELECTEUR DE TYPE DE MESSAGE ---
class MessageTypeSelector extends StatefulWidget {
  const MessageTypeSelector({super.key});

  @override
  State<MessageTypeSelector> createState() => _MessageTypeSelectorState();
}

class _MessageTypeSelectorState extends State<MessageTypeSelector> {
  int _step = 1;
  String _selectedCountry = 'Côte d\'Ivoire'; // Par défaut
  bool _selectAll = false;

  final List<String> _countries = ['Côte d\'Ivoire', 'Mali', 'Sénégal', 'Burkina Faso'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_step == 2) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 1)),
              Text(_step == 1 ? "Type de message" : "Destinataires ($_selectedCountry)", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _step == 1 ? _buildStep1() : _buildStep2()),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildOptionCard(Icons.person, "Message Unique", "Envoyer un SMS direct", () async {
          // Logique SMS unique
          Navigator.pop(context);
          final Uri smsLaunchUri = Uri(scheme: 'sms'); // Ouvre l'app message vide
          if (await canLaunchUrl(smsLaunchUri)) await launchUrl(smsLaunchUri);
        }),
        const SizedBox(height: 15),
        _buildOptionCard(Icons.groups, "Message Groupé", "Campagne SMS par pays", () {
          setState(() => _step = 2);
        }),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // Liste des pays horizontalement
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _countries.length,
            itemBuilder: (ctx, i) {
              final c = _countries[i];
              final isSel = _selectedCountry == c;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(c),
                  selected: isSel,
                  onSelected: (v) => setState(() => _selectedCountry = c),
                  selectedColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Contacts trouvés: 12"), // Simulation
            TextButton(onPressed: () => setState(() => _selectAll = !_selectAll), child: Text(_selectAll ? "Tout décocher" : "Tout cocher")),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (ctx, i) => CheckboxListTile(
              value: _selectAll,
              onChanged: (v) {},
              title: Text("Client ${i+1}"),
              secondary: const CircleAvatar(child: Icon(Icons.person)),
            ),
          ),
        ),
        SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Envoi groupé simulé !")));
            },
            child: const Text("Envoyer SMS", style: TextStyle(color: Colors.white))
        ))
      ],
    );
  }

  Widget _buildOptionCard(IconData icon, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [
          Icon(icon, size: 30, color: const Color(0xFF1E293B)),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])
        ]),
      ),
    );
  }
}