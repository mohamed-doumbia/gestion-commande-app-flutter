import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/client_stats_model.dart';

class ClientProvider with ChangeNotifier {
  List<ClientStatsModel> _clients = [];
  bool _isLoading = false;

  List<ClientStatsModel> get clients => _clients;
  bool get isLoading => _isLoading;

  // Stats globales pour les KPIs
  int get totalClients => _clients.length;
  int get vipClients => _clients.where((c) => c.totalSpent > 50000).length; // Exemple VIP > 50k

  Future<void> loadClients(int vendorId) async {
    _isLoading = true;
    notifyListeners();
    _clients = await DatabaseHelper.instance.getVendorClients(vendorId);
    _isLoading = false;
    notifyListeners();
  }
}