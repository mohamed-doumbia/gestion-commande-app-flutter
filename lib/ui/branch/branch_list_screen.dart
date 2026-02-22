import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/auth_provider.dart';
import 'add_branch_screen.dart';
import 'branch_detail_screen.dart';
import 'branch_dashboard_screen.dart';


/// Écran liste des succursales
class BranchesListScreen extends StatefulWidget {
  const BranchesListScreen({Key? key}) : super(key: key);

  @override
  State<BranchesListScreen> createState() => _BranchesListScreenState();
}

class _BranchesListScreenState extends State<BranchesListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.currentUser?.id;

    if (vendorId != null) {
      await context.read<BranchProvider>().loadBranches(vendorId as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Mes Succursales',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // TODO: Ajouter bouton carte en Phase 1.2
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Vue carte',
            onPressed: () {
              // TODO: Naviguer vers BranchesMapScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vue carte - Bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBranches,
        child: Consumer<BranchProvider>(
          builder: (context, branchProvider, child) {
            if (branchProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final branches = _searchQuery.isEmpty
                ? branchProvider.activeBranches
                : branchProvider.searchBranches(_searchQuery);

            return Column(
              children: [
                // Barre de recherche
                _buildSearchBar(),

                // KPIs
                _buildKPIs(branchProvider),

                // Liste des succursales
                Expanded(
                  child: branches.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      return _buildBranchCard(branch);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddBranch(),
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.add),
        label: Text(
          'Nouvelle Succursale',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher une succursale...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildKPIs(BranchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              icon: Icons.store,
              label: 'Total',
              value: '${provider.activeBranchCount}',
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKPICard(
              icon: Icons.attach_money,
              label: 'Facturation',
              value: '${provider.activeBranchCount * 1000} F',
              color: Colors.orange,
            ),
          ),
        ],
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
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(branch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Color(0xFF1E293B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        branch.code,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 🆕 ICÔNES ÉDITER ET SUPPRIMER
                Row(
                  children: [
                    // Bouton Éditer
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editBranch(branch),
                      tooltip: 'Modifier',
                    ),
                    // Bouton Supprimer
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteBranch(branch),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${branch.district}, ${branch.city}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  branch.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coût mensuel: ${branch.monthlyOperatingCost.toStringAsFixed(0)} F',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                // Bouton voir détails
                InkWell(
                  onTap: () => _navigateToBranchDetail(branch.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Détails',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// 🆕 AJOUTER CES MÉTHODES À LA FIN DE LA CLASSE

  void _editBranch(branch) {
    // TODO: Naviguer vers écran d'édition (Phase future)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Édition disponible prochainement',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _confirmDeleteBranch(branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer la succursale',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${branch.name}" ?\n\nCette action est irréversible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBranch(branch.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBranch(String branchId) async {
    final branchProvider = context.read<BranchProvider>();
    final success = await branchProvider.deleteBranch(branchId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Succursale supprimée',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la suppression',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Aucune succursale'
                : 'Aucun résultat',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Ajoutez votre première succursale'
                : 'Essayez un autre terme',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddBranch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBranchScreen()),
    );

    if (result == true) {
      _loadBranches();
    }
  }

  void _navigateToBranchDetail(String branchId) {
    // Rediriger vers le nouveau dashboard succursale (Phase 2)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDashboardScreen(branchId: branchId),
      ),
    );
  }
}