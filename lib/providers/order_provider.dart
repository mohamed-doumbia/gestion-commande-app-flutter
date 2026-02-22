import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == 'En attente').toList();
  List<OrderModel> get activeOrders => _orders
      .where((o) => o.status == 'Validée' || o.status == 'En cours')
      .toList();
  List<OrderModel> get historyOrders => _orders
      .where((o) =>
  o.status == 'Livrée' ||
      o.status == 'Annulée' ||
      o.status == 'Rejetée')
      .toList();

  double get totalRevenue => _orders
      .where((o) => o.status != 'Annulée')
      .fold(0, (sum, item) => sum + item.totalAmount);
  int get pendingCount => pendingOrders.length;

  Future<void> loadVendorOrders(String vendorId) async {
    _isLoading = true;
    notifyListeners();
    _orders = await DatabaseHelper.instance.getVendorOrders(vendorId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStatus(String orderId, String status, String vendorId) async {
    await DatabaseHelper.instance.updateOrderStatus(orderId, status);
    await loadVendorOrders(vendorId);

    print("Statut changé à $status -> SMS envoyé au client (Simulation)");
  }
}