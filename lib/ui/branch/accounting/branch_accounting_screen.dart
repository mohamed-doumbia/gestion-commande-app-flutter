import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/branch_accounting_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/branch_employee_provider.dart';
import '../../../widgets/department_drawer.dart';
import '../../../data/models/branch_transaction_model.dart';
import '../../../data/models/branch_recurring_cost_model.dart';
import '../../../data/models/permission_request_model.dart';

/// ============================================
/// PAGE COMPTABILITÉ SUCCURSALE
/// ============================================
/// Description : Gestion complète de la comptabilité d'une succursale
/// Phase : Phase 3 - Comptabilité
/// Contenu : 5 onglets (Enregistrer, Historique, Bilan, Coûts récurrents, Export/Import)
class BranchAccountingScreen extends StatefulWidget {
  final String branchId;

  const BranchAccountingScreen({
    Key? key,
    required this.branchId,
  }) : super(key: key);

  @override
  State<BranchAccountingScreen> createState() => _BranchAccountingScreenState();
}

class _BranchAccountingScreenState extends State<BranchAccountingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;
  Timer? _notificationTimer;
  int _pendingRequestsCount = 0;
  Set<String> _notifiedRequestIds = {};

  @override
  void initState() {
    super.initState();
    // Toujours initialiser avec 6 onglets (le 6ème sera masqué si non-admin)
    _tabController = TabController(length: 6, vsync: this);
    _checkAdminStatus();
    _loadData();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================
  /// VÉRIFIER LE STATUT ADMIN
  /// ============================================
  Future<void> _checkAdminStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id.toString() ?? '';
    if (userId.isEmpty) {
      setState(() {
        _isAdmin = false;
        _isLoadingAdmin = false;
      });
      return;
    }

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);
    
    // Ne PAS recréer le TabController, juste mettre à jour l'état
    setState(() {
      _isAdmin = isUserAdmin;
      _isLoadingAdmin = false;
    });
    
    // Démarrer le timer de notifications si admin
    if (isUserAdmin) {
      _startNotificationTimer();
    }
  }

  /// ============================================
  /// DÉMARRER LE TIMER DE NOTIFICATIONS
  /// ============================================
  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForNewPermissionRequests();
    });
    // Vérifier immédiatement aussi
    _checkForNewPermissionRequests();
  }

  /// ============================================
  /// VÉRIFIER LES NOUVELLES DEMANDES DE PERMISSION
  /// ============================================
  Future<void> _checkForNewPermissionRequests() async {
    if (!_isAdmin || !mounted) return;

    try {
      final employeeProvider = context.read<BranchEmployeeProvider>();
      await employeeProvider.loadPendingPermissionRequests(widget.branchId);
      
      final requests = employeeProvider.permissionRequests;
      final newRequests = requests.where((r) => !_notifiedRequestIds.contains(r.id)).toList();
      
      if (newRequests.isNotEmpty && mounted) {
        // Ajouter les IDs aux notifications envoyées
        _notifiedRequestIds.addAll(newRequests.map((r) => r.id));
        
        // Afficher une notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${newRequests.length} nouvelle(s) demande(s) de permission',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Passer à l'onglet Demandes
                    _tabController.animateTo(5);
                  },
                  child: Text('Voir', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Fermer',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        
        setState(() {
          _pendingRequestsCount = requests.length;
        });
      } else if (mounted) {
        setState(() {
          _pendingRequestsCount = requests.length;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification demandes: $e');
    }
  }

  /// ============================================
  /// CHARGER LES DONNÉES
  /// ============================================
  Future<void> _loadData() async {
    final accountingProvider = context.read<BranchAccountingProvider>();
    await Future.wait([
      accountingProvider.loadTransactions(widget.branchId),
      accountingProvider.loadRecurringCosts(widget.branchId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.currentEmployee;
    final branch = authProvider.currentEmployeeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DepartmentDrawer(
        departmentName: 'Comptabilité',
        employeeName: employee?.fullName,
        branchName: branch?.name,
      ),
      appBar: AppBar(
        title: Text(
          'Comptabilité',
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(text: 'Enregistrer'),
            const Tab(text: 'Historique'),
            const Tab(text: 'Bilan'),
            const Tab(text: 'Coûts récurrents'),
            const Tab(text: 'Export/Import'),
            if (_isAdmin) Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Demandes'),
                  if (_pendingRequestsCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$_pendingRequestsCount',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoadingAdmin
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordTransactionTab(),
                _buildHistoryTab(),
                _buildFinancialSummaryTab(),
                _buildRecurringCostsTab(),
                _buildExportImportTab(),
                // Toujours inclure le 6ème onglet, même si masqué dans les tabs
                _isAdmin ? _buildPermissionRequestsTab() : _buildEmptyTab(),
              ],
            ),
    );
  }

  /// ============================================
  /// ONGLET 1 : ENREGISTRER TRANSACTION
  /// ============================================
  Widget _buildRecordTransactionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _TransactionForm(
        branchId: widget.branchId,
        onTransactionSaved: () {
          // Recharger les transactions après ajout
          _loadData();
        },
      ),
    );
  }

  /// ============================================
  /// ONGLET 2 : HISTORIQUE TRANSACTIONS
  /// ============================================
  Widget _buildHistoryTab() {
    return Consumer<BranchAccountingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucune transaction',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadTransactions(widget.branchId),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = provider.transactions[index];
              return _TransactionCard(
                transaction: transaction,
                onEdit: () => _editTransaction(transaction),
                onDelete: () => _deleteTransaction(transaction.id),
              );
            },
          ),
        );
      },
    );
  }

  /// ============================================
  /// ONGLET 3 : BILAN FINANCIER
  /// ============================================
  Widget _buildFinancialSummaryTab() {
    return Consumer<BranchAccountingProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, double>>(
          future: provider.calculateFinancialSummary(branchId: widget.branchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final summary = snapshot.data ?? {
              'totalEntries': 0.0,
              'totalExits': 0.0,
              'totalExpenses': 0.0,
              'totalOutflows': 0.0,
              'netProfit': 0.0,
              'profitMargin': 0.0,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vue mensuelle
                  _buildSummaryCard(
                    'Vue Mensuelle',
                    [
                      _SummaryItem('Total Entrées', summary['totalEntries']!, Colors.green),
                      _SummaryItem('Total Sorties', summary['totalExits']!, Colors.orange),
                      _SummaryItem('Total Dépenses', summary['totalExpenses']!, Colors.red),
                      _SummaryItem('Bénéfice Net', summary['netProfit']!,
                          summary['netProfit']! >= 0 ? Colors.green : Colors.red),
                      _SummaryItem('Taux de marge', summary['profitMargin']!,
                          summary['profitMargin']! >= 0 ? Colors.green : Colors.red, isPercentage: true),
                    ],
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
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ============================================
  /// ONGLET 4 : COÛTS RÉCURRENTS
  /// ============================================
  Widget _buildRecurringCostsTab() {
    return Consumer<BranchAccountingProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Bouton ajouter
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddRecurringCostDialog(),
                icon: const Icon(Icons.add),
                label: Text('Ajouter coût récurrent', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            // Liste
            Expanded(
              child: provider.recurringCosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun coût récurrent',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadRecurringCosts(widget.branchId),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.recurringCosts.length,
                        itemBuilder: (context, index) {
                          final cost = provider.recurringCosts[index];
                          return _RecurringCostCard(
                            cost: cost,
                            onEdit: () => _editRecurringCost(cost),
                            onDelete: () => _deleteRecurringCost(cost.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// ============================================
  /// ONGLET 5 : EXPORT/IMPORT
  /// ============================================
  Widget _buildExportImportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.import_export, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Export/Import',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fonctionnalité disponible prochainement',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export Excel/PDF - Bientôt disponible', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.file_download),
            label: Text('Exporter bilan', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// ONGLET VIDE (pour non-admin)
  /// ============================================
  Widget _buildEmptyTab() {
    return const Center(child: SizedBox.shrink());
  }

  /// ============================================
  /// ONGLET 6 : DEMANDES DE PERMISSION (ADMIN UNIQUEMENT)
  /// ============================================
  Widget _buildPermissionRequestsTab() {
    return Consumer<BranchEmployeeProvider>(
      builder: (context, employeeProvider, child) {
        if (employeeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = employeeProvider.permissionRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16),
                Text(
                  'Aucune demande en attente',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toutes les demandes ont été traitées',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await employeeProvider.loadPendingPermissionRequests(widget.branchId);
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _PermissionRequestCard(
                request: request,
                onApprove: () => _handlePermissionRequest(request, true),
                onReject: () => _handlePermissionRequest(request, false),
              );
            },
          ),
        );
      },
    );
  }

  /// ============================================
  /// TRAITER UNE DEMANDE DE PERMISSION
  /// ============================================
  Future<void> _handlePermissionRequest(PermissionRequestModel request, bool approve) async {
    final authProvider = context.read<AuthProvider>();
    final reviewedBy = authProvider.currentUser?.id.toString() ?? 'unknown';
    
    final employeeProvider = context.read<BranchEmployeeProvider>();
    
    final success = approve
        ? await employeeProvider.approvePermissionRequest(request.id, reviewedBy)
        : await employeeProvider.rejectPermissionRequest(request.id, reviewedBy);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Demande approuvée' : 'Demande rejetée',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: approve ? Colors.green : Colors.orange,
        ),
      );
      // Recharger les demandes
      await employeeProvider.loadPendingPermissionRequests(widget.branchId);
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du traitement', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================
  // MÉTHODES HELPER POUR LES DIALOGUES ET ACTIONS
  // ============================================

  /// ============================================
  /// ÉDITER UNE TRANSACTION (AVEC VÉRIFICATION PERMISSION)
  /// ============================================
  Future<void> _editTransaction(BranchTransactionModel transaction) async {
    // Vérifier si l'utilisateur est admin
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

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (isUserAdmin) {
      // Admin peut modifier directement
      _showEditTransactionDialog(transaction);
    } else {
      // Non-admin doit demander permission
      _showPermissionRequestDialog(
        transactionId: transaction.id,
        requestType: RequestType.MODIFY_TRANSACTION,
        actionDescription: 'Modifier la transaction ${transaction.id}',
      );
    }
  }

  /// ============================================
  /// SUPPRIMER UNE TRANSACTION (ADMIN UNIQUEMENT)
  /// ============================================
  Future<void> _deleteTransaction(String transactionId) async {
    // Vérifier si l'utilisateur est admin
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

    final employeeProvider = context.read<BranchEmployeeProvider>();
    final isUserAdmin = await employeeProvider.isAdmin(widget.branchId, userId);

    if (!isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seul un administrateur peut supprimer une transaction', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Admin peut supprimer directement
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment supprimer cette transaction ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchAccountingProvider>();
      final success = await provider.deleteTransaction(transactionId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction supprimée', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger les données après suppression
        _loadData();
      }
    }
  }

  /// ============================================
  /// DIALOGUE DE DEMANDE DE PERMISSION
  /// ============================================
  void _showPermissionRequestDialog({
    required String transactionId,
    required RequestType requestType,
    required String actionDescription,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Demande de permission',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous devez demander la permission pour :',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              actionDescription,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Raison de la demande *',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                hintText: 'Expliquez pourquoi cette modification est nécessaire...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              maxLines: 3,
              validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer une raison' : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez entrer une raison', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.currentUser?.id.toString() ?? '';
              
              // Trouver l'employé correspondant
              final employeeProvider = context.read<BranchEmployeeProvider>();
              await employeeProvider.loadEmployees(widget.branchId);
              final employee = employeeProvider.employees.firstWhere(
                (e) => e.vendorId.toString() == userId,
                orElse: () => employeeProvider.employees.first,
              );

              final requestId = await employeeProvider.createPermissionRequest(
                branchId: widget.branchId,
                employeeId: employee.id,
                transactionId: transactionId,
                requestType: requestType,
                reason: reasonController.text.trim(),
              );

              if (requestId != null && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Demande de permission envoyée', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de l\'envoi de la demande', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
            child: Text('Envoyer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ============================================
  /// DIALOGUE D'ÉDITION DE TRANSACTION
  /// ============================================
  void _showEditTransactionDialog(BranchTransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => _EditTransactionDialog(
        branchId: widget.branchId,
        transaction: transaction,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  /// ============================================
  /// AFFICHER LE DIALOGUE D'AJOUT DE COÛT RÉCURRENT
  /// ============================================
  void _showAddRecurringCostDialog() {
    showDialog(
      context: context,
      builder: (context) => _RecurringCostDialog(
        branchId: widget.branchId,
        onSaved: () {
          // Recharger les coûts récurrents après ajout
          context.read<BranchAccountingProvider>().loadRecurringCosts(widget.branchId);
        },
      ),
    );
  }

  /// ============================================
  /// AFFICHER LE DIALOGUE D'ÉDITION DE COÛT RÉCURRENT
  /// ============================================
  void _editRecurringCost(BranchRecurringCostModel cost) {
    showDialog(
      context: context,
      builder: (context) => _RecurringCostDialog(
        branchId: widget.branchId,
        existingCost: cost,
        onSaved: () {
          // Recharger les coûts récurrents après modification
          context.read<BranchAccountingProvider>().loadRecurringCosts(widget.branchId);
        },
      ),
    );
  }

  Future<void> _deleteRecurringCost(String costId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment supprimer ce coût récurrent ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<BranchAccountingProvider>();
      final success = await provider.deleteRecurringCost(costId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coût récurrent supprimé', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildSummaryCard(String title, List<_SummaryItem> items) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    Text(
                      item.isPercentage
                          ? '${item.value.toStringAsFixed(2)}%'
                          : '${item.value.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// Classes helper pour l'affichage
class _SummaryItem {
  final String label;
  final double value;
  final Color color;
  final bool isPercentage;

  _SummaryItem(this.label, this.value, this.color, {this.isPercentage = false});
}

// Formulaire de transaction (séparé pour clarté)
class _TransactionForm extends StatefulWidget {
  final String branchId;
  final VoidCallback? onTransactionSaved;

  const _TransactionForm({
    required this.branchId,
    this.onTransactionSaved,
  });

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _selectedType = TransactionType.EXPENSE;
  TransactionCategory _selectedCategory = TransactionCategory.OTHER;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final createdBy = authProvider.currentUser?.id.toString() ?? 'unknown';

    final provider = context.read<BranchAccountingProvider>();
    final transactionId = await provider.addTransaction(
      branchId: widget.branchId,
      type: _selectedType,
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      createdBy: createdBy,
    );

    setState(() => _isLoading = false);

    if (transactionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction enregistrée avec succès !', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
      _amountController.clear();
      _descriptionController.clear();
      _selectedDate = DateTime.now();
      // Appeler le callback pour notifier le parent
      widget.onTransactionSaved?.call();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type
          _buildDropdown<TransactionType>(
            label: 'Type',
            value: _selectedType,
            items: TransactionType.values,
            onChanged: (value) => setState(() => _selectedType = value!),
            displayName: (type) => type.displayName,
          ),
          const SizedBox(height: 16),
          // Catégorie
          _buildDropdown<TransactionCategory>(
            label: 'Catégorie',
            value: _selectedCategory,
            items: TransactionCategory.values,
            onChanged: (value) => setState(() => _selectedCategory = value!),
            displayName: (category) => category.displayName,
          ),
          const SizedBox(height: 16),
          // Montant
          _buildTextField(
            controller: _amountController,
            label: 'Montant (FCFA)',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer un montant';
              if (double.tryParse(value) == null) return 'Montant invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: GoogleFonts.poppins(),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Description/Notes (optionnel)',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          // Bouton
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B), // Fond noir
              foregroundColor: Colors.white, // Texte blanc
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Enregistrer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // Texte blanc explicite
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) displayName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white, // Fond blanc pour le popup
        style: GoogleFonts.poppins(color: Colors.black), // Texte noir pour la valeur sélectionnée
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            displayName(item),
            style: GoogleFonts.poppins(color: Colors.black), // Texte noir dans le popup
          ),
        )).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, color: Colors.black), // Icône noire
      ),
    );
  }
}

// Carte transaction
class _TransactionCard extends StatelessWidget {
  final BranchTransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(transaction.type.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.type.displayName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${transaction.amount.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category.displayName,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.description!,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Modifier', style: GoogleFonts.poppins()),
                onTap: onEdit,
              ),
              PopupMenuItem(
                child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// DIALOGUE D'AJOUT/ÉDITION DE COÛT RÉCURRENT
// ============================================
class _RecurringCostDialog extends StatefulWidget {
  final String branchId;
  final BranchRecurringCostModel? existingCost;
  final VoidCallback onSaved;

  const _RecurringCostDialog({
    required this.branchId,
    this.existingCost,
    required this.onSaved,
  });

  @override
  State<_RecurringCostDialog> createState() => _RecurringCostDialogState();
}

class _RecurringCostDialogState extends State<_RecurringCostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  TransactionCategory _selectedCategory = TransactionCategory.RENT;
  RecurringFrequency _selectedFrequency = RecurringFrequency.MONTHLY;
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;
  bool _hasEndDate = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si on édite, pré-remplir les champs
    if (widget.existingCost != null) {
      final cost = widget.existingCost!;
      _nameController.text = cost.name;
      _amountController.text = cost.amount.toStringAsFixed(0);
      _selectedCategory = cost.category;
      _selectedFrequency = cost.frequency;
      _selectedStartDate = cost.startDate;
      _selectedEndDate = cost.endDate;
      _hasEndDate = cost.endDate != null;
      _isActive = cost.isActive;
      _notesController.text = cost.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<BranchAccountingProvider>();

    if (widget.existingCost != null) {
      // Mode édition
      final success = await provider.updateRecurringCost(
        costId: widget.existingCost!.id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        startDate: _selectedStartDate,
        endDate: _hasEndDate ? _selectedEndDate : null,
        isActive: _isActive,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coût récurrent modifié avec succès !', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Mode ajout
      final costId = await provider.addRecurringCost(
        branchId: widget.branchId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        startDate: _selectedStartDate,
        endDate: _hasEndDate ? _selectedEndDate : null,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (costId != null && mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coût récurrent ajouté avec succès !', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingCost != null ? 'Modifier le coût récurrent' : 'Ajouter un coût récurrent',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du coût *',
                  hintText: 'Ex: Loyer mensuel',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: Colors.black),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Catégorie
              _buildDropdown<TransactionCategory>(
                label: 'Catégorie *',
                value: _selectedCategory,
                items: [
                  TransactionCategory.RENT,
                  TransactionCategory.CHARGES,
                  TransactionCategory.SALARY,
                  TransactionCategory.TRANSPORT,
                  TransactionCategory.MARKETING,
                  TransactionCategory.OTHER,
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
                displayName: (cat) => cat.displayName,
              ),
              const SizedBox(height: 16),
              
              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: Colors.black),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide (doit être > 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Fréquence
              _buildDropdown<RecurringFrequency>(
                label: 'Fréquence *',
                value: _selectedFrequency,
                items: RecurringFrequency.values,
                onChanged: (value) => setState(() => _selectedFrequency = value!),
                displayName: (freq) => freq.displayName,
              ),
              const SizedBox(height: 16),
              
              // Date de début
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedStartDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Date de début: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate)}',
                          style: GoogleFonts.poppins(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date de fin (optionnelle)
              Row(
                children: [
                  Checkbox(
                    value: _hasEndDate,
                    onChanged: (value) => setState(() {
                      _hasEndDate = value ?? false;
                      if (!_hasEndDate) _selectedEndDate = null;
                    }),
                  ),
                  Expanded(
                    child: Text(
                      'Définir une date de fin',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                  ),
                ],
              ),
              if (_hasEndDate) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedEndDate ?? _selectedStartDate.add(const Duration(days: 365)),
                      firstDate: _selectedStartDate,
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedEndDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedEndDate != null
                                ? 'Date de fin: ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}'
                                : 'Sélectionner une date de fin',
                            style: GoogleFonts.poppins(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Statut actif (seulement en édition)
              if (widget.existingCost != null) ...[
                Row(
                  children: [
                    Checkbox(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value ?? true),
                    ),
                    Expanded(
                      child: Text(
                        'Coût actif',
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Informations complémentaires...',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  widget.existingCost != null ? 'Modifier' : 'Ajouter',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) displayName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(color: Colors.black),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            displayName(item),
            style: GoogleFonts.poppins(color: Colors.black),
          ),
        )).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      ),
    );
  }
}

// Carte coût récurrent
class _RecurringCostCard extends StatelessWidget {
  final BranchRecurringCostModel cost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecurringCostCard({
    required this.cost,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cost.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cost.amount.toStringAsFixed(0)} FCFA - ${cost.frequency.displayName}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  cost.category.displayName,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cost.isActive ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cost.isActive ? 'Actif' : 'Inactif',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cost.isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Modifier', style: GoogleFonts.poppins()),
                onTap: onEdit,
              ),
              PopupMenuItem(
                child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// CARTE DEMANDE DE PERMISSION
// ============================================
class _PermissionRequestCard extends StatelessWidget {
  final PermissionRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PermissionRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayType,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (request.transactionId != null)
                        Text(
                          'Transaction: ${request.transactionId}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request.reason,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Demandé le: ${_formatDate(request.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text('Rejeter', style: GoogleFonts.poppins()),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Approuver', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================
// DIALOGUE D'ÉDITION DE TRANSACTION
// ============================================
class _EditTransactionDialog extends StatefulWidget {
  final String branchId;
  final BranchTransactionModel transaction;
  final VoidCallback onSaved;

  const _EditTransactionDialog({
    required this.branchId,
    required this.transaction,
    required this.onSaved,
  });

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les valeurs existantes
    _amountController.text = widget.transaction.amount.toStringAsFixed(0);
    _descriptionController.text = widget.transaction.description ?? '';
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<BranchAccountingProvider>();
    final success = await provider.updateTransaction(
      transactionId: widget.transaction.id,
      type: _selectedType,
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction modifiée avec succès !', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier Transaction',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type
              _buildDropdown<TransactionType>(
                label: 'Type',
                value: _selectedType,
                items: TransactionType.values,
                onChanged: (value) => setState(() => _selectedType = value!),
                displayName: (type) => type.displayName,
              ),
              const SizedBox(height: 16),
              // Catégorie
              _buildDropdown<TransactionCategory>(
                label: 'Catégorie',
                value: _selectedCategory,
                items: TransactionCategory.values,
                onChanged: (value) => setState(() => _selectedCategory = value!),
                displayName: (category) => category.displayName,
              ),
              const SizedBox(height: 16),
              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  labelStyle: GoogleFonts.poppins(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(color: Colors.black),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Veuillez entrer un montant';
                  if (double.tryParse(value) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.poppins(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Modifier', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) displayName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(color: Colors.black),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            displayName(item),
            style: GoogleFonts.poppins(color: Colors.black),
          ),
        )).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      ),
    );
  }
}

