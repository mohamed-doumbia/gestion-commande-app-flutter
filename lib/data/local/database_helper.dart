import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client_stats_model.dart';
import '../models/message_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/vendor_info_mode.dart';
import '../models/product_with_vendor_model.dart';
import '../models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_gestion.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const userTable = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fullName TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      email TEXT,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      shopName TEXT,
      city TEXT,
      district TEXT
    )
    ''';

    const productTable = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vendorId INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      description TEXT,
      images TEXT,
      stockQuantity INTEGER DEFAULT 0,
      FOREIGN KEY (vendorId) REFERENCES users (id)
    )
    ''';

    const orderTable = '''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId INTEGER NOT NULL,
      totalAmount REAL NOT NULL,
      status TEXT DEFAULT 'En attente',
      date TEXT NOT NULL,
      FOREIGN KEY (clientId) REFERENCES users (id)
    )
    ''';

    const orderItemsTable = '''
    CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      orderId INTEGER NOT NULL,
      productId INTEGER NOT NULL,
      productName TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      FOREIGN KEY (orderId) REFERENCES orders (id),
      FOREIGN KEY (productId) REFERENCES products (id)
    )
    ''';

    const messageTable = '''
    CREATE TABLE messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      senderId INTEGER,
      receiverId INTEGER,
      text TEXT,
      date TEXT,
      isMe INTEGER
    )
    ''';

    const categoryTable = '''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      isDefault INTEGER DEFAULT 0
    )
    ''';

    // Créer toutes les tables
    await db.execute(userTable);
    await db.execute(productTable);
    await db.execute(orderTable);
    await db.execute(orderItemsTable);
    await db.execute(messageTable);
    await db.execute(categoryTable);

    // Initialiser les catégories par défaut
    await _initDefaultCategories(db);
  }

  Future<void> _initDefaultCategories(Database db) async {
    final defaultCategories = [
      'Nourriture',
      'Boisson',
      'Vêtements',
      'Électronique',
      'Autre',
    ];

    for (var cat in defaultCategories) {
      await db.insert(
        'categories',
        {'name': cat, 'isDefault': 1},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ============================================
  // GESTION DES UTILISATEURS
  // ============================================
  Future<int> createUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> loginUser(String phone, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<VendorInfoModel?> getVendorInfo(int vendorId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ? AND role = ?',
      whereArgs: [vendorId, 'vendeur'],
    );

    if (result.isEmpty) return null;
    return VendorInfoModel.fromMap(result.first);
  }

  // ============================================
  // GESTION DES CATÉGORIES
  // ============================================
  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      orderBy: 'isDefault DESC, name ASC',
    );
    return result.map((e) => e['name'] as String).toList();
  }

  Future<void> addCategory(String categoryName) async {
    final db = await instance.database;

    try {
      await db.insert(
        'categories',
        {
          'name': categoryName,
          'isDefault': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      print("Catégorie existe déjà: $categoryName");
    }
  }

  Future<bool> categoryExists(String categoryName) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [categoryName],
    );
    return result.isNotEmpty;
  }

  // ============================================
  // GESTION DES PRODUITS
  // ============================================
  Future<List<ProductWithVendorModel>> getAllProductsWithVendor() async {
    final db = await database;

    print('🔍 Exécution de la requête SQL getAllProductsWithVendor...');

    final result = await db.rawQuery('''
    SELECT 
      p.id,
      p.name,
      p.category,
      p.price,
      p.stockQuantity,
      p.description,
      p.images,
      p.vendorId,
      u.id as vendor_id,
      u.fullName as vendor_name,
      u.shopName as vendor_shop_name,
      u.phone as vendor_phone,
      u.city as vendor_city,
      u.district as vendor_district
    FROM products p
    INNER JOIN users u ON p.vendorId = u.id
    WHERE u.role = 'vendor'
    ORDER BY p.id DESC
  ''');

    print('📊 Requête SQL retournée: ${result.length} lignes');

    if (result.isEmpty) {
      print('⚠️ AUCUN PRODUIT DANS LA BASE DE DONNÉES');

      // Vérification des tables
      final productsCount = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final vendorsCount = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE role = 'vendor'");

      print('📦 Produits dans la table: ${productsCount.first['count']}');
      print('👤 Vendeurs dans la table: ${vendorsCount.first['count']}');

      return [];
    }

    return result.map((map) {
      // Extraire les infos produit
      final productMap = {
        'id': map['id'],
        'name': map['name'],
        'category': map['category'],
        'price': map['price'],
        'stockQuantity': map['stockQuantity'],
        'description': map['description'],
        'images': map['images'],
        'vendorId': map['vendorId'],
      };

      // Extraire les infos vendeur
      final vendorMap = {
        'id': map['vendor_id'],
        'name': map['vendor_name'],
        'shopName': map['vendor_shop_name'],
        'phone': map['vendor_phone'],
        'city': map['vendor_city'],
        'district': map['vendor_district'],
      };

      print('✅ Produit: ${map['name']} | Vendeur: ${map['vendor_name']}');

      return ProductWithVendorModel(
        product: ProductModel.fromMap(productMap),
        vendorInfo: VendorInfoModel.fromMap(vendorMap),
      );
    }).toList();
  }


  Future<void> debugDatabase() async {
    final db = await database;

    print('\n========== DEBUG DATABASE ==========');

    // Vérifier les produits
    final products = await db.query('products');
    print('📦 Total produits: ${products.length}');
    for (var p in products) {
      print('  - ${p['name']} (vendorId: ${p['vendorId']})');
    }

    // Vérifier les vendeurs
    final vendors = await db.query('users', where: "role = 'vendor'");
    print('👤 Total vendeurs: ${vendors.length}');
    for (var v in vendors) {
      print('  - ${v['fullName']} (id: ${v['id']})');
    }

    // Vérifier les clients
    final clients = await db.query('users', where: "role = 'client'");
    print('👥 Total clients: ${clients.length}');

    print('=====================================\n');
  }

  // ============================================
  // GESTION DES MESSAGES
  // ============================================
  Future<List<MessageModel>> getMessages(int userId, int otherId) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where:
      '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [userId, otherId, otherId, userId],
      orderBy: 'date ASC',
    );
    return result.map((e) => MessageModel.fromMap(e)).toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    final db = await instance.database;
    await db.insert('messages', message.toMap());
  }

  // ============================================
  // GESTION DES COMMANDES
  // ============================================
  Future<void> createOrder(int clientId, double total,
      List<Map<String, dynamic>> items) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final orderId = await txn.insert('orders', {
        'clientId': clientId,
        'totalAmount': total,
        'status': 'En attente',
        'date': DateTime.now().toIso8601String(),
      });

      for (var item in items) {
        await txn.insert('order_items', {
          'orderId': orderId,
          'productId': item['productId'],
          'productName': item['productName'],
          'quantity': item['quantity'],
          'price': item['price'],
        });

        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [item['quantity'], item['productId']],
        );
      }
    });
  }

  Future<List<OrderModel>> getVendorOrders(int vendorId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> orderIdsMap = await db.rawQuery('''
      SELECT DISTINCT o.id 
      FROM orders o
      JOIN order_items oi ON o.id = oi.orderId
      JOIN products p ON oi.productId = p.id
      WHERE p.vendorId = ?
      ORDER BY o.date DESC
    ''', [vendorId]);

    List<OrderModel> orders = [];

    for (var map in orderIdsMap) {
      int orderId = map['id'];

      final orderInfo = await db.rawQuery('''
        SELECT o.*, u.fullName as clientName
        FROM orders o
        JOIN users u ON o.clientId = u.id
        WHERE o.id = ?
      ''', [orderId]);

      if (orderInfo.isNotEmpty) {
        final itemsMap = await db.query(
          'order_items',
          where: 'orderId = ?',
          whereArgs: [orderId],
        );
        final items = itemsMap.map((e) => OrderItem.fromMap(e)).toList();

        orders.add(OrderModel.fromMap(orderInfo.first, items));
      }
    }
    return orders;
  }

  Future<int> updateOrderStatus(int orderId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ============================================
  // GESTION DES CLIENTS (STATS)
  // ============================================
  Future<List<ClientStatsModel>> getVendorClients(int vendorId) async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT 
      u.id,
      u.fullName,
      u.phone,
      COUNT(DISTINCT o.id) as orderCount,
      COALESCE(SUM(o.totalAmount), 0) as totalSpent,
      MAX(o.date) as lastOrderDate
    FROM users u
    LEFT JOIN orders o ON u.id = o.clientId AND o.vendorId = ?
    WHERE u.role = 'client'
      AND EXISTS (
        SELECT 1 FROM orders 
        WHERE clientId = u.id AND vendorId = ?
      )
    GROUP BY u.id
    ORDER BY totalSpent DESC
  ''', [vendorId, vendorId]);

    return result.map((map) => ClientStatsModel.fromMap(map)).toList();
  }
}