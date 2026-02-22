import 'package:flutter/material.dart';
import '../data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.product.price * item.quantity;
    });
    return total;
  }

  void addItem(ProductModel product) {
    final productId = product.id ?? '';
    
    // Debug pour identifier le problème
    if (productId.isEmpty) {
      debugPrint('❌ ERREUR PANIER: Produit "${product.name}" n\'a pas d\'ID !');
      debugPrint('   ProductModel.id: ${product.id}');
      debugPrint('   ProductModel.vendorId: ${product.vendorId}');
      return;
    }
    
    debugPrint('✅ Ajout au panier: ${product.name} (ID: $productId)');
    
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
            (existing) => CartItem(
            product: existing.product, quantity: existing.quantity + 1),
      );
      debugPrint('   → Quantité mise à jour: ${_items[productId]!.quantity}');
    } else {
      _items.putIfAbsent(
        productId,
            () => CartItem(product: product),
      );
      debugPrint('   → Nouveau produit ajouté');
    }
    
    debugPrint('📦 Total items dans le panier: ${_items.length}');
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
              (existing) => CartItem(
              product: existing.product, quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}