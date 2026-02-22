import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/branch_accounting_provider.dart';
import '../../../providers/branch_employee_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/department_drawer.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/role_model.dart';
import '../../../data/local/database_helper.dart';
import 'accounting/branch_accounting_screen.dart';
import 'accounting/department_code_verification_screen.dart';
import 'employees/branch_employees_screen.dart';
import 'marketing/branch_marketing_screen.dart';

/// ============================================
/// DASHBOARD SUCCURSALE - PAGE PRINCIPALE
/// ============================================
/// Description : Page principale de gestion d'une succursale
/// Contient : Vue d'ensemble, KPIs, actions rapides, navigation vers sections
/// Phase : Phase 2
class BranchDashboardScreen extends StatefulWidget {
  final String branchId;

  const BranchDashboardScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<BranchDashboardScreen> createState() => _BranchDashboardScreenState();
}

class _BranchDashboardScreenState extends State<BranchDashboardScreen>
    with WidgetsBindingObserver {
  BranchModel? _branch;
  
  // Filtres de période
  String _selectedPeriod = 'mois'; // 'semaine', 'mois', 'année'
  int? _selectedYear;
  String? _selectedYearMonth; // Format "YYYY-MM"
  List<int> _availableYears = [];
  List<Map<String, dynamic>> _availableMonths = [];
  
  // Données financières
  double _totalEntries = 0.0;
  double _totalExpenses = 0.0;
  double _netProfit = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBranchDetails();
    _loadFinancialData();
    _loadAvailablePeriods();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger les périodes disponibles quand l'application revient au premier plan
    // pour s'assurer que les nouvelles transactions sont prises en compte
    if (state == AppLifecycleState.resumed) {
      _loadAvailablePeriods();
    }
  }

  /// ============================================
  /// CHARGER LES DÉTAILS DE LA SUCCURSALE
  /// ============================================
  void _loadBranchDetails() {
    final branchProvider = context.read<BranchProvider>();
    setState(() {
      _branch = branchProvider.getBranchById(widget.branchId);
    });
  }

  /// ============================================
  /// CHARGER LES DONNÉES FINANCIÈRES
  /// ============================================
  Future<void> _loadFinancialData() async {
    final accountingProvider = context.read<BranchAccountingProvider>();
    
    // Calculer les dates selon la période sélectionnée
    DateTime? startDate;
    DateTime? endDate = DateTime.now();
    
    if (_selectedPeriod == 'semaine') {
      // Semaine en cours (7 derniers jours)
      startDate = DateTime.now().subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'mois') {
      if (_selectedYearMonth != null) {
        // Mois spécifique sélectionné
        final parts = _selectedYearMonth!.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        startDate = DateTime(year, month, 1);
        endDate = DateTime(year, month + 1, 0); // Dernier jour du mois
      } else {
        // Mois en cours par défaut
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      }
    } else if (_selectedPeriod == 'année') {
      if (_selectedYear != null) {
        // Année spécifique sélectionnée
        startDate = DateTime(_selectedYear!, 1, 1);
        endDate = DateTime(_selectedYear!, 12, 31);
      } else {
        // Année en cours par défaut
        final now = DateTime.now();
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
      }
    }
    
    final summary = await accountingProvider.calculateFinancialSummary(
      branchId: widget.branchId,
      startDate: startDate,
      endDate: endDate,
    );
    
    if (mounted) {
      setState(() {
        _totalEntries = summary['totalEntries'] ?? 0.0;
        _totalExpenses = summary['totalExpenses'] ?? 0.0;
        _netProfit = summary['netProfit'] ?? 0.0;
      });
    }
  }

  /// ============================================
  /// CHARGER LES PÉRIODES DISPONIBLES
  /// ============================================
  Future<void> _loadAvailablePeriods() async {
    final dbHelper = DatabaseHelper.instance;
    final years = await dbHelper.getAvailableYears(widget.branchId);
    
    if (mounted) {
      // Sauvegarder l'année et le mois actuellement sélectionnés avant de les modifier
      final previousYear = _selectedYear;
      final previousYearMonth = _selectedYearMonth;
      
      setState(() {
        _availableYears = years;
        
        // Si aucune année n'est sélectionnée, prendre la première disponible
        if (years.isNotEmpty && _selectedYear == null) {
          _selectedYear = years.first;
        }
        // Si l'année sélectionnée n'existe plus dans la liste, prendre la première disponible
        else if (years.isNotEmpty && !years.contains(_selectedYear)) {
          _selectedYear = years.first;
          // Réinitialiser le mois car l'année a changé
          _selectedYearMonth = null;
        }
      });
      
      // Charger les mois pour l'année sélectionnée
      if (_selectedYear != null) {
        await _loadAvailableMonths(_selectedYear!);
        
        // Si on avait un mois sélectionné pour l'année précédente et que l'année n'a pas changé,
        // essayer de le restaurer s'il existe toujours dans la nouvelle liste
        if (previousYear == _selectedYear && previousYearMonth != null && _availableMonths.isNotEmpty && mounted) {
          final exists = _availableMonths.any((m) => m['year_month'] == previousYearMonth);
          if (exists) {
            setState(() {
              _selectedYearMonth = previousYearMonth;
            });
            // Recharger les données financières avec le mois restauré
            await _loadFinancialData();
          }
        }
      }
    }
  }

  /// ============================================
  /// CHARGER LES MOIS DISPONIBLES POUR UNE ANNÉE
  /// ============================================
  Future<void> _loadAvailableMonths(int year) async {
    final dbHelper = DatabaseHelper.instance;
    final months = await dbHelper.getAvailableMonths(widget.branchId, year);
    
    if (mounted) {
      setState(() {
        // Toujours mettre à jour la liste des mois disponibles
        _availableMonths = months;
        
        // Gérer la sélection du mois :
        // - Si un mois est déjà sélectionné ET qu'il appartient à l'année courante ET qu'il existe dans la liste, le garder
        // - Sinon, sélectionner le premier mois disponible de l'année
        if (_selectedYearMonth != null) {
          final parts = _selectedYearMonth!.split('-');
          final selectedYear = int.parse(parts[0]);
          
          // Si le mois sélectionné appartient à une autre année, le réinitialiser
          if (selectedYear != year) {
            _selectedYearMonth = months.isNotEmpty ? months.first['year_month'] as String : null;
          } else {
            // Vérifier si le mois sélectionné existe toujours dans la liste
            final exists = months.any((m) => m['year_month'] == _selectedYearMonth);
            if (!exists && months.isNotEmpty) {
              // Si le mois n'existe plus, sélectionner le premier mois disponible
              _selectedYearMonth = months.first['year_month'] as String;
            }
          }
        } else if (months.isNotEmpty) {
          // Aucun mois sélectionné, prendre le premier disponible
          _selectedYearMonth = months.first['year_month'] as String;
        } else {
          // Aucun mois disponible pour cette année
          _selectedYearMonth = null;
        }
      });
      
      // Recharger les données financières avec le nouveau mois
      await _loadFinancialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_branch == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Succursale', style: GoogleFonts.poppins()),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.currentEmployee;
    final branch = authProvider.currentEmployeeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DepartmentDrawer(
        departmentName: 'Dashboard',
        employeeName: employee?.fullName,
        branchName: branch?.name ?? _branch?.name,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadBranchDetails();
          await _loadFinancialData();
          await _loadAvailablePeriods();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ============================================
            // SECTION 1 : EN-TÊTE SUCCURSALE
            // ============================================
            _buildHeader(),

            // ============================================
            // SECTION 2 : KPIs EN TEMPS RÉEL
            // ============================================
            _buildKPIs(),

            // ============================================
            // SECTION 3 : ACTIONS RAPIDES
            // ============================================
            _buildQuickActions(),

            // ============================================
            // SECTION 4 : NAVIGATION VERS SECTIONS
            // ============================================
            _buildSectionsGrid(),

            // ============================================
            // SECTION 5 : GRAPHIQUES RAPIDES
            // ============================================
            _buildQuickCharts(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE L'EN-TÊTE DE LA SUCCURSALE
  /// ============================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton retour et titre
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _branch!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Bouton paramètres
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // TODO Phase 8 : Naviguer vers Paramètres
                  _showComingSoon('Paramètres');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Code succursale
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _branch!.code,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Statut
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _branch!.isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _branch!.isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 16),
              // Manager (si assigné)
              if (_branch!.managerId != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 4),
                    Text(
                      'Manager assigné',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Localisation
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _branch!.fullAddress,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LES KPIs EN TEMPS RÉEL
  /// ============================================
  Widget _buildKPIs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec filtres de période
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vue d\'ensemble',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              // Filtres de période
              Flexible(
                child: _buildPeriodFilter(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grille de KPIs avec données réelles
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Entrées',
                  '${_totalEntries.toStringAsFixed(0)} FCFA',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  'Dépenses',
                  '${_totalExpenses.toStringAsFixed(0)} FCFA',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Bénéfice',
                  '${_netProfit.toStringAsFixed(0)} FCFA',
                  Icons.account_balance_wallet,
                  _netProfit >= 0 ? Colors.blue : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('Employés', '0', Icons.people, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKPICard('Produits', '0', Icons.inventory_2, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('Alertes', '0', Icons.warning, Colors.amber)),
            ],
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LE FILTRE DE PÉRIODE
  /// ============================================
  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélecteur de type de période
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(value: 'semaine', child: Text('Semaine')),
                DropdownMenuItem(value: 'mois', child: Text('Mois')),
                DropdownMenuItem(value: 'année', child: Text('Année')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    if (value == 'semaine') {
                      _selectedYear = null;
                      _selectedYearMonth = null;
                    }
                  });
                  await _loadFinancialData();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sélecteur d'année (si période = année ou mois)
          if (_selectedPeriod == 'année' && _availableYears.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox(),
                isDense: true,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                dropdownColor: Colors.white,
                items: _availableYears.map((year) => DropdownMenuItem(
                  value: year,
                  child: Text(year.toString(), style: GoogleFonts.poppins(color: Colors.black)),
                )).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                    // Recharger les mois disponibles pour la nouvelle année
                    await _loadAvailableMonths(value);
                    await _loadFinancialData();
                  }
                },
              ),
            ),
          // Sélecteur de mois (si période = mois)
          if (_selectedPeriod == 'mois' && _availableMonths.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedYearMonth,
                underline: const SizedBox(),
                isDense: true,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                dropdownColor: Colors.white,
                items: _availableMonths.map((monthData) {
                  final month = monthData['month'] as int;
                  final yearMonth = monthData['year_month'] as String;
                  final parts = yearMonth.split('-');
                  final year = int.parse(parts[0]);
                  // Format manuel des mois pour éviter l'initialisation de locale
                  final monthNames = [
                    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
                  ];
                  final monthName = '${monthNames[month - 1]} $year';
                  return DropdownMenuItem(
                    value: yearMonth,
                    child: Text(monthName, style: GoogleFonts.poppins(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _selectedYearMonth = value);
                    await _loadFinancialData();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE UNE CARTE KPI
  /// ============================================
  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              // Indicateur de tendance (placeholder)
              Icon(Icons.arrow_upward, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
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

  /// ============================================
  /// CONSTRUIRE LES ACTIONS RAPIDES
  /// ============================================
  Widget _buildQuickActions() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Vérifier si c'est une session employé
        final isEmployee = authProvider.isEmployeeSession;
        final employee = authProvider.currentEmployee;
        
        // Si c'est un employé, vérifier les permissions
        bool canAddExpense = true; // Par défaut visible pour admin/vendeur
        bool canAddEmployee = true; // Par défaut visible pour admin
        
        if (isEmployee && employee != null) {
          // Pour les employés, masquer certaines actions selon le département
          // Seuls les admins peuvent ajouter des employés
          canAddEmployee = false; // Les employés ne peuvent pas ajouter d'employés
          
          // Les employés de comptabilité peuvent ajouter des dépenses
          // Les autres départements ne peuvent pas
          if (employee.roleId != null) {
            final employeeProvider = context.read<BranchEmployeeProvider>();
            employeeProvider.getRole(employee.roleId!).then((role) {
              if (role != null && role.department != 'COMPTABILITE' && role.department != 'ADMIN') {
                canAddExpense = false;
              }
            });
          }
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions rapides',
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
                    child: _buildQuickActionButton(
                      'Nouvelle Vente',
                      Icons.add_shopping_cart,
                      Colors.green,
                      () => _showComingSoon('Nouvelle Vente'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (canAddExpense)
                    Expanded(
                      child: _buildQuickActionButton(
                        'Nouvelle Dépense',
                        Icons.receipt_long,
                        Colors.red,
                        () => _showComingSoon('Nouvelle Dépense'),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
              if (canAddEmployee) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Ajouter Employé',
                        Icons.person_add,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BranchEmployeesScreen(branchId: widget.branchId),
                          ),
                        ).then((_) => _loadBranchDetails()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Entrée Stock',
                        Icons.inventory,
                        Colors.orange,
                        () => _showComingSoon('Entrée Stock'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Entrée Stock',
                        Icons.inventory,
                        Colors.orange,
                        () => _showComingSoon('Entrée Stock'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ============================================
  /// CONSTRUIRE UN BOUTON D'ACTION RAPIDE
  /// ============================================
  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LA GRILLE DE NAVIGATION SECTIONS
  /// ============================================
  Widget _buildSectionsGrid() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isEmployee = authProvider.isEmployeeSession;
        final employee = authProvider.currentEmployee;
        
        // Déterminer quelles sections afficher selon le rôle
        bool showAccounting = true;
        bool showEmployees = true;
        bool showSettings = true;
        
        if (isEmployee && employee != null && employee.roleId != null) {
          // Charger le rôle pour déterminer les permissions
          final employeeProvider = context.read<BranchEmployeeProvider>();
          
          return FutureBuilder<RoleModel?>(
            future: employeeProvider.getRole(employee.roleId!),
            builder: (context, snapshot) {
              final role = snapshot.data;
              String? department = role?.department;
              
              // Masquer les sections selon le département
              if (department != null) {
                showAccounting = department == 'COMPTABILITE' || department == 'ADMIN' || department == 'MANAGER';
                showEmployees = department == 'RH' || department == 'ADMIN' || department == 'MANAGER';
                showSettings = department == 'ADMIN';
              }
              
              // Admin voit toujours tous les départements
              final isAdmin = department == 'ADMIN' || (role?.hasPermission('ADMIN') ?? false);
              
              return _buildSectionsGridContent(
                showAccounting: showAccounting || isAdmin,
                showEmployees: showEmployees || isAdmin,
                showSettings: showSettings,
                showMarketing: isAdmin || department == 'MARKETING' || department == 'MANAGER',
              );
            },
          );
        }
        
        // Si pas d'employé ou pas de rôle, afficher tout (admin/vendeur)
        return _buildSectionsGridContent(
          showAccounting: true,
          showEmployees: true,
          showSettings: true,
          showMarketing: true,
        );
      },
    );
  }

  /// ============================================
  /// CONTENU DE LA GRILLE DE SECTIONS
  /// ============================================
  Widget _buildSectionsGridContent({
    required bool showAccounting,
    required bool showEmployees,
    required bool showSettings,
    bool showMarketing = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sections',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // Grille 2x3
          Row(
            children: [
              if (showAccounting)
                Expanded(child: _buildSectionCard('Comptabilité', Icons.account_balance_wallet, Colors.green, () {
                  _navigateToAccounting();
                }))
              else
                const SizedBox.shrink(),
              if (showAccounting && showEmployees) const SizedBox(width: 12),
              if (showEmployees)
                Expanded(child: _buildSectionCard('Employés', Icons.people, Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BranchEmployeesScreen(branchId: _branch!.id),
                    ),
                  );
                }))
              else
                const SizedBox.shrink(),
              if (!showAccounting && !showEmployees) const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (showMarketing)
                Expanded(child: _buildSectionCard('Marketing', Icons.campaign, Colors.pink, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BranchMarketingScreen(branchId: _branch!.id),
                    ),
                  );
                }))
              else
                const SizedBox.shrink(),
              if (showMarketing) const SizedBox(width: 12),
              Expanded(child: _buildSectionCard('RH', Icons.work, Colors.orange, () => _showComingSoon('RH'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSectionCard('Stock', Icons.inventory_2, Colors.purple, () => _showComingSoon('Stock'))),
              const SizedBox(width: 12),
              Expanded(child: _buildSectionCard('Ventes', Icons.shopping_bag, Colors.teal, () => _showComingSoon('Ventes'))),
            ],
          ),
          const SizedBox(height: 12),
          if (showSettings)
            Row(
              children: [
                Expanded(child: _buildSectionCard('Paramètres', Icons.settings, Colors.grey, () => _showComingSoon('Paramètres'))),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE UNE CARTE DE SECTION
  /// ============================================
  Widget _buildSectionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================
  /// CONSTRUIRE LES GRAPHIQUES RAPIDES
  /// ============================================
  Widget _buildQuickCharts() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Graphiques rapides',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder pour graphiques
          Container(
            padding: const EdgeInsets.all(24),
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
                Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'Graphiques disponibles prochainement',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CA des 7 derniers jours\nDépenses des 7 derniers jours\nTop 5 produits vendus',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// AFFICHER UN MESSAGE "Bientôt disponible"
  /// ============================================
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature - Bientôt disponible (Phase suivante)',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ============================================
  /// NAVIGUER VERS LA COMPTABILITÉ (AVEC VÉRIFICATION)
  /// ============================================
  Future<void> _navigateToAccounting() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur non identifié', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier si l'utilisateur est admin
    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (isUserAdmin) {
      // Admin peut accéder directement
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BranchAccountingScreen(branchId: _branch!.id),
        ),
      );
    } else {
      // Non-admin doit entrer le code département
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepartmentCodeVerificationScreen(
            branchId: _branch!.id,
            department: 'COMPTABILITE',
          ),
        ),
      );
    }
  }
}

