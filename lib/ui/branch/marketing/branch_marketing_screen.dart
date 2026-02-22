import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_marketing_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/department_drawer.dart';
import 'tabs/sales_management_tab.dart';
import 'tabs/marketing_campaigns_tab.dart';
import 'tabs/client_analysis_tab.dart';
import 'tabs/promotions_tab.dart';
import 'tabs/client_communication_tab.dart';
import 'tabs/marketing_statistics_tab.dart';
import 'tabs/social_media_tab.dart';
import 'tabs/excel_upload_tab.dart';

/// ============================================
/// PAGE MARKETING SUCCURSALE
/// ============================================
/// Description : Gestion complète du marketing d'une succursale
/// Phase : Département Marketing
/// Contenu : 8 onglets (7 fonctionnels + 1 upload Excel)
class BranchMarketingScreen extends StatefulWidget {
  final String branchId;

  const BranchMarketingScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<BranchMarketingScreen> createState() => _BranchMarketingScreenState();
}

class _BranchMarketingScreenState extends State<BranchMarketingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 8 onglets : 7 fonctionnels + 1 upload Excel
    _tabController = TabController(length: 8, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================
  /// CHARGER LES DONNÉES INITIALES
  /// ============================================
  Future<void> _loadData() async {
    final marketingProvider = context.read<BranchMarketingProvider>();
    await marketingProvider.loadBranchSummaries();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.currentEmployee;
    final branch = authProvider.currentEmployeeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DepartmentDrawer(
        departmentName: 'Marketing',
        employeeName: employee?.fullName,
        branchName: branch?.name,
      ),
      appBar: AppBar(
        title: Text(
          'Marketing',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Gestion Ventes'),
            Tab(text: 'Campagnes'),
            Tab(text: 'Analyse Clients'),
            Tab(text: 'Promotions'),
            Tab(text: 'Communication'),
            Tab(text: 'Statistiques'),
            Tab(text: 'Réseaux Sociaux'),
            Tab(text: 'Import Excel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1 : Gestion des Ventes
          SalesManagementTab(branchId: widget.branchId),
          
          // Onglet 2 : Campagnes Marketing
          MarketingCampaignsTab(branchId: widget.branchId),
          
          // Onglet 3 : Analyse Clients
          ClientAnalysisTab(branchId: widget.branchId),
          
          // Onglet 4 : Promotions & Offres
          PromotionsTab(branchId: widget.branchId),
          
          // Onglet 5 : Communication Clients
          ClientCommunicationTab(branchId: widget.branchId),
          
          // Onglet 6 : Statistiques Marketing
          MarketingStatisticsTab(branchId: widget.branchId),
          
          // Onglet 7 : Réseaux Sociaux & Publicité
          SocialMediaTab(branchId: widget.branchId),
          
          // Onglet 8 : Import Excel (clients/ventes)
          ExcelUploadTab(branchId: widget.branchId),
        ],
      ),
    );
  }
}

