import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/order_model.dart';

class ClientOrderProvider with ChangeNotifier {
  List<OrderModel> _myOrders = [];
  bool _isLoading = false;

  // Getters
  List<OrderModel> get myOrders => _myOrders;
  bool get isLoading => _isLoading;

  // STATS CALCULÉES
  int get totalOrdersCount => _myOrders.where((o) => o.status == 'Livrée').length; // Seules les livrées comptent comme "Achat finalisé" ? Ou toutes ? Disons Livrée pour l'achat confirmé.

  // Total des commandes en cours (pour le badge)
  int get activeOrdersCount => _myOrders.where((o) => o.status == 'En attente' || o.status == 'Validée').length;

  double get totalSpent {
    // On ne calcule que l'argent des commandes LIVRÉES (validées et payées)
    return _myOrders
        .where((o) => o.status == 'Livrée')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int get loyaltyPoints {
    // Règle : 1 point tous les 4 achats validés (Livrés)
    int deliveredOrders = totalOrdersCount;
    return (deliveredOrders / 4).floor(); // Division entière
  }

  // CHARGEMENT DES DONNÉES
  Future<void> loadClientOrders(int clientId) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;

    // Récupérer les commandes où clientId correspond
    // On doit aussi faire une jointure pour avoir le nom du vendeur si besoin,
    // mais pour l'instant on fait simple sur la table orders
    final result = await db.query(
        'orders',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'date DESC' // Les plus récentes en haut
    );

    // Pour chaque commande, il faut charger ses items pour avoir le détail
    List<OrderModel> loadedOrders = [];
    for (var row in result) {
      int orderId = row['id'] as int;

      // Récup items
      final itemsResult = await db.query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
      final items = itemsResult.map((item) => OrderItem.fromMap(item)).toList();

      // On triche un peu sur le "clientName" car ici on est le client,
      // on pourrait récupérer le nom du vendeur à la place si on avait stocké vendorId dans orders.
      // Pour l'instant on garde la structure OrderModel existante.
      loadedOrders.add(OrderModel.fromMap(row, items));
    }

    _myOrders = loadedOrders;
    _isLoading = false;
    notifyListeners();
  }
}