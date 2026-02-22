import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/database_helper.dart';
import '../data/models/product_model.dart';
import '../data/models/product_with_vendor_model.dart';

class ProductProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();
  List<ProductModel> _products = [];
  List<ProductWithVendorModel> _productsWithVendor = [];
  List<String> _categories = [];
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  List<ProductWithVendorModel> get productsWithVendor => _productsWithVendor;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  // ✅ Charger produits vendeur (Dashboard vendeur)
  Future<void> loadVendorProducts(String vendorId) async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'products',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'id DESC',
    );

    _products = result.map((e) => ProductModel.fromMap(e)).toList();

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Charger TOUS les produits avec infos vendeur (Client)
  Future<void> loadAllProductsWithVendor() async {
    _isLoading = true;
    notifyListeners();

    print('📦 Chargement de tous les produits...');

    _productsWithVendor = await DatabaseHelper.instance.getAllProductsWithVendor();

    print('✅ ${_productsWithVendor.length} produits chargés');

    if (_productsWithVendor.isNotEmpty) {
      print('📍 Premier produit: ${_productsWithVendor.first.product.name}');
      print('👤 Vendeur: ${_productsWithVendor.first.vendorInfo.name}');
    } else {
      print('⚠️ AUCUN PRODUIT TROUVÉ');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Charger les catégories
  Future<void> loadCategories() async {
    _categories = await DatabaseHelper.instance.getAllCategories();
    // Utiliser scheduleMicrotask pour éviter notifyListeners pendant build
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // ✅ Mettre à jour le stock d'un produit
  Future<void> updateProductStock(String productId, int newStock) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'products',
      {'stockQuantity': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
    // Utiliser scheduleMicrotask pour éviter notifyListeners pendant build
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // ✅ Ajouter une catégorie
  Future<void> addCategory(String categoryName) async {
    await DatabaseHelper.instance.addCategory(categoryName);
    // Recharger les catégories de manière asynchrone pour éviter notifyListeners pendant build
    _categories = await DatabaseHelper.instance.getAllCategories();
    // Utiliser scheduleMicrotask pour différer notifyListeners après le build
    scheduleMicrotask(() {
      notifyListeners();
    });
  }

  // ✅ Ajouter un produit
  Future<void> addProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Générer un UUID pour le produit s'il n'en a pas
      final productId = product.id ?? _uuid.v4();
      
      // Créer un nouveau produit avec l'ID généré
      final productWithId = ProductModel(
        id: productId,
        vendorId: product.vendorId,
        name: product.name,
        category: product.category,
        price: product.price,
        description: product.description,
        images: product.images,
        stockQuantity: product.stockQuantity,
        branchId: product.branchId,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
      
      print('✅ Ajout produit avec ID: $productId');
      
      final db = await DatabaseHelper.instance.database;
      await db.insert('products', productWithId.toMap());
      
      print('✅ Produit inséré dans la base de données');
      
      // Recharger les produits après ajout
      await loadVendorProducts(product.vendorId);
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du produit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ CORRECTION : Regrouper produits par vendeur
  Map<String, List<ProductWithVendorModel>> groupByVendor(
      [List<ProductWithVendorModel>? products]) {
    // Utiliser la liste fournie ou la liste par défaut
    final productList = products ?? _productsWithVendor;

    Map<String, List<ProductWithVendorModel>> grouped = {};

    for (var item in productList) {
      // ✅ CORRECTION : Utiliser vendorInfo au lieu de vendor
      final vendorId = item.vendorInfo.id.toString();

      if (!grouped.containsKey(vendorId)) {
        grouped[vendorId] = [];
      }
      grouped[vendorId]!.add(item);
    }

    return grouped;
  }

  // ✅ Refresh stock
  Future<void> refreshStock(String? vendorId) async {
    if (vendorId != null) {
      await loadVendorProducts(vendorId);
    } else {
      await loadAllProductsWithVendor();
    }
  }

  // ✅ NOUVEAU : Getter pour le nombre total de produits
  int get totalProductsCount => _productsWithVendor.length;

  // ✅ NOUVEAU : Getter pour les produits en rupture de stock
  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.stockQuantity == 0).toList();

  // ✅ NOUVEAU : Getter pour les produits en alerte stock
  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5).toList();
}