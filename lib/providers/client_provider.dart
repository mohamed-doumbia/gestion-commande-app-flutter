import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/client_stats_model.dart';

class ClientProvider with ChangeNotifier {
  List<ClientStatsModel> _clients = [];
  bool _isLoading = false;

  List<ClientStatsModel> get clients => _clients;
  bool get isLoading => _isLoading;

  // ------------------------------------------------
  // STATISTIQUES (Getters calculés)
  // ------------------------------------------------

  // 1. Total Clients
  int get totalClients => _clients.length;

  // 2. Clients VIP (Règle : ≥ 5 commandes OU ≥ 50.000 FCFA dépensés)
  int get vipClients => _clients.where((c) {
    return c.totalOrders >= 5 || c.totalSpent >= 50000;
  }).length;

  // 3. Nouveaux clients (1ère commande dans les 30 derniers jours)
  int get newClients {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return _clients.where((c) {
      if (c.lastOrderDate == null) return false; // Pas de date, pas nouveau
      try {
        final lastOrder = DateTime.parse(c.lastOrderDate!);
        return lastOrder.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).length;
  }

  // 4. Clients inactifs (Pas de commande depuis 90 jours)
  int get inactiveClients {
    final now = DateTime.now();
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    return _clients.where((c) {
      if (c.lastOrderDate == null) return true; // Jamais commandé = inactif
      try {
        final lastOrder = DateTime.parse(c.lastOrderDate!);
        return lastOrder.isBefore(ninetyDaysAgo);
      } catch (e) {
        return false;
      }
    }).length;
  }

  // 5. Top 5 Clients (Ceux qui ont le plus dépensé)
  List<ClientStatsModel> get topClients {
    // On crée une copie pour ne pas modifier l'ordre de la liste principale
    final sortedList = List<ClientStatsModel>.from(_clients);

    // On trie du plus grand au plus petit
    sortedList.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    // On prend les 5 premiers
    return sortedList.take(5).toList();
  }

  // ------------------------------------------------
  // CHARGEMENT DES DONNÉES
  // ------------------------------------------------

  Future<void> loadClients(String vendorId) async {
    _isLoading = true;
    notifyListeners(); // Déclenche le spinner

    try {
      // Appel à la base de données
      _clients = await DatabaseHelper.instance.getVendorClients(vendorId);
      print("CLIENTS CHARGÉS: ${_clients.length}"); // Debug
    } catch (e) {
      print("ERREUR LORS DU CHARGEMENT DES CLIENTS : $e");
      _clients = []; // En cas d'erreur, on vide la liste pour éviter le crash
    } finally {
      // Quoi qu'il arrive (succès ou erreur), on arrête le chargement
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode utilitaire pour trouver un client spécifique
  ClientStatsModel? getClientById(String clientId) {
    try {
      return _clients.firstWhere((c) => c.id == clientId);
    } catch (e) {
      return null;
    }
  }
}