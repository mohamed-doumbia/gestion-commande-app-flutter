import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client_stats_model.dart';
import '../models/message_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

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
      shopName TEXT
    )
    ''';

    // Dans DatabaseHelper._createDB...
    // ... après la table users

    const productTable = '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vendorId INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      description TEXT,
      imagePath TEXT,
      stockQuantity INTEGER DEFAULT 0,
      FOREIGN KEY (vendorId) REFERENCES users (id)
    )
    ''';

    // ... après la table products

    const orderTable = '''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId INTEGER NOT NULL,
      totalAmount REAL NOT NULL,
      status TEXT DEFAULT 'En attente', -- En attente, Validée, Rejetée, Livrée
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

    // Dans _createDB...
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

    await db.execute(messageTable);

    await db.execute(orderTable);
    await db.execute(orderItemsTable);

    await db.execute(productTable);

    await db.execute(userTable);
    // On ajoutera les tables Products et Orders ici plus tard
  }

  Future<int> createUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  // Dans DatabaseHelper...
  Future<List<MessageModel>> getMessages(int userId, int otherId) async {
    final db = await instance.database;
    final result = await db.query(
        'messages',
        where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
        whereArgs: [userId, otherId, otherId, userId],
        orderBy: 'date ASC' // Chronologique
    );
    return result.map((e) => MessageModel.fromMap(e)).toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    final db = await instance.database;
    await db.insert('messages', message.toMap());
  }

  // Dans DatabaseHelper

// Dans DatabaseHelper...

  Future<void> createOrder(int clientId, double total, List<Map<String, dynamic>> items) async {
    final db = await instance.database;

    // On utilise une "Transaction" pour que tout se fasse en même temps
    // (Sécurité : si ça plante au milieu, ça annule tout)
    await db.transaction((txn) async {

      // 1. Créer la commande
      final orderId = await txn.insert('orders', {
        'clientId': clientId,
        'totalAmount': total,
        'status': 'En attente',
        'date': DateTime.now().toIso8601String(),
        'isSynced': 0, // Pour la synchro future
      });

      // 2. Traiter chaque article
      for (var item in items) {
        // A. Ajouter la ligne de commande
        await txn.insert('order_items', {
          'orderId': orderId,
          'productId': item['productId'],
          'productName': item['productName'],
          'quantity': item['quantity'],
          'price': item['price'],
        });

        // B. --- LA GESTION DE STOCK AUTOMATIQUE EST ICI ---
        // On décrémente (soustrait) la quantité du stock du produit
        await txn.rawUpdate(
            'UPDATE products SET stockQuantity = stockQuantity - ? WHERE id = ?',
            [item['quantity'], item['productId']]
        );
      }
    });
  }

  // Récupérer les commandes d'un vendeur spécifique
  Future<List<OrderModel>> getVendorOrders(int vendorId) async {
    final db = await instance.database;

    // 1. Trouver les IDs des commandes qui contiennent des produits de ce vendeur
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

      // 2. Pour chaque commande, récupérer les infos générales + Nom Client
      final orderInfo = await db.rawQuery('''
        SELECT o.*, u.fullName as clientName
        FROM orders o
        JOIN users u ON o.clientId = u.id
        WHERE o.id = ?
      ''', [orderId]);

      if (orderInfo.isNotEmpty) {
        // 3. Récupérer les items de cette commande
        final itemsMap = await db.query('order_items', where: 'orderId = ?', whereArgs: [orderId]);
        final items = itemsMap.map((e) => OrderItem.fromMap(e)).toList();

        orders.add(OrderModel.fromMap(orderInfo.first, items));
      }
    }
    return orders;
  }

  // Dans DatabaseHelper...

  Future<List<ClientStatsModel>> getVendorClients(int vendorId) async {
    final db = await instance.database;

    // Cette requête est magique : elle joint les tables pour trouver
    // QUI a acheté QUOI appartenant à ce VENDEUR
    final result = await db.rawQuery('''
      SELECT 
        u.id, 
        u.fullName, 
        u.phone, 
        COUNT(DISTINCT o.id) as orderCount, 
        SUM(oi.price * oi.quantity) as totalSpent
      FROM users u
      JOIN orders o ON u.id = o.clientId
      JOIN order_items oi ON o.id = oi.orderId
      JOIN products p ON oi.productId = p.id
      WHERE p.vendorId = ?
      GROUP BY u.id
      ORDER BY totalSpent DESC
    ''', [vendorId]);

    return result.map((e) => ClientStatsModel.fromMap(e)).toList();
  }

  // Changer le statut
  Future<int> updateOrderStatus(int orderId, String newStatus) async {
    final db = await instance.database;
    return await db.update(
      'orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
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
}

