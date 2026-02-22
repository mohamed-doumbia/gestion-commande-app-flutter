import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../providers/branch_marketing_provider.dart';
import '../../../../../providers/branch_provider.dart';
import '../../../../../data/models/branch_sales_summary_model.dart';
import 'sales/branch_sales_detail_screen.dart';
import 'sales/branch_comparison_screen.dart';

/// ============================================
/// ONGLET 1 : GESTION DES VENTES
/// ============================================
/// Description : Suivre les stocks et ventes par magasin et ville
/// Phase : Département Marketing - Priorité 1
class SalesManagementTab extends StatefulWidget {
  final String branchId;

  const SalesManagementTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<SalesManagementTab> createState() => _SalesManagementTabState();
}

class _SalesManagementTabState extends State<SalesManagementTab>
    with SingleTickerProviderStateMixin {
  String? _selectedCity;
  String? _selectedBranchId;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final marketingProvider = context.read<BranchMarketingProvider>();
    await marketingProvider.loadBranchSummaries();
    await marketingProvider.loadSalesByBranch();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtres
            _buildFilters(),
            const SizedBox(height: 16),
            
            // KPIs interactifs
            _buildKPIs(),
            const SizedBox(height: 24),
            
            // Graphiques de progression
            _buildProgressCharts(),
            const SizedBox(height: 24),
            
            // Liste des succursales
            _buildBranchesList(),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LES FILTRES (AMÉLIORÉ AVEC RECHERCHE)
  /// ============================================
  Widget _buildFilters() {
    final branchProvider = context.read<BranchProvider>();
    final branches = branchProvider.branches;
    final cities = branches.map((b) => b.city).toSet().toList();

    return Column(
      children: [
        // Barre de recherche
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une succursale...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
            ),
            style: GoogleFonts.poppins(),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Filtre par ville
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    hint: Text(
                      'Toutes les villes',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes les villes'),
                      ),
                      ...cities.map((city) => DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                      final marketingProvider = context.read<BranchMarketingProvider>();
                      marketingProvider.filterByCity(value);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Filtre par succursale
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBranchId,
                    hint: Text(
                      'Toutes les succursales',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes les succursales'),
                      ),
                      ...branches.map((branch) => DropdownMenuItem<String>(
                        value: branch.id,
                        child: Text(branch.name),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBranchId = value;
                      });
                      final marketingProvider = context.read<BranchMarketingProvider>();
                      marketingProvider.filterByBranch(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ============================================
  /// CONSTRUIRE LES KPIs INTERACTIFS
  /// ============================================
  Widget _buildKPIs() {
    return Consumer<BranchMarketingProvider>(
      builder: (context, provider, child) {
        final summaries = provider.branchSummaries;
        
        if (summaries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Aucune donnée disponible',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          );
        }

        // Calculer les totaux
        final totalStock = summaries.fold<int>(0, (sum, s) => sum + s.totalStock);
        final totalRevenue = summaries.fold<double>(0, (sum, s) => sum + s.revenue);
        final totalLowStock = summaries.fold<int>(0, (sum, s) => sum + s.lowStockCount);
        final totalOutOfStock = summaries.fold<int>(0, (sum, s) => sum + s.outOfStockCount);
        
        // Calculer le taux de croissance moyen
        final avgGrowthRate = summaries.isNotEmpty
            ? summaries.fold<double>(0, (sum, s) => sum + s.growthRate) / summaries.length
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Stock Total',
                    _formatNumber(totalStock),
                    'unités',
                    Icons.inventory_2,
                    Colors.blue,
                    onTap: () {
                      // Navigation vers détails stocks
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    'Chiffre d\'affaires',
                    _formatCurrency(totalRevenue),
                    'FCFA',
                    Icons.trending_up,
                    Colors.green,
                    growthRate: avgGrowthRate,
                    onTap: () {
                      // Navigation vers détails ventes
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Stock Faible',
                    '$totalLowStock',
                    'produits',
                    Icons.warning_amber,
                    Colors.orange,
                    onTap: () {
                      // Filtrer les produits en stock faible
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKPICard(
                    'Rupture',
                    '$totalOutOfStock',
                    'produits',
                    Icons.error_outline,
                    Colors.red,
                    onTap: () {
                      // Filtrer les produits en rupture
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// CARTE KPI INDIVIDUELLE (AMÉLIORÉE)
  /// ============================================
  Widget _buildKPICard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    double? growthRate,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (growthRate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: growthRate >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                            size: 14,
                            color: growthRate >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: growthRate >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LES GRAPHIQUES DE PROGRESSION
  /// ============================================
  Widget _buildProgressCharts() {
    return Consumer<BranchMarketingProvider>(
      builder: (context, provider, child) {
        final summaries = provider.branchSummaries;
        
        if (summaries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution des Ventes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildRevenueChart(summaries),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// GRAPHIQUE DE REVENUS (AMÉLIORÉ)
  /// ============================================
  Widget _buildRevenueChart(List<BranchSalesSummaryModel> summaries) {
    if (summaries.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    // Préparer les données pour le graphique avec progression temporelle
    final maxRevenue = summaries.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
    final spots = summaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatCurrency(value),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < summaries.length && value.toInt() >= 0) {
                  final summary = summaries[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      summary.branchName.length > 8
                          ? '${summary.branchName.substring(0, 8)}...'
                          : summary.branchName,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            left: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF1E293B),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF1E293B),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.3),
                  const Color(0xFF1E293B).withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxRevenue * 1.2, // Ajouter 20% d'espace en haut
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF1E293B),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final summary = summaries[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '${summary.branchName}\n${_formatCurrency(touchedSpot.y)}',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// FORMATER UN NOMBRE
  /// ============================================
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// ============================================
  /// FORMATER UNE DEVISE
  /// ============================================
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// ============================================
  /// CONSTRUIRE LA LISTE DES SUCCURSALES (AMÉLIORÉE)
  /// ============================================
  Widget _buildBranchesList() {
    return Consumer<BranchMarketingProvider>(
      builder: (context, provider, child) {
        final summaries = provider.branchSummaries;

        if (summaries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Aucune succursale disponible',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          );
        }

        // Filtrer par recherche
        final filteredSummaries = _searchQuery.isEmpty
            ? summaries
            : summaries.where((s) =>
                s.branchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.district.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Succursales (${filteredSummaries.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BranchComparisonScreen(branchId: widget.branchId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows, size: 18),
                  label: Text(
                    'Comparer',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredSummaries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'Aucune succursale trouvée',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
              )
            else
              ...filteredSummaries.map((summary) => _buildBranchCard(summary)),
          ],
        );
      },
    );
  }

  /// ============================================
  /// CARTE SUCCURSALE
  /// ============================================
  Widget _buildBranchCard(BranchSalesSummaryModel summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BranchSalesDetailScreen(
                  branchId: summary.branchId,
                  branchName: summary.branchName,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.branchName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.location,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: summary.hasAlerts
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        summary.stockStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: summary.hasAlerts ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Stock',
                        '${summary.totalStock}',
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Ventes',
                        '${summary.soldQuantity}',
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'CA',
                        '${summary.revenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                if (summary.hasAlerts) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${summary.lowStockCount} produits en stock faible, ${summary.outOfStockCount} en rupture',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

