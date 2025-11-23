import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;

  // Charger les produits d'un vendeur spécifique
  Future<void> loadProducts(int vendorId) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
        'products',
        where: 'vendorId = ?',
        whereArgs: [vendorId],
        orderBy: 'id DESC' // Les plus récents en haut
    );

    _products = result.map((e) => ProductModel.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  // Ajouter un produit
  Future<void> addProduct(ProductModel product) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('products', product.toMap());

    // Recharger la liste pour voir l'ajout tout de suite
    await loadProducts(product.vendorId);
  }

  // Petite astuce : Une méthode pour recharger le stock après une vente
  // Utile quand on revient sur l'écran liste après une commande
  Future<void> refreshStock(int vendorId) async {
    await loadProducts(vendorId);
  }
}