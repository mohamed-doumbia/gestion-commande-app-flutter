import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/client_stats_model.dart';

class ClientProvider with ChangeNotifier {
  List<ClientStatsModel> _clients = [];
  bool _isLoading = false;

  List<ClientStatsModel> get clients => _clients;
  bool get isLoading => _isLoading;

  // Statistiques globales
  int get totalClients => _clients.length;

  // Clients VIP (≥5 commandes OU ≥50000 FCFA)
  int get vipClients => _clients.where((c) => c.isVip).length;

  // Nouveaux clients (dernière commande dans les 30 derniers jours)
  int get newClients {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return _clients.where((c) {
      if (c.lastOrderDate == null) return false;
      try {
        final lastOrder = DateTime.parse(c.lastOrderDate!);
        return lastOrder.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).length;
  }

  // Clients inactifs (pas de commande depuis 90 jours)
  int get inactiveClients {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    return _clients.where((c) {
      if (c.lastOrderDate == null) return false;
      try {
        final lastOrder = DateTime.parse(c.lastOrderDate!);
        return lastOrder.isBefore(ninetyDaysAgo);
      } catch (e) {
        return false;
      }
    }).length;
  }

  // Top clients (par dépenses)
  List<ClientStatsModel> get topClients {
    final sorted = List<ClientStatsModel>.from(_clients);
    sorted.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return sorted.take(5).toList();
  }

  Future<void> loadClients(int vendorId) async {
    _isLoading = true;
    notifyListeners();

    _clients = await DatabaseHelper.instance.getVendorClients(vendorId);

    _isLoading = false;
    notifyListeners();
  }

  // Méthode pour obtenir les stats d'un client spécifique
  ClientStatsModel? getClientById(int clientId) {
    try {
      return _clients.firstWhere((c) => c.id == clientId);
    } catch (e) {
      return null;
    }
  }
}