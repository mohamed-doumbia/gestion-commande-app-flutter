import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';

/// Écran détails succursale
class BranchDetailScreen extends StatefulWidget {
  final String branchId;

  const BranchDetailScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BranchModel? _branch;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadBranchDetails();
  }

  void _loadBranchDetails() {
    final branchProvider = context.read<BranchProvider>();
    setState(() {
      _branch = branchProvider.getBranchById(widget.branchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_branch == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Succursale', style: GoogleFonts.poppins()),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: Text('Succursale non trouvée')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête avec infos succursale
          _buildHeader(),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF1E293B),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1E293B),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Vue d\'ensemble'),
                Tab(text: 'Ventes'),
                Tab(text: 'Stock'),
                Tab(text: 'Employés'),
                Tab(text: 'Dépenses'),
                Tab(text: 'Rapports'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildComingSoonTab('Ventes'),
                _buildComingSoonTab('Stock'),
                _buildComingSoonTab('Employés'),
                _buildComingSoonTab('Dépenses'),
                _buildComingSoonTab('Rapports'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre de navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _branch!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _branch!.code,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editBranch,
                  ),
                ],
              ),
            ),

            // Infos rapides
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.location_on,
                      label: 'Localisation',
                      value: '${_branch!.district}, ${_branch!.city}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Contact',
                      value: _branch!.phone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1E293B)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPIs
        _buildSectionTitle('Indicateurs Clés'),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                icon: Icons.shopping_cart,
                label: 'Ventes du jour',
                value: '0',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                icon: Icons.inventory,
                label: 'Produits',
                value: '0',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                icon: Icons.people,
                label: 'Employés',
                value: '0',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                icon: Icons.attach_money,
                label: 'CA du mois',
                value: '0 F',
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Informations détaillées
        _buildSectionTitle('Informations'),
        _buildDetailCard(),

        const SizedBox(height: 24),

        // Coûts d'exploitation
        _buildSectionTitle('Coûts d\'exploitation'),
        _buildCostCard(),

        const SizedBox(height: 24),

        // Actions rapides
        _buildSectionTitle('Actions rapides'),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow('Adresse', _branch!.fullAddress),
            const Divider(height: 24),
            _buildDetailRow('Email', _branch!.email ?? 'Non renseigné'),
            const Divider(height: 24),
            _buildDetailRow(
              'Date d\'ouverture',
              '${_branch!.openingDate.day}/${_branch!.openingDate.month}/${_branch!.openingDate.year}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Statut',
              _branch!.isActive ? 'Actif' : 'Inactif',
              valueColor: _branch!.isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              'Loyer mensuel',
              '${_branch!.monthlyRent.toStringAsFixed(0)} FCFA',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Charges mensuelles',
              '${_branch!.monthlyCharges.toStringAsFixed(0)} FCFA',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Total',
              '${_branch!.monthlyOperatingCost.toStringAsFixed(0)} FCFA',
              valueColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.add_shopping_cart,
          label: 'Nouvelle vente',
          onTap: () => _showComingSoon('Nouvelle vente'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.inventory_2,
          label: 'Gérer le stock',
          onTap: () => _showComingSoon('Gestion du stock'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.person_add,
          label: 'Ajouter un employé',
          onTap: () => _showComingSoon('Ajout employé'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '$tabName',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disponible dans les prochaines phases',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _editBranch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Édition - Disponible prochainement',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature - Disponible dans les prochaines phases',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}