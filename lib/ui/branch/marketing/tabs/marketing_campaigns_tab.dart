import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../providers/marketing_expense_provider.dart';
import '../../../../../utils/period_helper.dart';
import 'expenses/add_expense_screen.dart';

/// ============================================
/// ONGLET 2 : PLANIFICATION DES DÉPENSES MARKETING
/// ============================================
/// Description : Planifier les dépenses marketing par catégorie pour une période
/// Phase : Département Marketing
class MarketingCampaignsTab extends StatefulWidget {
  final String branchId;

  const MarketingCampaignsTab({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<MarketingCampaignsTab> createState() => _MarketingCampaignsTabState();
}

class _MarketingCampaignsTabState extends State<MarketingCampaignsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedPeriodType = 'month'; // 'week', 'month', 'year'
  DateTime _selectedPeriodStart = DateTime.now();
  DateTime _selectedPeriodEnd = DateTime.now();

  // Map pour stocker les montants planifiés par catégorie
  Map<String, double> _plannedExpenses = {};
  Map<String, String> _customCategories = {}; // Pour les catégories "Autres"

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
    _initializePeriod();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialiser la période selon le type
  void _initializePeriod() {
    final periodDates = PeriodHelper.calculatePeriodDates(
      periodType: _selectedPeriodType,
    );
    _selectedPeriodStart = periodDates['start']!;
    _selectedPeriodEnd = periodDates['end']!;
  }

  /// Charger les données planifiées
  Future<void> _loadData() async {
    final provider = context.read<MarketingExpenseProvider>();
    await provider.loadExpenses(
      branchId: widget.branchId,
      startDate: _selectedPeriodStart,
      endDate: _selectedPeriodEnd,
    );
    
    // Grouper les dépenses par catégorie
    _plannedExpenses.clear();
    for (final expense in provider.expenses) {
      _plannedExpenses[expense.category] = 
          (_plannedExpenses[expense.category] ?? 0.0) + expense.amount;
    }
    
    _animationController.forward();
    setState(() {});
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
            // Sélecteur de période (sans dates)
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // Vue d'ensemble : Dépenses totales par catégorie
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildOverview(),
            ),
            const SizedBox(height: 24),

            // Liste des catégories pour planification
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCategoryPlanningList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélecteur de période (sans dates affichées)
  Widget _buildPeriodSelector() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriodType,
                  isExpanded: true,
                  items: PeriodHelper.periodTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(PeriodHelper.getPeriodTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriodType = value;
                        _initializePeriod();
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                final prevPeriod = PeriodHelper.getPreviousPeriod(
                  periodType: _selectedPeriodType,
                  currentStart: _selectedPeriodStart,
                );
                _selectedPeriodStart = prevPeriod['start']!;
                _selectedPeriodEnd = prevPeriod['end']!;
              });
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                final nextPeriod = PeriodHelper.getNextPeriod(
                  periodType: _selectedPeriodType,
                  currentStart: _selectedPeriodStart,
                );
                _selectedPeriodStart = nextPeriod['start']!;
                _selectedPeriodEnd = nextPeriod['end']!;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  /// Vue d'ensemble : Dépenses totales par catégorie
  Widget _buildOverview() {
    final total = _plannedExpenses.values.fold<double>(0.0, (sum, amount) => sum + amount);

    return Container(
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
          Text(
            'Vue d\'ensemble',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (_plannedExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune dépense planifiée',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Graphique camembert
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPieChart(),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildCategoryLegend(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total planifié',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_formatCurrency(total)} FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Graphique camembert
  Widget _buildPieChart() {
    if (_plannedExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];

    final total = _plannedExpenses.values.fold<double>(0.0, (sum, amount) => sum + amount);
    final entries = _plannedExpenses.entries.toList();
    
    final pieChartData = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;

      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieChartData,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  /// Légende des catégories
  Widget _buildCategoryLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];

    final entries = _plannedExpenses.entries.toList();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value.key;
        final amount = entry.value.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.length > 15 ? '${category.substring(0, 15)}...' : category,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatCurrency(amount),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Liste des catégories pour planification
  Widget _buildCategoryPlanningList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Planification par catégorie',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...MarketingExpenseProvider.categories.map((category) {
          return _buildCategoryCard(category);
        }),
      ],
    );
  }

  /// Carte pour une catégorie
  Widget _buildCategoryCard(String category) {
    final isOther = category == 'Autres dépenses';
    final plannedAmount = _plannedExpenses[category] ?? 0.0;
    final customCategoryName = _customCategories[category];

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOther && customCategoryName != null 
                            ? customCategoryName 
                            : category,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plannedAmount > 0)
                        Text(
                          'Planifié : ${_formatCurrency(plannedAmount)} FCFA',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (plannedAmount > 0)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editCategoryExpense(category),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isOther && customCategoryName == null)
              _buildCustomCategoryInput(category)
            else
              _buildAmountInput(category, isOther),
          ],
        ),
      ),
    );
  }

  /// Champ pour saisir le nom de la catégorie personnalisée
  Widget _buildCustomCategoryInput(String category) {
    final controller = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'Ex: Sponsoring',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onFieldSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _customCategories[category] = value;
              });
            }
          },
        ),
      ],
    );
  }

  /// Champ pour saisir le montant
  Widget _buildAmountInput(String category, bool isOther) {
    final amountController = TextEditingController(
      text: _plannedExpenses[category] != null && _plannedExpenses[category]! > 0
          ? _plannedExpenses[category]!.toStringAsFixed(0)
          : '',
    );
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    DateTime selectedDate = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                    });
                  }
                },
                child: TextFormField(
                  controller: dateController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount != null && amount > 0) {
                await _saveCategoryExpense(
                  category: isOther && _customCategories[category] != null
                      ? _customCategories[category]!
                      : category,
                  amount: amount,
                  date: selectedDate,
                );
                amountController.clear();
                dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
                selectedDate = DateTime.now();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez saisir un montant valide', 
                        style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Enregistrer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sauvegarder la dépense planifiée
  Future<void> _saveCategoryExpense({
    required String category,
    required double amount,
    required DateTime date,
  }) async {
    try {
      final provider = context.read<MarketingExpenseProvider>();
      
      await provider.addExpense(
        branchId: widget.branchId,
        category: category,
        activity: category, // Utiliser la catégorie comme activité pour la planification
        amount: amount,
        expenseDate: date,
        description: 'Dépense planifiée pour ${PeriodHelper.getPeriodTypeLabel(_selectedPeriodType)}',
      );

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dépense planifiée enregistrée', 
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Modifier une dépense planifiée
  Future<void> _editCategoryExpense(String category) async {
    final provider = context.read<MarketingExpenseProvider>();
    final expenses = provider.expenses.where((e) => e.category == category).toList();
    
    if (expenses.isEmpty) return;

    // Ouvrir la page de modification avec la première dépense de cette catégorie
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          branchId: widget.branchId,
          expense: expenses.first,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Marketing & Publicité':
        return Colors.blue;
      case 'Communication':
        return Colors.green;
      case 'Événements & Relations publiques':
        return Colors.orange;
      case 'Formation & Développement':
        return Colors.purple;
      case 'Matériel & Équipement':
        return Colors.red;
      case 'Transport & Logistique':
        return Colors.teal;
      case 'Services professionnels':
        return Colors.pink;
      case 'Location & Infrastructure':
        return Colors.amber;
      case 'Autres dépenses':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Marketing & Publicité':
        return Icons.campaign;
      case 'Communication':
        return Icons.message;
      case 'Événements & Relations publiques':
        return Icons.event;
      case 'Formation & Développement':
        return Icons.school;
      case 'Matériel & Équipement':
        return Icons.inventory_2;
      case 'Transport & Logistique':
        return Icons.local_shipping;
      case 'Services professionnels':
        return Icons.business_center;
      case 'Location & Infrastructure':
        return Icons.location_city;
      case 'Autres dépenses':
        return Icons.add_circle_outline;
      default:
        return Icons.receipt;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
