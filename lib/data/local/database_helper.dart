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

    // 🆕 MODIFIER: version 1 → version 2
    return await openDatabase(
      path,
      version: 2, // Nouvelle version
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // 🆕 AJOUTER
    );
  }

  // 🆕 AJOUTER: Gestion des migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 → v2 : Ajouter tables branches et employees

      const branchTable = '''
        CREATE TABLE branches (
          id TEXT PRIMARY KEY,
          vendorId INTEGER NOT NULL,
          name TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          country TEXT NOT NULL,
          city TEXT NOT NULL,
          district TEXT NOT NULL,
          address TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          phone TEXT NOT NULL,
          email TEXT,
          managerId TEXT,
          monthlyRent REAL DEFAULT 0,
          monthlyCharges REAL DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          openingDate TEXT NOT NULL,
          closingDate TEXT,
          openingHours TEXT DEFAULT '{}',
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (vendorId) REFERENCES users (id)
        )
      ''';

      const employeeTable = '''
        CREATE TABLE employees (
          id TEXT PRIMARY KEY,
          branchId TEXT NOT NULL,
          vendorId INTEGER NOT NULL,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          phone TEXT NOT NULL,
          email TEXT,
          role TEXT NOT NULL,
          permissions TEXT DEFAULT '[]',
          isActive INTEGER DEFAULT 1,
          hireDate TEXT NOT NULL,
          terminationDate TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (branchId) REFERENCES branches (id),
          FOREIGN KEY (vendorId) REFERENCES users (id)
        )
      ''';

      // ========================================
// 🆕 PHASE 2 : TABLES RH
// ========================================

// Table présences/pointages
const attendanceTable = '''
  CREATE TABLE employee_attendance (
    id TEXT PRIMARY KEY,
    employeeId TEXT NOT NULL,
    branchId TEXT NOT NULL,
    date TEXT NOT NULL,
    checkIn TEXT,
    checkOut TEXT,
    workedMinutes INTEGER DEFAULT 0,
    status TEXT NOT NULL,
    checkInLat REAL,
    checkInLong REAL,
    isValidated INTEGER DEFAULT 0,
    notes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (employeeId) REFERENCES employees (id),
    FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

// Table paies
 const payrollTable = '''
      CREATE TABLE employee_payroll (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        branchId TEXT NOT NULL,
        periodStart TEXT NOT NULL,
        periodEnd TEXT NOT NULL,
        baseSalary REAL NOT NULL,
        commission REAL DEFAULT 0,
        bonus REAL DEFAULT 0,
        deductions REAL DEFAULT 0,
        netSalary REAL NOT NULL,
        daysWorked INTEGER DEFAULT 0,
        hoursWorked INTEGER DEFAULT 0,
        salesGenerated REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        paidDate TEXT,
        paymentMethod TEXT,
        createdBy TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id),
        FOREIGN KEY (branchId) REFERENCES branches (id)
      )
''';

// Table demandes congés
 const leaveRequestsTable = '''
      CREATE TABLE leave_requests (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        branchId TEXT NOT NULL,
        type TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        numberOfDays INTEGER NOT NULL,
        reason TEXT,
        status TEXT DEFAULT 'pending',
        approvedBy TEXT,
        approvedAt TEXT,
        rejectionReason TEXT,
        attachment TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id),
        FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

// Table performance employés
      const performanceTable = '''
  CREATE TABLE employee_performance (
    id TEXT PRIMARY KEY,
    employeeId TEXT NOT NULL,
    branchId TEXT NOT NULL,
    month TEXT NOT NULL,
    totalOrders INTEGER DEFAULT 0,
    totalRevenue REAL DEFAULT 0,
    avgOrderValue REAL DEFAULT 0,
    daysWorked INTEGER DEFAULT 0,
    daysAbsent INTEGER DEFAULT 0,
    lateCount INTEGER DEFAULT 0,
    attendanceRate REAL DEFAULT 0,
    uniqueClients INTEGER DEFAULT 0,
    repeatClients INTEGER DEFAULT 0,
    ranking INTEGER DEFAULT 0,
    bonus REAL DEFAULT 0,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (employeeId) REFERENCES employees (id),
    FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

      await db.execute(branchTable);
      await db.execute(employeeTable);
      await db.execute(attendanceTable);
      await db.execute(payrollTable);
      await db.execute(leaveRequestsTable);
      await db.execute(performanceTable);

      // Ajouter colonnes branch_id aux tables existantes
      await db.execute('ALTER TABLE users ADD COLUMN branchId TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN branchId TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN branchId TEXT');

      try {
        await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN updated_at TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN created_at TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT');
        await db.execute('ALTER TABLE orders ADD COLUMN created_at TEXT');
        await db.execute('ALTER TABLE orders ADD COLUMN updated_at TEXT');

        // Mettre à jour les lignes existantes avec date actuelle
        final now = DateTime.now().toIso8601String();
        await db.execute("UPDATE users SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
        await db.execute("UPDATE products SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
        await db.execute("UPDATE orders SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
      } catch (e) {
        print('⚠️ Colonnes timestamps déjà existantes ou erreur: $e');
      }


      // Créer index pour performance
      await db.execute('CREATE INDEX idx_products_branch ON products(branchId)');
      await db.execute('CREATE INDEX idx_orders_branch ON orders(branchId)');
      await db.execute('CREATE INDEX idx_branches_vendor ON branches(vendorId)');
      await db.execute('CREATE INDEX idx_employees_branch ON employees(branchId)');

      // Index pour performance RH
      await db.execute('CREATE INDEX idx_attendance_employee ON employee_attendance(employeeId)');
      await db.execute('CREATE INDEX idx_attendance_branch ON employee_attendance(branchId)');
      await db.execute('CREATE INDEX idx_attendance_date ON employee_attendance(date)');
      await db.execute('CREATE INDEX idx_payroll_employee ON employee_payroll(employeeId)');
      await db.execute('CREATE INDEX idx_payroll_period ON employee_payroll(periodStart)');
      await db.execute('CREATE INDEX idx_leave_employee ON leave_requests(employeeId)');
      await db.execute('CREATE INDEX idx_performance_employee ON employee_performance(employeeId)');
      await db.execute('CREATE INDEX idx_performance_month ON employee_performance(month)');

      print('✅ Tables RH Phase 2 créées avec succès !');
    }
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
      district TEXT,
      branchId TEXT, 
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
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
      branchId TEXT,
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
      branchId TEXT,
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

    // 🆕 AJOUTER: Tables branches et employees
    const branchTable = '''
    CREATE TABLE branches (
      id TEXT PRIMARY KEY,
      vendorId INTEGER NOT NULL,
      name TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      country TEXT NOT NULL,
      city TEXT NOT NULL,
      district TEXT NOT NULL,
      address TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      phone TEXT NOT NULL,
      email TEXT,
      managerId TEXT,
      monthlyRent REAL DEFAULT 0,
      monthlyCharges REAL DEFAULT 0,
      isActive INTEGER DEFAULT 1,
      openingDate TEXT NOT NULL,
      closingDate TEXT,
      openingHours TEXT DEFAULT '{}',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (vendorId) REFERENCES users (id)
    )
    ''';

    const employeeTable = '''
    CREATE TABLE employees (
      id TEXT PRIMARY KEY,
      branchId TEXT NOT NULL,
      vendorId INTEGER NOT NULL,
      firstName TEXT NOT NULL,
      lastName TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      role TEXT NOT NULL,
      permissions TEXT DEFAULT '[]',
      isActive INTEGER DEFAULT 1,
      hireDate TEXT NOT NULL,
      terminationDate TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (branchId) REFERENCES branches (id),
      FOREIGN KEY (vendorId) REFERENCES users (id)
    )
    ''';

    // Table présences/pointages
    const attendanceTable = '''
  CREATE TABLE employee_attendance (
    id TEXT PRIMARY KEY,
    employeeId TEXT NOT NULL,
    branchId TEXT NOT NULL,
    date TEXT NOT NULL,
    checkIn TEXT,
    checkOut TEXT,
    workedMinutes INTEGER DEFAULT 0,
    status TEXT NOT NULL,
    checkInLat REAL,
    checkInLong REAL,
    isValidated INTEGER DEFAULT 0,
    notes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (employeeId) REFERENCES employees (id),
    FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

// Table paies
    const payrollTable = '''
      CREATE TABLE employee_payroll (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        branchId TEXT NOT NULL,
        periodStart TEXT NOT NULL,
        periodEnd TEXT NOT NULL,
        baseSalary REAL NOT NULL,
        commission REAL DEFAULT 0,
        bonus REAL DEFAULT 0,
        deductions REAL DEFAULT 0,
        netSalary REAL NOT NULL,
        daysWorked INTEGER DEFAULT 0,
        hoursWorked INTEGER DEFAULT 0,
        salesGenerated REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        paidDate TEXT,
        paymentMethod TEXT,
        createdBy TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id),
        FOREIGN KEY (branchId) REFERENCES branches (id)
      )
''';

// Table demandes congés
    const leaveRequestsTable = '''
      CREATE TABLE leave_requests (
        id TEXT PRIMARY KEY,
        employeeId TEXT NOT NULL,
        branchId TEXT NOT NULL,
        type TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        numberOfDays INTEGER NOT NULL,
        reason TEXT,
        status TEXT DEFAULT 'pending',
        approvedBy TEXT,
        approvedAt TEXT,
        rejectionReason TEXT,
        attachment TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id),
        FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

// Table performance employés
    const performanceTable = '''
  CREATE TABLE employee_performance (
    id TEXT PRIMARY KEY,
    employeeId TEXT NOT NULL,
    branchId TEXT NOT NULL,
    month TEXT NOT NULL,
    totalOrders INTEGER DEFAULT 0,
    totalRevenue REAL DEFAULT 0,
    avgOrderValue REAL DEFAULT 0,
    daysWorked INTEGER DEFAULT 0,
    daysAbsent INTEGER DEFAULT 0,
    lateCount INTEGER DEFAULT 0,
    attendanceRate REAL DEFAULT 0,
    uniqueClients INTEGER DEFAULT 0,
    repeatClients INTEGER DEFAULT 0,
    ranking INTEGER DEFAULT 0,
    bonus REAL DEFAULT 0,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (employeeId) REFERENCES employees (id),
    FOREIGN KEY (branchId) REFERENCES branches (id)
  )
''';

    // Créer toutes les tables
    await db.execute(userTable);
    await db.execute(productTable);
    await db.execute(orderTable);
    await db.execute(orderItemsTable);
    await db.execute(messageTable);
    await db.execute(categoryTable);
    await db.execute(branchTable);
    await db.execute(employeeTable);
    //  PHASE 2 : TABLES RH (dans _createDB)
    await db.execute(attendanceTable);
    await db.execute(payrollTable);
    await db.execute(leaveRequestsTable);
    await db.execute(performanceTable);



    // 🆕 AJOUTER: Index pour performance
    await db.execute('CREATE INDEX idx_products_branch ON products(branchId)');
    await db.execute('CREATE INDEX idx_orders_branch ON orders(branchId)');
    await db.execute('CREATE INDEX idx_branches_vendor ON branches(vendorId)');
    await db.execute('CREATE INDEX idx_employees_branch ON employees(branchId)');
    //POUR RH
    await db.execute('CREATE INDEX idx_attendance_employee ON employee_attendance(employeeId)');
    await db.execute('CREATE INDEX idx_attendance_branch ON employee_attendance(branchId)');
    await db.execute('CREATE INDEX idx_attendance_date ON employee_attendance(date)');
    await db.execute('CREATE INDEX idx_payroll_employee ON employee_payroll(employeeId)');
    await db.execute('CREATE INDEX idx_payroll_period ON employee_payroll(periodStart)');
    await db.execute('CREATE INDEX idx_leave_employee ON leave_requests(employeeId)');
    await db.execute('CREATE INDEX idx_performance_employee ON employee_performance(employeeId)');
    await db.execute('CREATE INDEX idx_performance_month ON employee_performance(month)');

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

  Future<UserModel?> getUserByPhone(String phone) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
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
      p.branchId,
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

      final productsCount = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final vendorsCount = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE role = 'vendor'");

      print('📦 Produits dans la table: ${productsCount.first['count']}');
      print('👤 Vendeurs dans la table: ${vendorsCount.first['count']}');

      return [];
    }

    return result.map((map) {
      final productMap = {
        'id': map['id'],
        'name': map['name'],
        'category': map['category'],
        'price': map['price'],
        'stockQuantity': map['stockQuantity'],
        'description': map['description'],
        'images': map['images'],
        'vendorId': map['vendorId'],
        'branchId': map['branchId'], // 🆕
      };

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

    final products = await db.query('products');
    print('📦 Total produits: ${products.length}');
    for (var p in products) {
      print('  - ${p['name']} (vendorId: ${p['vendorId']})');
    }

    final vendors = await db.query('users', where: "role = 'vendor'");
    print('👤 Total vendeurs: ${vendors.length}');
    for (var v in vendors) {
      print('  - ${v['fullName']} (id: ${v['id']})');
    }

    final clients = await db.query('users', where: "role = 'client'");
    print('👥 Total clients: ${clients.length}');

    // 🆕 AJOUTER: Debug branches
    final branches = await db.query('branches');
    print('🏢 Total succursales: ${branches.length}');
    for (var b in branches) {
      print('  - ${b['name']} (code: ${b['code']})');
    }

    // 🆕 AJOUTER: Debug employees
    final employees = await db.query('employees', where: 'isActive = 1');
    print('👔 Total employés actifs: ${employees.length}');

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
    final db = await instance.database;

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

  // ============================================
  // 🆕 GESTION DES SUCCURSALES (BRANCHES)
  // ============================================
  Future<String> insertBranch(Map<String, dynamic> branch) async {
    final db = await database;
    await db.insert('branches', branch);
    return branch['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getBranchesByVendor(int vendorId) async {
    final db = await database;
    return await db.query(
      'branches',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getBranch(String branchId) async {
    final db = await database;
    final results = await db.query(
      'branches',
      where: 'id = ?',
      whereArgs: [branchId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateBranch(String branchId, Map<String, dynamic> branch) async {
    final db = await database;
    return await db.update(
      'branches',
      branch,
      where: 'id = ?',
      whereArgs: [branchId],
    );
  }

  Future<int> deleteBranch(String branchId) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'branches',
      {
        'isActive': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [branchId],
    );
  }

  // ============================================
  // 🆕 GESTION DES EMPLOYÉS
  // ============================================
  Future<String> insertEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    await db.insert('employees', employee);
    return employee['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getEmployeesByBranch(String branchId) async {
    final db = await database;
    return await db.query(
      'employees',
      where: 'branchId = ? AND isActive = 1',
      whereArgs: [branchId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEmployeesByVendor(int vendorId) async {
    final db = await database;
    return await db.query(
      'employees',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getEmployee(String employeeId) async {
    final db = await database;
    final results = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateEmployee(String employeeId, Map<String, dynamic> employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee,
      where: 'id = ?',
      whereArgs: [employeeId],
    );
  }

  Future<int> deleteEmployee(String employeeId) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'employees',
      {
        'isActive': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [employeeId],
    );
  }


// ============================================
// 🆕 GESTION DES PRÉSENCES (ATTENDANCE)
// ============================================


  Future<String> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    await db.insert('employee_attendance', attendance);
    return attendance['id'] as String;
  }


  Future<List<Map<String, dynamic>>> getAttendanceByEmployee(
      String employeeId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final db = await database;
    return await db.query(
      'employee_attendance',
      where: 'employeeId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        employeeId,
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
      orderBy: 'date DESC',
    );
  }


  Future<List<Map<String, dynamic>>> getAttendanceByBranch(
      String branchId,
      DateTime date,
      ) async {
    final db = await database;
    return await db.query(
      'employee_attendance',
      where: 'branchId = ? AND date = ?',
      whereArgs: [branchId, date.toIso8601String().split('T')[0]],
    );
  }

  Future<Map<String, dynamic>?> getTodayAttendance(String employeeId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final results = await db.query(
      'employee_attendance',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, today],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateAttendance(String attendanceId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'employee_attendance',
      data,
      where: 'id = ?',
      whereArgs: [attendanceId],
    );
  }

  // ============================================
// 🆕 GESTION DES PAIES (PAYROLL)
// ============================================
  Future<String> insertPayroll(Map<String, dynamic> payroll) async {
    final db = await database;
    await db.insert('employee_payroll', payroll);
    return payroll['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getPayrollByEmployee(String employeeId) async {
    final db = await database;
    return await db.query(
      'employee_payroll',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'periodStart DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPayrollByBranch(
      String branchId,
      DateTime periodStart,
      ) async {
    final db = await database;
    return await db.query(
      'employee_payroll',
      where: 'branchId = ? AND periodStart = ?',
      whereArgs: [branchId, periodStart.toIso8601String().split('T')[0]],
    );
  }

  Future<int> updatePayroll(String payrollId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'employee_payroll',
      data,
      where: 'id = ?',
      whereArgs: [payrollId],
    );
  }

  // ============================================
// 🆕 GESTION DES CONGÉS (LEAVE REQUESTS)
// ============================================
  Future<String> insertLeaveRequest(Map<String, dynamic> leave) async {
    final db = await database;
    await db.insert('leave_requests', leave);
    return leave['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getLeaveRequestsByEmployee(String employeeId) async {
    final db = await database;
    return await db.query(
      'leave_requests',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingLeaveRequests(String branchId) async {
    final db = await database;
    return await db.query(
      'leave_requests',
      where: 'branchId = ? AND status = ?',
      whereArgs: [branchId, 'pending'],
      orderBy: 'createdAt ASC',
    );
  }


  Future<int> updateLeaveRequest(String leaveId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'leave_requests',
      data,
      where: 'id = ?',
      whereArgs: [leaveId],
    );
  }


  // ============================================
// 🆕 GESTION PERFORMANCE
// ============================================
  Future<String> insertPerformance(Map<String, dynamic> performance) async {
    final db = await database;
    await db.insert('employee_performance', performance);
    return performance['id'] as String;
  }


  Future<Map<String, dynamic>?> getPerformance(String employeeId, String month) async {
    final db = await database;
    final results = await db.query(
      'employee_performance',
      where: 'employeeId = ? AND month = ?',
      whereArgs: [employeeId, month],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getBranchPerformance(
      String branchId,
      String month,
      ) async {
    final db = await database;
    return await db.query(
      'employee_performance',
      where: 'branchId = ? AND month = ?',
      whereArgs: [branchId, month],
      orderBy: 'totalRevenue DESC',
    );
  }

  Future<int> updatePerformance(String performanceId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'employee_performance',
      data,
      where: 'id = ?',
      whereArgs: [performanceId],
    );
  }







}