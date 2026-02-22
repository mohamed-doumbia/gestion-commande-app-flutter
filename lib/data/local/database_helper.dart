import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
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
    // Appeler _ensureAllTablesAndColumns après l'ouverture pour garantir que toutes les colonnes existent
    await _ensureAllTablesAndColumns(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // ============================================
    // INITIALISATION DE LA BASE DE DONNÉES
    // ============================================
    // Version actuelle : 13
    // Historique des versions :
    // - v1 : Version initiale (users, products, orders)
    // - v2 : Ajout tables branches, employees et tables RH
    // - v3 : Ajout created_at/updated_at à products
    // - v4 : Correction nommage colonnes branches (snake_case) et retrait champs financiers
    // - v5 : Ajout tables branch_transactions et branch_recurring_costs (Phase 3 - Comptabilité)
    // - v6 : Adresse succursale rendue optionnelle et correction type vendorId
    // - v7 : Phase 4 - Gestion employés : tables roles, permission_requests, modification employees
    // - v8 : Ajout colonnes photo et idCard à employees
    // - v9 : Ajout toutes les colonnes manquantes à employees (contractType, baseSalary, paymentFrequency, etc.)
    // - v10 : Migration UUID - Conversion de tous les IDs INTEGER en TEXT (UUID)
    // - v11 : Ajout champ access_code pour authentification employés
    // - v12 : Ajout champ department_code à la table roles pour génération automatique
    // - v13 : Ajout tables marketing_expenses et marketing_budgets (Département Marketing)
    return await openDatabase(
      path,
      version: 13, // Utilisation de la méthode dynamique pour éviter d'incrémenter la version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================
  // MÉTHODES UTILITAIRES POUR GESTION DYNAMIQUE
  // ============================================
  
  /// Vérifier si une table existe
  Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier si une colonne existe dans une table
  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      return columns.any((col) => col['name'] == columnName);
    } catch (e) {
      return false;
    }
  }

  /// Créer une table si elle n'existe pas
  Future<void> _ensureTableExists(Database db, String tableName, String createStatement) async {
    final exists = await _tableExists(db, tableName);
    if (!exists) {
      await db.execute(createStatement);
      print('✅ Table $tableName créée');
    } else {
      print('ℹ️ Table $tableName existe déjà');
    }
  }

  /// Ajouter une colonne si elle n'existe pas
  Future<void> _ensureColumnExists(Database db, String tableName, String columnName, String columnDefinition) async {
    final exists = await _columnExists(db, tableName, columnName);
    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition');
      print('✅ Colonne $columnName ajoutée à $tableName');
    } else {
      print('ℹ️ Colonne $columnName existe déjà dans $tableName');
    }
  }

  /// Créer un index si il n'existe pas
  Future<void> _ensureIndexExists(Database db, String indexName, String createIndexStatement) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
        [indexName],
      );
      if (result.isEmpty) {
        await db.execute(createIndexStatement);
        print('✅ Index $indexName créé');
      } else {
        print('ℹ️ Index $indexName existe déjà');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la création de l\'index $indexName: $e');
    }
  }

  /// ============================================
  /// MIGRATION UNIVERSELLE - VÉRIFICATION DYNAMIQUE
  /// ============================================
  /// Cette méthode vérifie et crée automatiquement les tables/colonnes manquantes
  /// sans nécessiter d'incrémenter la version à chaque fois
  Future<void> _ensureAllTablesAndColumns(Database db) async {
    print('🔄 Vérification dynamique des tables et colonnes...');

    // Tables marketing (vérifier si elles existent)
    await _ensureTableExists(db, 'marketing_expenses', '''
      CREATE TABLE marketing_expenses (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category TEXT NOT NULL,
        activity TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (branch_id) REFERENCES branches (id)
      )
    ''');

    await _ensureTableExists(db, 'marketing_budgets', '''
      CREATE TABLE marketing_budgets (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category TEXT NOT NULL,
        budget_amount REAL NOT NULL,
        period_type TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (branch_id) REFERENCES branches (id)
      )
    ''');

    // Index marketing
    await _ensureIndexExists(db, 'idx_marketing_expenses_branch', 
      'CREATE INDEX idx_marketing_expenses_branch ON marketing_expenses(branch_id)');
    await _ensureIndexExists(db, 'idx_marketing_expenses_date', 
      'CREATE INDEX idx_marketing_expenses_date ON marketing_expenses(expense_date)');
    await _ensureIndexExists(db, 'idx_marketing_expenses_category', 
      'CREATE INDEX idx_marketing_expenses_category ON marketing_expenses(category)');
    await _ensureIndexExists(db, 'idx_marketing_budgets_branch', 
      'CREATE INDEX idx_marketing_budgets_branch ON marketing_budgets(branch_id)');
    await _ensureIndexExists(db, 'idx_marketing_budgets_period', 
      'CREATE INDEX idx_marketing_budgets_period ON marketing_budgets(period_start, period_end)');

    // Vérifier les colonnes importantes qui pourraient manquer
    await _ensureColumnExists(db, 'employees', 'access_code', 'TEXT UNIQUE');
    await _ensureColumnExists(db, 'roles', 'department_code', 'TEXT');
    await _ensureColumnExists(db, 'users', 'is_deleted', 'INTEGER DEFAULT 0');

    // Générer des IDs pour les produits existants qui n'en ont pas
    await _fixProductsWithoutId(db);

    print('✅ Vérification dynamique terminée');
  }

  /// Générer des IDs pour les produits existants qui n'en ont pas
  Future<void> _fixProductsWithoutId(Database db) async {
    try {
      // Vérifier si la table products existe
      final tableExists = await _tableExists(db, 'products');
      if (!tableExists) return;

      // Trouver les produits sans ID (en utilisant rowid car id est PRIMARY KEY)
      final productsWithoutId = await db.rawQuery('''
        SELECT rowid, name, vendorId, category, price, stockQuantity, description, images, branchId, created_at, updated_at
        FROM products
        WHERE id IS NULL OR id = '' OR id = 'null'
      ''');

      if (productsWithoutId.isEmpty) {
        print('ℹ️ Tous les produits ont un ID');
        return;
      }

      print('⚠️ ${productsWithoutId.length} produit(s) sans ID trouvé(s), génération des IDs...');

      final uuid = const Uuid();
      final batch = db.batch();

      for (final product in productsWithoutId) {
        final newId = uuid.v4();
        final rowid = product['rowid'] as int;
        
        // Créer un nouveau produit avec l'ID généré
        batch.rawUpdate(
          '''
          UPDATE products 
          SET id = ?, updated_at = ?
          WHERE rowid = ?
          ''',
          [newId, DateTime.now().toIso8601String(), rowid],
        );
        print('✅ ID généré pour produit "${product['name']}": $newId');
      }

      await batch.commit(noResult: true);
      print('✅ ${productsWithoutId.length} produit(s) mis à jour avec des IDs');
    } catch (e) {
      print('⚠️ Erreur lors de la génération des IDs pour les produits: $e');
      // Ne pas bloquer l'application si cette opération échoue
    }
  }

  // 🆕 AJOUTER: Gestion des migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 → v2 : Ajouter tables branches et employees

      // ============================================
      // TABLE : branches (Succursales)
      // ============================================
      // Description : Stocke les informations de base des succursales
      // Note : Les informations financières (loyer, charges) seront gérées
      //        dans la table branch_transactions (Phase 3)
      const branchTable = '''
        CREATE TABLE branches (
          id TEXT PRIMARY KEY,
          vendor_id TEXT NOT NULL,
          name TEXT NOT NULL,
          code TEXT NOT NULL UNIQUE,
          country TEXT NOT NULL,
          city TEXT NOT NULL,
          district TEXT NOT NULL,
          address TEXT,
          latitude REAL,
          longitude REAL,
          phone TEXT,
          email TEXT,
          manager_id TEXT,
          is_active INTEGER DEFAULT 1,
          opening_date TEXT NOT NULL,
          closing_date TEXT,
          opening_hours TEXT DEFAULT '{}',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (vendor_id) REFERENCES users (id)
        )
      ''';

    const employeeTable = '''
    CREATE TABLE employees (
      id TEXT PRIMARY KEY,
      branchId TEXT NOT NULL,
      vendorId TEXT NOT NULL,
      firstName TEXT NOT NULL,
      lastName TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      photo TEXT,
      idCard TEXT,
      role TEXT NOT NULL,
      role_id TEXT,
      department_code TEXT,
      access_code TEXT UNIQUE,
      contractType TEXT,
      contract_type TEXT,
      permissions TEXT DEFAULT '[]',
      baseSalary REAL DEFAULT 0,
      salary REAL,
      paymentFrequency TEXT DEFAULT 'monthly',
      paymentMethod TEXT,
      commissionRate REAL,
      bonus REAL,
      annualLeaveDays INTEGER DEFAULT 30,
      usedLeaveDays INTEGER DEFAULT 0,
      sickLeaveDays INTEGER DEFAULT 0,
      totalSales INTEGER DEFAULT 0,
      totalRevenue REAL DEFAULT 0,
      customerRating REAL,
      isActive INTEGER DEFAULT 1,
      is_deleted INTEGER DEFAULT 0,
      hireDate TEXT NOT NULL,
      terminationDate TEXT,
      emergencyContact TEXT,
      emergency_contact TEXT,
      emergencyPhone TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (branchId) REFERENCES branches (id),
      FOREIGN KEY (vendorId) REFERENCES users (id),
      FOREIGN KEY (role_id) REFERENCES roles (id)
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

      // ============================================
      // AJOUT COLONNES branch_id AUX TABLES EXISTANTES
      // ============================================
      // Permet de lier users, products et orders à une succursale spécifique
      await db.execute('ALTER TABLE users ADD COLUMN branchId TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN branchId TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN branchId TEXT');

      try {
        // Vérifier si les colonnes existent déjà avant de les ajouter (pour éviter les erreurs)
        final productsColumns = await db.rawQuery("PRAGMA table_info(products)");
        final hasProductsCreatedAt = productsColumns.any((col) => col['name'] == 'created_at');
        final hasProductsUpdatedAt = productsColumns.any((col) => col['name'] == 'updated_at');
        
        if (!hasProductsCreatedAt) {
          await db.execute('ALTER TABLE products ADD COLUMN created_at TEXT');
        }
        if (!hasProductsUpdatedAt) {
          await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT');
        }
        
        final usersColumns = await db.rawQuery("PRAGMA table_info(users)");
        final hasUsersCreatedAt = usersColumns.any((col) => col['name'] == 'created_at');
        final hasUsersUpdatedAt = usersColumns.any((col) => col['name'] == 'updated_at');
        
        if (!hasUsersCreatedAt) {
          await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
        }
        if (!hasUsersUpdatedAt) {
          await db.execute('ALTER TABLE users ADD COLUMN updated_at TEXT');
        }
        
        final ordersColumns = await db.rawQuery("PRAGMA table_info(orders)");
        final hasOrdersCreatedAt = ordersColumns.any((col) => col['name'] == 'created_at');
        final hasOrdersUpdatedAt = ordersColumns.any((col) => col['name'] == 'updated_at');
        
        if (!hasOrdersCreatedAt) {
          await db.execute('ALTER TABLE orders ADD COLUMN created_at TEXT');
        }
        if (!hasOrdersUpdatedAt) {
          await db.execute('ALTER TABLE orders ADD COLUMN updated_at TEXT');
        }

        // Mettre à jour les lignes existantes avec date actuelle
        final now = DateTime.now().toIso8601String();
        await db.execute("UPDATE users SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
        await db.execute("UPDATE products SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
        await db.execute("UPDATE orders SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
      } catch (e) {
        print('⚠️ Erreur lors de l\'ajout des colonnes timestamps: $e');
      }


      // ============================================
      // CRÉATION DES INDEX POUR OPTIMISATION DES PERFORMANCES
      // ============================================
      // Les index accélèrent les recherches et jointures fréquentes
      await db.execute('CREATE INDEX idx_products_branch ON products(branchId)');
      await db.execute('CREATE INDEX idx_orders_branch ON orders(branchId)');
      await db.execute('CREATE INDEX idx_branches_vendor ON branches(vendor_id)');
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
    
    if (oldVersion < 3) {
      // Migration v2 → v3 : Ajouter created_at et updated_at à products si manquants
      print('🔄 Migration v2 → v3 : Ajout des colonnes timestamps à products...');
      
      try {
        // Vérifier si les colonnes existent déjà
        final productsColumns = await db.rawQuery("PRAGMA table_info(products)");
        final hasProductsCreatedAt = productsColumns.any((col) => col['name'] == 'created_at');
        final hasProductsUpdatedAt = productsColumns.any((col) => col['name'] == 'updated_at');
        
        if (!hasProductsCreatedAt) {
          await db.execute('ALTER TABLE products ADD COLUMN created_at TEXT');
          print('✅ Colonne created_at ajoutée à products');
        }
        if (!hasProductsUpdatedAt) {
          await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT');
          print('✅ Colonne updated_at ajoutée à products');
        }
        
        // Mettre à jour les produits existants avec la date actuelle
        final now = DateTime.now().toIso8601String();
        await db.execute("UPDATE products SET created_at = '$now', updated_at = '$now' WHERE created_at IS NULL");
        
        print('✅ Migration v2 → v3 terminée avec succès !');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v2 → v3: $e');
        rethrow; // Relancer pour que l'app sache qu'il y a un problème
      }
    }
    
    // ============================================
    // MIGRATION v3 → v4 : CORRECTION STRUCTURE TABLE branches
    // ============================================
    // Objectif : Standardiser le nommage des colonnes en snake_case
    //            et retirer les champs financiers (seront dans branch_transactions)
    if (oldVersion < 4) {
      print('🔄 Migration v3 → v4 : Correction structure table branches...');
      
      try {
        // Vérifier la structure actuelle de la table branches
        final branchesColumns = await db.rawQuery("PRAGMA table_info(branches)");
        final columnNames = branchesColumns.map((col) => col['name'] as String).toList();
        
        print('📋 Colonnes actuelles branches: ${columnNames.join(", ")}');
        
        // Renommer vendorId → vendor_id si nécessaire
        if (columnNames.contains('vendorId') && !columnNames.contains('vendor_id')) {
          // SQLite ne supporte pas RENAME COLUMN directement, on doit recréer la table
          // Mais pour éviter la perte de données, on utilise une approche sécurisée
          await db.execute('ALTER TABLE branches RENAME TO branches_old');
          
          // Créer la nouvelle table avec la bonne structure
          await db.execute('''
            CREATE TABLE branches (
              id TEXT PRIMARY KEY,
              vendor_id TEXT NOT NULL,
              name TEXT NOT NULL,
              code TEXT NOT NULL UNIQUE,
              country TEXT NOT NULL,
              city TEXT NOT NULL,
              district TEXT NOT NULL,
              address TEXT,
              latitude REAL,
              longitude REAL,
              phone TEXT,
              email TEXT,
              manager_id TEXT,
              is_active INTEGER DEFAULT 1,
              opening_date TEXT NOT NULL,
              closing_date TEXT,
              opening_hours TEXT DEFAULT '{}',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (vendor_id) REFERENCES users (id)
            )
          ''');
          
          // Copier les données en mappant les anciennes colonnes vers les nouvelles
          await db.execute('''
            INSERT INTO branches (
              id, vendor_id, name, code, country, city, district, address,
              latitude, longitude, phone, email, manager_id,
              is_active, opening_date, closing_date, opening_hours,
              created_at, updated_at
            )
            SELECT 
              id,
              vendorId as vendor_id,
              name,
              code,
              country,
              city,
              district,
              address,
              latitude,
              longitude,
              phone,
              email,
              managerId as manager_id,
              isActive as is_active,
              openingDate as opening_date,
              closingDate as closing_date,
              openingHours as opening_hours,
              createdAt as created_at,
              updatedAt as updated_at
            FROM branches_old
          ''');
          
          // Supprimer l'ancienne table
          await db.execute('DROP TABLE branches_old');
          
          print('✅ Colonne vendorId renommée en vendor_id');
        }
        
        // Renommer managerId → manager_id si nécessaire (déjà fait ci-dessus)
        // Renommer isActive → is_active si nécessaire (déjà fait ci-dessus)
        // Renommer openingDate → opening_date si nécessaire (déjà fait ci-dessus)
        // Renommer closingDate → closing_date si nécessaire (déjà fait ci-dessus)
        // Renommer openingHours → opening_hours si nécessaire (déjà fait ci-dessus)
        // Renommer createdAt → created_at si nécessaire (déjà fait ci-dessus)
        // Renommer updatedAt → updated_at si nécessaire (déjà fait ci-dessus)
        
        // Retirer monthlyRent et monthlyCharges si elles existent
        // Note : Ces colonnes seront gérées dans branch_transactions (Phase 3)
        // On ne les supprime pas pour éviter la perte de données existantes
        // Elles seront simplement ignorées dans le code
        
        print('✅ Migration v3 → v4 terminée avec succès !');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v3 → v4: $e');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
        // La table peut déjà avoir la bonne structure
      }
    }

    // ============================================
    // MIGRATION v4 → v5 : AJOUT TABLES COMPTABILITÉ
    // ============================================
    // Objectif : Ajouter les tables pour la gestion comptable des succursales
    if (oldVersion < 5) {
      print('🔄 Migration v4 → v5 : Ajout tables comptabilité...');
      
      try {
        // Table transactions financières
        await db.execute('''
          CREATE TABLE IF NOT EXISTS branch_transactions (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            attachment TEXT,
            created_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (branch_id) REFERENCES branches (id)
          )
        ''');

        // Table coûts récurrents
        await db.execute('''
          CREATE TABLE IF NOT EXISTS branch_recurring_costs (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            frequency TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            is_active INTEGER DEFAULT 1,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (branch_id) REFERENCES branches (id)
          )
        ''');

        // Créer les index pour optimiser les performances
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_branch ON branch_transactions(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON branch_transactions(date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type ON branch_transactions(type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recurring_costs_branch ON branch_recurring_costs(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_recurring_costs_active ON branch_recurring_costs(is_active)');

        print('✅ Migration v4 → v5 terminée avec succès !');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v4 → v5: $e');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // ============================================
    // MIGRATION v5 → v6 : ADRESSE ET TÉLÉPHONE OPTIONNELS
    // ============================================
    // Objectif : Rendre l'adresse et le téléphone optionnels dans la table branches
    // Méthode : Recréer la table car SQLite ne supporte pas ALTER COLUMN pour modifier NOT NULL
    if (oldVersion < 6) {
      print('🔄 Migration v5 → v6 : Adresse et téléphone optionnels...');
      
      try {
        // Vérifier si la table existe
        final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='branches'");
        if (tableInfo.isEmpty) {
          print('ℹ️ Table branches n\'existe pas encore, sera créée avec la nouvelle structure');
          print('✅ Migration v5 → v6 terminée avec succès !');
          return;
        }

        // Vérifier la structure actuelle
        final branchesColumns = await db.rawQuery("PRAGMA table_info(branches)");
        final hasAddressNotNull = branchesColumns.any((col) => 
          col['name'] == 'address' && col['notnull'] == 1);
        final hasPhoneNotNull = branchesColumns.any((col) => 
          col['name'] == 'phone' && col['notnull'] == 1);

        // Si address ou phone sont NOT NULL, on doit recréer la table
        if (hasAddressNotNull || hasPhoneNotNull) {
          print('📋 Recréation de la table branches pour rendre address et phone optionnels...');
          
          // Sauvegarder les données existantes
          final oldData = await db.rawQuery('SELECT * FROM branches');
          
          // Renommer l'ancienne table
          await db.execute('ALTER TABLE branches RENAME TO branches_old');
          
          // Créer la nouvelle table avec address et phone optionnels
          await db.execute('''
            CREATE TABLE branches (
              id TEXT PRIMARY KEY,
              vendor_id TEXT NOT NULL,
              name TEXT NOT NULL,
              code TEXT NOT NULL UNIQUE,
              country TEXT NOT NULL,
              city TEXT NOT NULL,
              district TEXT NOT NULL,
              address TEXT,
              latitude REAL,
              longitude REAL,
              phone TEXT,
              email TEXT,
              manager_id TEXT,
              is_active INTEGER DEFAULT 1,
              opening_date TEXT NOT NULL,
              closing_date TEXT,
              opening_hours TEXT DEFAULT '{}',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (vendor_id) REFERENCES users (id)
            )
          ''');
          
          // Recréer l'index
          await db.execute('CREATE INDEX IF NOT EXISTS idx_branches_vendor ON branches(vendor_id)');
          
          // Copier les données (address et phone peuvent être NULL maintenant)
          for (var row in oldData) {
            await db.insert('branches', {
              'id': row['id'],
              'vendor_id': row['vendor_id'],
              'name': row['name'],
              'code': row['code'],
              'country': row['country'],
              'city': row['city'],
              'district': row['district'],
              'address': row['address'], // Peut être NULL
              'latitude': row['latitude'],
              'longitude': row['longitude'],
              'phone': row['phone'], // Peut être NULL maintenant
              'email': row['email'],
              'manager_id': row['manager_id'],
              'is_active': row['is_active'],
              'opening_date': row['opening_date'],
              'closing_date': row['closing_date'],
              'opening_hours': row['opening_hours'],
              'created_at': row['created_at'],
              'updated_at': row['updated_at'],
            });
          }
          
          // Supprimer l'ancienne table
          await db.execute('DROP TABLE branches_old');
          
          print('✅ Table branches recréée avec succès !');
        }
        
        print('✅ Migration v5 → v6 terminée avec succès !');
        print('ℹ️ Note : Les nouvelles succursales peuvent avoir une adresse et un téléphone NULL');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v5 → v6: $e');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // ============================================
    // MIGRATION v6 → v7 : PHASE 4 - GESTION EMPLOYÉS ET RÔLES
    // ============================================
    if (oldVersion < 7) {
      try {
        print('🔄 Migration v6 → v7 : Phase 4 - Gestion employés et rôles...');
        
        // 1. Créer la table roles
        await db.execute('''
          CREATE TABLE IF NOT EXISTS roles (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            name TEXT NOT NULL,
            department TEXT NOT NULL,
            department_code TEXT,
            permissions TEXT,
            created_by TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (branch_id) REFERENCES branches (id)
          )
        ''');
        
        // 2. Créer la table permission_requests
        await db.execute('''
          CREATE TABLE IF NOT EXISTS permission_requests (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            employee_id TEXT NOT NULL,
            transaction_id TEXT,
            request_type TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT DEFAULT 'PENDING',
            reviewed_by TEXT,
            reviewed_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (branch_id) REFERENCES branches (id),
            FOREIGN KEY (employee_id) REFERENCES employees (id)
          )
        ''');
        
        // 3. Ajouter les nouvelles colonnes à la table employees
        // Vérifier si les colonnes existent déjà
        final employeeColumns = await db.rawQuery("PRAGMA table_info(employees)");
        final hasRoleId = employeeColumns.any((col) => col['name'] == 'role_id');
        final hasDepartmentCode = employeeColumns.any((col) => col['name'] == 'department_code');
        final hasIsDeleted = employeeColumns.any((col) => col['name'] == 'is_deleted');
        final hasSalary = employeeColumns.any((col) => col['name'] == 'salary');
        final hasContractType = employeeColumns.any((col) => col['name'] == 'contract_type');
        final hasEmergencyContact = employeeColumns.any((col) => col['name'] == 'emergency_contact');
        
        if (!hasRoleId) {
          await db.execute('ALTER TABLE employees ADD COLUMN role_id TEXT');
        }
        if (!hasDepartmentCode) {
          await db.execute('ALTER TABLE employees ADD COLUMN department_code TEXT');
        }
        if (!hasIsDeleted) {
          await db.execute('ALTER TABLE employees ADD COLUMN is_deleted INTEGER DEFAULT 0');
        }
        if (!hasSalary) {
          await db.execute('ALTER TABLE employees ADD COLUMN salary REAL');
        }
        if (!hasContractType) {
          await db.execute('ALTER TABLE employees ADD COLUMN contract_type TEXT');
        }
        if (!hasEmergencyContact) {
          await db.execute('ALTER TABLE employees ADD COLUMN emergency_contact TEXT');
        }
        
        // 4. Ajouter is_deleted à branch_transactions pour soft delete
        final transactionColumns = await db.rawQuery("PRAGMA table_info(branch_transactions)");
        final hasTransactionIsDeleted = transactionColumns.any((col) => col['name'] == 'is_deleted');
        if (!hasTransactionIsDeleted) {
          await db.execute('ALTER TABLE branch_transactions ADD COLUMN is_deleted INTEGER DEFAULT 0');
        }
        
        // Créer les index pour optimiser les performances
        await db.execute('CREATE INDEX IF NOT EXISTS idx_roles_branch ON roles(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_roles_department ON roles(department)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_permission_requests_branch ON permission_requests(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_permission_requests_status ON permission_requests(status)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_role ON employees(role_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_deleted ON employees(is_deleted)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_deleted ON branch_transactions(is_deleted)');
        
        print('✅ Migration v6 → v7 terminée avec succès !');
        print('ℹ️ Phase 4 : Tables roles, permission_requests créées, colonnes ajoutées à employees');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v6 → v7: $e');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // Migration v7 → v8 : Ajout colonnes photo et idCard à employees
    if (oldVersion < 8) {
      try {
        print('🔄 Migration v7 → v8 : Ajout colonnes photo et idCard à employees...');
        
        final employeeColumns = await db.rawQuery("PRAGMA table_info(employees)");
        final hasPhoto = employeeColumns.any((col) => col['name'] == 'photo');
        final hasIdCard = employeeColumns.any((col) => col['name'] == 'idCard');
        
        if (!hasPhoto) {
          await db.execute('ALTER TABLE employees ADD COLUMN photo TEXT');
          print('✅ Colonne photo ajoutée à employees');
        }
        if (!hasIdCard) {
          await db.execute('ALTER TABLE employees ADD COLUMN idCard TEXT');
          print('✅ Colonne idCard ajoutée à employees');
        }
        
        print('✅ Migration v7 → v8 terminée avec succès !');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v7 → v8: $e');
      }
    }

    // Migration v8 → v9 : Ajout toutes les colonnes manquantes à employees
    if (oldVersion < 9) {
      try {
        print('🔄 Migration v8 → v9 : Ajout colonnes complètes à employees...');
        
        final employeeColumns = await db.rawQuery("PRAGMA table_info(employees)");
        final columnNames = employeeColumns.map((col) => col['name'] as String).toSet();
        
        // Liste des colonnes à ajouter avec leurs types et valeurs par défaut
        final columnsToAdd = {
          'photo': 'ALTER TABLE employees ADD COLUMN photo TEXT',
          'idCard': 'ALTER TABLE employees ADD COLUMN idCard TEXT',
          'contractType': 'ALTER TABLE employees ADD COLUMN contractType TEXT',
          'baseSalary': 'ALTER TABLE employees ADD COLUMN baseSalary REAL DEFAULT 0',
          'paymentFrequency': 'ALTER TABLE employees ADD COLUMN paymentFrequency TEXT DEFAULT \'monthly\'',
          'paymentMethod': 'ALTER TABLE employees ADD COLUMN paymentMethod TEXT',
          'commissionRate': 'ALTER TABLE employees ADD COLUMN commissionRate REAL',
          'bonus': 'ALTER TABLE employees ADD COLUMN bonus REAL',
          'annualLeaveDays': 'ALTER TABLE employees ADD COLUMN annualLeaveDays INTEGER DEFAULT 30',
          'usedLeaveDays': 'ALTER TABLE employees ADD COLUMN usedLeaveDays INTEGER DEFAULT 0',
          'sickLeaveDays': 'ALTER TABLE employees ADD COLUMN sickLeaveDays INTEGER DEFAULT 0',
          'totalSales': 'ALTER TABLE employees ADD COLUMN totalSales INTEGER DEFAULT 0',
          'totalRevenue': 'ALTER TABLE employees ADD COLUMN totalRevenue REAL DEFAULT 0',
          'customerRating': 'ALTER TABLE employees ADD COLUMN customerRating REAL',
          'emergencyContact': 'ALTER TABLE employees ADD COLUMN emergencyContact TEXT',
          'emergencyPhone': 'ALTER TABLE employees ADD COLUMN emergencyPhone TEXT',
        };
        
        // Ajouter chaque colonne si elle n'existe pas
        for (final entry in columnsToAdd.entries) {
          if (!columnNames.contains(entry.key)) {
            await db.execute(entry.value);
            print('✅ Colonne ${entry.key} ajoutée à employees');
          }
        }
        
        print('✅ Migration v8 → v9 terminée avec succès !');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v8 → v9: $e');
      }
    }

    // ============================================
    // MIGRATION v9 → v10 : CONVERSION COMPLÈTE VERS UUID
    // ============================================
    // Description : Convertit toutes les clés primaires et étrangères de INTEGER vers UUID (TEXT)
    // Tables concernées : users, products, orders, order_items, messages, categories
    if (oldVersion < 10) {
      try {
        print('🔄 Migration v9 → v10 : Conversion complète vers UUID...');
        print('⚠️ Cette migration va convertir toutes les clés INTEGER en UUID (TEXT)');
        
        final Uuid uuid = const Uuid();
        
        // ============================================
        // 1. MIGRATION TABLE USERS
        // ============================================
        print('📋 Étape 1/6 : Migration table users...');
        final users = await db.query('users');
        if (users.isNotEmpty) {
          // Créer table temporaire avec UUID
          await db.execute('''
            CREATE TABLE users_new (
              id TEXT PRIMARY KEY,
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
          ''');
          
          // Créer table de mapping
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_id_mapping (
              old_id INTEGER PRIMARY KEY,
              new_id TEXT NOT NULL UNIQUE
            )
          ''');
          
          // Migrer les données avec génération d'UUID
          final batch = db.batch();
          for (final user in users) {
            final newId = uuid.v4();
            batch.insert('users_new', {
              'id': newId,
              'fullName': user['fullName'],
              'phone': user['phone'],
              'email': user['email'],
              'password': user['password'],
              'role': user['role'],
              'shopName': user['shopName'],
              'city': user['city'],
              'district': user['district'],
              'branchId': user['branchId'],
              'created_at': user['created_at'],
              'updated_at': user['updated_at'],
            });
            
            batch.insert('user_id_mapping', {
              'old_id': user['id'],
              'new_id': newId,
            });
          }
          await batch.commit();
          
          // Remplacer l'ancienne table
          await db.execute('DROP TABLE users');
          await db.execute('ALTER TABLE users_new RENAME TO users');
          print('✅ Table users migrée vers UUID');
        }
        
        // ============================================
        // 2. MIGRATION TABLE PRODUCTS
        // ============================================
        print('📋 Étape 2/6 : Migration table products...');
        final products = await db.query('products');
        if (products.isNotEmpty) {
          await db.execute('''
            CREATE TABLE products_new (
              id TEXT PRIMARY KEY,
              vendorId TEXT NOT NULL,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              price REAL NOT NULL,
              description TEXT,
              images TEXT,
              stockQuantity INTEGER DEFAULT 0,
              branchId TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS product_id_mapping (
              old_id INTEGER PRIMARY KEY,
              new_id TEXT NOT NULL UNIQUE
            )
          ''');
          
          final batch = db.batch();
          for (final product in products) {
            final newId = uuid.v4();
            // Convertir vendorId INTEGER vers UUID
            final vendorIdMapping = await db.query(
              'user_id_mapping',
              where: 'old_id = ?',
              whereArgs: [product['vendorId']],
            );
            final newVendorId = vendorIdMapping.isNotEmpty 
                ? vendorIdMapping.first['new_id'] as String
                : uuid.v4(); // Fallback si mapping non trouvé
            
            batch.insert('products_new', {
              'id': newId,
              'vendorId': newVendorId,
              'name': product['name'],
              'category': product['category'],
              'price': product['price'],
              'description': product['description'],
              'images': product['images'],
              'stockQuantity': product['stockQuantity'],
              'branchId': product['branchId'],
              'created_at': product['created_at'],
              'updated_at': product['updated_at'],
            });
            
            batch.insert('product_id_mapping', {
              'old_id': product['id'],
              'new_id': newId,
            });
          }
          await batch.commit();
          
          await db.execute('DROP TABLE products');
          await db.execute('ALTER TABLE products_new RENAME TO products');
          print('✅ Table products migrée vers UUID');
        }
        
        // ============================================
        // 3. MIGRATION TABLE ORDERS
        // ============================================
        print('📋 Étape 3/6 : Migration table orders...');
        final orders = await db.query('orders');
        if (orders.isNotEmpty) {
          await db.execute('''
            CREATE TABLE orders_new (
              id TEXT PRIMARY KEY,
              clientId TEXT NOT NULL,
              totalAmount REAL NOT NULL,
              status TEXT DEFAULT 'En attente',
              date TEXT NOT NULL,
              branchId TEXT
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS order_id_mapping (
              old_id INTEGER PRIMARY KEY,
              new_id TEXT NOT NULL UNIQUE
            )
          ''');
          
          final batch = db.batch();
          for (final order in orders) {
            final newId = uuid.v4();
            // Convertir clientId INTEGER vers UUID
            final clientIdMapping = await db.query(
              'user_id_mapping',
              where: 'old_id = ?',
              whereArgs: [order['clientId']],
            );
            final newClientId = clientIdMapping.isNotEmpty 
                ? clientIdMapping.first['new_id'] as String
                : uuid.v4();
            
            batch.insert('orders_new', {
              'id': newId,
              'clientId': newClientId,
              'totalAmount': order['totalAmount'],
              'status': order['status'],
              'date': order['date'],
              'branchId': order['branchId'],
            });
            
            batch.insert('order_id_mapping', {
              'old_id': order['id'],
              'new_id': newId,
            });
          }
          await batch.commit();
          
          await db.execute('DROP TABLE orders');
          await db.execute('ALTER TABLE orders_new RENAME TO orders');
          print('✅ Table orders migrée vers UUID');
        }
        
        // ============================================
        // 4. MIGRATION TABLE ORDER_ITEMS
        // ============================================
        print('📋 Étape 4/6 : Migration table order_items...');
        final orderItems = await db.query('order_items');
        if (orderItems.isNotEmpty) {
          await db.execute('''
            CREATE TABLE order_items_new (
              id TEXT PRIMARY KEY,
              orderId TEXT NOT NULL,
              productId TEXT NOT NULL,
              productName TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              price REAL NOT NULL
            )
          ''');
          
          final batch = db.batch();
          for (final item in orderItems) {
            final newId = uuid.v4();
            // Convertir orderId et productId
            final orderIdMapping = await db.query(
              'order_id_mapping',
              where: 'old_id = ?',
              whereArgs: [item['orderId']],
            );
            final newOrderId = orderIdMapping.isNotEmpty 
                ? orderIdMapping.first['new_id'] as String
                : uuid.v4();
            
            final productIdMapping = await db.query(
              'product_id_mapping',
              where: 'old_id = ?',
              whereArgs: [item['productId']],
            );
            final newProductId = productIdMapping.isNotEmpty 
                ? productIdMapping.first['new_id'] as String
                : uuid.v4();
            
            batch.insert('order_items_new', {
              'id': newId,
              'orderId': newOrderId,
              'productId': newProductId,
              'productName': item['productName'],
              'quantity': item['quantity'],
              'price': item['price'],
            });
          }
          await batch.commit();
          
          await db.execute('DROP TABLE order_items');
          await db.execute('ALTER TABLE order_items_new RENAME TO order_items');
          print('✅ Table order_items migrée vers UUID');
        }
        
        // ============================================
        // 5. MIGRATION TABLE MESSAGES
        // ============================================
        print('📋 Étape 5/6 : Migration table messages...');
        final messages = await db.query('messages');
        if (messages.isNotEmpty) {
          await db.execute('''
            CREATE TABLE messages_new (
              id TEXT PRIMARY KEY,
              senderId TEXT,
              receiverId TEXT,
              text TEXT,
              date TEXT,
              isMe INTEGER
            )
          ''');
          
          final batch = db.batch();
          for (final message in messages) {
            final newId = uuid.v4();
            // Convertir senderId et receiverId
            String? newSenderId;
            if (message['senderId'] != null) {
              final senderMapping = await db.query(
                'user_id_mapping',
                where: 'old_id = ?',
                whereArgs: [message['senderId']],
              );
              newSenderId = senderMapping.isNotEmpty 
                  ? senderMapping.first['new_id'] as String
                  : null;
            }
            
            String? newReceiverId;
            if (message['receiverId'] != null) {
              final receiverMapping = await db.query(
                'user_id_mapping',
                where: 'old_id = ?',
                whereArgs: [message['receiverId']],
              );
              newReceiverId = receiverMapping.isNotEmpty 
                  ? receiverMapping.first['new_id'] as String
                  : null;
            }
            
            batch.insert('messages_new', {
              'id': newId,
              'senderId': newSenderId,
              'receiverId': newReceiverId,
              'text': message['text'],
              'date': message['date'],
              'isMe': message['isMe'],
            });
          }
          await batch.commit();
          
          await db.execute('DROP TABLE messages');
          await db.execute('ALTER TABLE messages_new RENAME TO messages');
          print('✅ Table messages migrée vers UUID');
        }
        
        // ============================================
        // 6. MIGRATION TABLE CATEGORIES
        // ============================================
        print('📋 Étape 6/6 : Migration table categories...');
        final categories = await db.query('categories');
        if (categories.isNotEmpty) {
          await db.execute('''
            CREATE TABLE categories_new (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL UNIQUE,
              isDefault INTEGER DEFAULT 0
            )
          ''');
          
          final batch = db.batch();
          for (final category in categories) {
            final newId = uuid.v4();
            batch.insert('categories_new', {
              'id': newId,
              'name': category['name'],
              'isDefault': category['isDefault'],
            });
          }
          await batch.commit();
          
          await db.execute('DROP TABLE categories');
          await db.execute('ALTER TABLE categories_new RENAME TO categories');
          print('✅ Table categories migrée vers UUID');
        }
        
        // ============================================
        // 7. MIGRATION TABLE BRANCHES (vendor_id INTEGER → TEXT)
        // ============================================
        print('📋 Étape 7/8 : Migration table branches (vendor_id)...');
        final branchesColumns = await db.rawQuery("PRAGMA table_info(branches)");
        final vendorIdColumn = branchesColumns.firstWhere(
          (col) => col['name'] == 'vendor_id',
          orElse: () => {},
        );
        
        if (vendorIdColumn.isNotEmpty && vendorIdColumn['type'] == 'INTEGER') {
          // La colonne existe et est INTEGER, il faut la convertir
          final branches = await db.query('branches');
          if (branches.isNotEmpty) {
            await db.execute('''
              CREATE TABLE branches_new (
                id TEXT PRIMARY KEY,
                vendor_id TEXT NOT NULL,
                name TEXT NOT NULL,
                code TEXT NOT NULL UNIQUE,
                country TEXT NOT NULL,
                city TEXT NOT NULL,
                district TEXT NOT NULL,
                address TEXT,
                latitude REAL,
                longitude REAL,
                phone TEXT,
                email TEXT,
                manager_id TEXT,
                is_active INTEGER DEFAULT 1,
                opening_date TEXT NOT NULL,
                closing_date TEXT,
                opening_hours TEXT DEFAULT '{}',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            
            final batch = db.batch();
            for (final branch in branches) {
              // Convertir vendor_id INTEGER vers UUID
              final vendorIdMapping = await db.query(
                'user_id_mapping',
                where: 'old_id = ?',
                whereArgs: [branch['vendor_id']],
              );
              final newVendorId = vendorIdMapping.isNotEmpty 
                  ? vendorIdMapping.first['new_id'] as String
                  : uuid.v4();
              
              batch.insert('branches_new', {
                'id': branch['id'],
                'vendor_id': newVendorId,
                'name': branch['name'],
                'code': branch['code'],
                'country': branch['country'],
                'city': branch['city'],
                'district': branch['district'],
                'address': branch['address'],
                'latitude': branch['latitude'],
                'longitude': branch['longitude'],
                'phone': branch['phone'],
                'email': branch['email'],
                'manager_id': branch['manager_id'],
                'is_active': branch['is_active'],
                'opening_date': branch['opening_date'],
                'closing_date': branch['closing_date'],
                'opening_hours': branch['opening_hours'],
                'created_at': branch['created_at'],
                'updated_at': branch['updated_at'],
              });
            }
            await batch.commit();
            
            await db.execute('DROP TABLE branches');
            await db.execute('ALTER TABLE branches_new RENAME TO branches');
            print('✅ Table branches migrée (vendor_id vers UUID)');
          }
        } else {
          print('ℹ️ Table branches déjà avec vendor_id TEXT ou table vide');
        }
        
        // ============================================
        // 8. MIGRATION TABLE EMPLOYEES (vendorId INTEGER → TEXT)
        // ============================================
        print('📋 Étape 8/8 : Migration table employees (vendorId)...');
        final employeesColumns = await db.rawQuery("PRAGMA table_info(employees)");
        final vendorIdCol = employeesColumns.firstWhere(
          (col) => col['name'] == 'vendorId',
          orElse: () => {},
        );
        
        if (vendorIdCol.isNotEmpty && vendorIdCol['type'] == 'INTEGER') {
          // La colonne existe et est INTEGER, il faut la convertir
          final employees = await db.query('employees');
          if (employees.isNotEmpty) {
            // Créer la nouvelle table avec vendorId TEXT
            await db.execute('''
              CREATE TABLE employees_new (
                id TEXT PRIMARY KEY,
                branchId TEXT NOT NULL,
                vendorId TEXT NOT NULL,
                firstName TEXT NOT NULL,
                lastName TEXT NOT NULL,
                phone TEXT NOT NULL,
                email TEXT,
                photo TEXT,
                idCard TEXT,
                role TEXT NOT NULL,
                role_id TEXT,
                department_code TEXT,
                contractType TEXT,
                contract_type TEXT,
                permissions TEXT DEFAULT '[]',
                baseSalary REAL DEFAULT 0,
                salary REAL,
                paymentFrequency TEXT DEFAULT 'monthly',
                paymentMethod TEXT,
                commissionRate REAL,
                bonus REAL,
                annualLeaveDays INTEGER DEFAULT 30,
                usedLeaveDays INTEGER DEFAULT 0,
                sickLeaveDays INTEGER DEFAULT 0,
                totalSales INTEGER DEFAULT 0,
                totalRevenue REAL DEFAULT 0,
                customerRating REAL,
                isActive INTEGER DEFAULT 1,
                is_deleted INTEGER DEFAULT 0,
                hireDate TEXT NOT NULL,
                terminationDate TEXT,
                emergencyContact TEXT,
                emergency_contact TEXT,
                emergencyPhone TEXT,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL
              )
            ''');
            
            final batch = db.batch();
            for (final employee in employees) {
              // Convertir vendorId INTEGER vers UUID
              final vendorIdMapping = await db.query(
                'user_id_mapping',
                where: 'old_id = ?',
                whereArgs: [employee['vendorId']],
              );
              final newVendorId = vendorIdMapping.isNotEmpty 
                  ? vendorIdMapping.first['new_id'] as String
                  : uuid.v4();
              
              // Copier toutes les colonnes existantes
              final newEmployee = Map<String, dynamic>.from(employee);
              newEmployee['vendorId'] = newVendorId;
              
              batch.insert('employees_new', newEmployee);
            }
            await batch.commit();
            
            await db.execute('DROP TABLE employees');
            await db.execute('ALTER TABLE employees_new RENAME TO employees');
            print('✅ Table employees migrée (vendorId vers UUID)');
          }
        } else {
          print('ℹ️ Table employees déjà avec vendorId TEXT ou table vide');
        }
        
        // ============================================
        // NETTOYAGE DES TABLES DE MAPPING
        // ============================================
        await db.execute('DROP TABLE IF EXISTS user_id_mapping');
        await db.execute('DROP TABLE IF EXISTS product_id_mapping');
        await db.execute('DROP TABLE IF EXISTS order_id_mapping');
        
        print('✅ Migration v9 → v10 terminée avec succès !');
        print('ℹ️ Toutes les tables utilisent maintenant UUID (TEXT) comme clé primaire');
      } catch (e) {
        print('❌ Erreur lors de la migration v9 → v10: $e');
        print('⚠️ Stack trace: ${StackTrace.current}');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // ============================================
    // MIGRATION v10 → v11 : AJOUT CHAMP access_code
    // ============================================
    // Description : Ajoute le champ access_code (4 chiffres) pour l'authentification des employés
    // Ce code est unique et généré automatiquement lors de la création d'un employé
    if (oldVersion < 11) {
      try {
        print('🔄 Migration v10 → v11 : Ajout champ access_code à employees...');
        
        // Vérifier si la colonne existe déjà
        final employeeColumns = await db.rawQuery("PRAGMA table_info(employees)");
        final hasAccessCode = employeeColumns.any((col) => col['name'] == 'access_code');
        
        if (!hasAccessCode) {
          // Ajouter la colonne access_code avec contrainte UNIQUE
          await db.execute('ALTER TABLE employees ADD COLUMN access_code TEXT UNIQUE');
          print('✅ Colonne access_code ajoutée à la table employees');
          
          // Créer un index pour optimiser les recherches par code
          await db.execute('CREATE INDEX IF NOT EXISTS idx_employees_access_code ON employees(access_code)');
          print('✅ Index créé sur access_code');
        } else {
          print('ℹ️ Colonne access_code existe déjà');
        }
        
        print('✅ Migration v10 → v11 terminée avec succès !');
        print('ℹ️ Le champ access_code est maintenant disponible pour l\'authentification des employés');
      } catch (e) {
        print('❌ Erreur lors de la migration v10 → v11: $e');
        print('⚠️ Stack trace: ${StackTrace.current}');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // Migration v11 → v12 : Ajout department_code à la table roles
    if (oldVersion < 12) {
      try {
        print('🔄 Migration v11 → v12 : Ajout champ department_code à roles...');
        
        // Vérifier si la colonne existe déjà
        final roleColumns = await db.rawQuery("PRAGMA table_info(roles)");
        final hasDepartmentCode = roleColumns.any((col) => col['name'] == 'department_code');
        
        if (!hasDepartmentCode) {
          // Ajouter la colonne department_code
          await db.execute('ALTER TABLE roles ADD COLUMN department_code TEXT');
          print('✅ Colonne department_code ajoutée à la table roles');
        } else {
          print('ℹ️ Colonne department_code existe déjà');
        }
        
        print('✅ Migration v11 → v12 terminée avec succès !');
        print('ℹ️ Le champ department_code est maintenant disponible pour la génération automatique');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v11 → v12: $e');
        print('⚠️ Stack trace: ${StackTrace.current}');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // ============================================
    // MIGRATION v12 → v13 : TABLES MARKETING EXPENSES ET BUDGETS
    // ============================================
    if (oldVersion < 13) {
      try {
        print('🔄 Migration v12 → v13 : Ajout tables marketing_expenses et marketing_budgets...');
        
        // Table dépenses marketing
        const marketingExpensesTable = '''
        CREATE TABLE IF NOT EXISTS marketing_expenses (
          id TEXT PRIMARY KEY,
          branch_id TEXT NOT NULL,
          category TEXT NOT NULL,
          activity TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          expense_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (branch_id) REFERENCES branches (id)
        )
        ''';

        // Table budgets marketing
        const marketingBudgetsTable = '''
        CREATE TABLE IF NOT EXISTS marketing_budgets (
          id TEXT PRIMARY KEY,
          branch_id TEXT NOT NULL,
          category TEXT NOT NULL,
          budget_amount REAL NOT NULL,
          period_type TEXT NOT NULL,
          period_start TEXT NOT NULL,
          period_end TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (branch_id) REFERENCES branches (id)
        )
        ''';

        await db.execute(marketingExpensesTable);
        await db.execute(marketingBudgetsTable);
        
        // Créer les index pour optimiser les requêtes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_marketing_expenses_branch ON marketing_expenses(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_marketing_expenses_date ON marketing_expenses(expense_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_marketing_expenses_category ON marketing_expenses(category)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_marketing_budgets_branch ON marketing_budgets(branch_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_marketing_budgets_period ON marketing_budgets(period_start, period_end)');
        
        print('✅ Migration v12 → v13 terminée avec succès !');
        print('ℹ️ Les tables marketing_expenses et marketing_budgets sont maintenant disponibles');
      } catch (e) {
        print('⚠️ Erreur lors de la migration v12 → v13: $e');
        print('⚠️ Stack trace: ${StackTrace.current}');
        // Ne pas relancer l'erreur pour éviter de bloquer l'app
      }
    }

    // ============================================
    // VÉRIFICATION DYNAMIQUE FINALE
    // ============================================
    // Toujours vérifier que toutes les tables/colonnes existent
    // Cela permet d'ajouter de nouvelles fonctionnalités sans incrémenter la version
    // Note: _ensureAllTablesAndColumns est aussi appelé dans le getter database
    // pour garantir qu'il s'exécute même si la version n'a pas changé
    await _ensureAllTablesAndColumns(db);
  }

  Future _createDB(Database db, int version) async {
    const userTable = '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      fullName TEXT NOT NULL,
      phone TEXT NOT NULL UNIQUE,
      email TEXT,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      shopName TEXT,
      city TEXT,
      district TEXT,
      branchId TEXT, 
      is_deleted INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''';

    const productTable = '''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      vendorId TEXT NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      description TEXT,
      images TEXT,
      stockQuantity INTEGER DEFAULT 0,
      branchId TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (vendorId) REFERENCES users (id)
    )
    ''';

    const orderTable = '''
    CREATE TABLE orders (
      id TEXT PRIMARY KEY,
      clientId TEXT NOT NULL,
      totalAmount REAL NOT NULL,
      status TEXT DEFAULT 'En attente',
      date TEXT NOT NULL,
      branchId TEXT,
      FOREIGN KEY (clientId) REFERENCES users (id)
    )
    ''';

    const orderItemsTable = '''
    CREATE TABLE order_items (
      id TEXT PRIMARY KEY,
      orderId TEXT NOT NULL,
      productId TEXT NOT NULL,
      productName TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      FOREIGN KEY (orderId) REFERENCES orders (id),
      FOREIGN KEY (productId) REFERENCES products (id)
    )
    ''';

    const messageTable = '''
    CREATE TABLE messages (
      id TEXT PRIMARY KEY,
      senderId TEXT,
      receiverId TEXT,
      text TEXT,
      date TEXT,
      isMe INTEGER
    )
    ''';

    const categoryTable = '''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      isDefault INTEGER DEFAULT 0
    )
    ''';

    // ============================================
    // TABLE : branches (Succursales)
    // ============================================
    // Description : Stocke les informations de base des succursales
    // Note : Les informations financières (loyer, charges) seront gérées
    //        dans la table branch_transactions (Phase 3 - Comptabilité)
    // Convention : Utilisation de snake_case pour les noms de colonnes SQL
    const branchTable = '''
    CREATE TABLE branches (
      id TEXT PRIMARY KEY,
      vendor_id TEXT NOT NULL,
      name TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      country TEXT NOT NULL,
      city TEXT NOT NULL,
      district TEXT NOT NULL,
      address TEXT,
      latitude REAL,
      longitude REAL,
      phone TEXT,
      email TEXT,
      manager_id TEXT,
      is_active INTEGER DEFAULT 1,
      opening_date TEXT NOT NULL,
      closing_date TEXT,
      opening_hours TEXT DEFAULT '{}',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (vendor_id) REFERENCES users (id)
    )
    ''';

    const employeeTable = '''
    CREATE TABLE employees (
      id TEXT PRIMARY KEY,
      branchId TEXT NOT NULL,
      vendorId TEXT NOT NULL,
      firstName TEXT NOT NULL,
      lastName TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      photo TEXT,
      idCard TEXT,
      role TEXT NOT NULL,
      role_id TEXT,
      department_code TEXT,
      access_code TEXT UNIQUE,
      contractType TEXT,
      contract_type TEXT,
      permissions TEXT DEFAULT '[]',
      baseSalary REAL DEFAULT 0,
      salary REAL,
      paymentFrequency TEXT DEFAULT 'monthly',
      paymentMethod TEXT,
      commissionRate REAL,
      bonus REAL,
      annualLeaveDays INTEGER DEFAULT 30,
      usedLeaveDays INTEGER DEFAULT 0,
      sickLeaveDays INTEGER DEFAULT 0,
      totalSales INTEGER DEFAULT 0,
      totalRevenue REAL DEFAULT 0,
      customerRating REAL,
      isActive INTEGER DEFAULT 1,
      is_deleted INTEGER DEFAULT 0,
      hireDate TEXT NOT NULL,
      terminationDate TEXT,
      emergencyContact TEXT,
      emergency_contact TEXT,
      emergencyPhone TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (branchId) REFERENCES branches (id),
      FOREIGN KEY (vendorId) REFERENCES users (id),
      FOREIGN KEY (role_id) REFERENCES roles (id)
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

    // ============================================
    // PHASE 3 : TABLES COMPTABILITÉ
    // ============================================
    
    // Table transactions financières
    const branchTransactionsTable = '''
    CREATE TABLE branch_transactions (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      attachment TEXT,
      created_by TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (branch_id) REFERENCES branches (id)
    )
    ''';

    // Table coûts récurrents
    const branchRecurringCostsTable = '''
    CREATE TABLE branch_recurring_costs (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      frequency TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT,
      is_active INTEGER DEFAULT 1,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (branch_id) REFERENCES branches (id)
    )
    ''';

    await db.execute(branchTransactionsTable);
    await db.execute(branchRecurringCostsTable);

    // ============================================
    // PHASE MARKETING : TABLES DÉPENSES MARKETING
    // ============================================
    
    // Table dépenses marketing
    const marketingExpensesTable = '''
    CREATE TABLE marketing_expenses (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      category TEXT NOT NULL,
      activity TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      expense_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (branch_id) REFERENCES branches (id)
    )
    ''';

    // Table budgets marketing
    const marketingBudgetsTable = '''
    CREATE TABLE marketing_budgets (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      category TEXT NOT NULL,
      budget_amount REAL NOT NULL,
      period_type TEXT NOT NULL,
      period_start TEXT NOT NULL,
      period_end TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (branch_id) REFERENCES branches (id)
    )
    ''';

    await db.execute(marketingExpensesTable);
    await db.execute(marketingBudgetsTable);

    // ============================================
    // CRÉATION DES INDEX POUR OPTIMISATION DES PERFORMANCES
    // ============================================
    // Les index accélèrent les recherches et jointures fréquentes
    await db.execute('CREATE INDEX idx_products_branch ON products(branchId)');
    await db.execute('CREATE INDEX idx_orders_branch ON orders(branchId)');
    await db.execute('CREATE INDEX idx_branches_vendor ON branches(vendor_id)');
    await db.execute('CREATE INDEX idx_employees_branch ON employees(branchId)');
    //POUR RH
    await db.execute('CREATE INDEX idx_attendance_employee ON employee_attendance(employeeId)');
    await db.execute('CREATE INDEX idx_attendance_branch ON employee_attendance(branchId)');
    await db.execute('CREATE INDEX idx_attendance_date ON employee_attendance(date)');
    //POUR MARKETING
    await db.execute('CREATE INDEX idx_marketing_expenses_branch ON marketing_expenses(branch_id)');
    await db.execute('CREATE INDEX idx_marketing_expenses_date ON marketing_expenses(expense_date)');
    await db.execute('CREATE INDEX idx_marketing_expenses_category ON marketing_expenses(category)');
    await db.execute('CREATE INDEX idx_marketing_budgets_branch ON marketing_budgets(branch_id)');
    await db.execute('CREATE INDEX idx_marketing_budgets_period ON marketing_budgets(period_start, period_end)');
    await db.execute('CREATE INDEX idx_payroll_employee ON employee_payroll(employeeId)');
    await db.execute('CREATE INDEX idx_payroll_period ON employee_payroll(periodStart)');
    await db.execute('CREATE INDEX idx_leave_employee ON leave_requests(employeeId)');
    await db.execute('CREATE INDEX idx_performance_employee ON employee_performance(employeeId)');
    await db.execute('CREATE INDEX idx_performance_month ON employee_performance(month)');
    
    // Index pour tables comptabilité (Phase 3)
    await db.execute('CREATE INDEX idx_transactions_branch ON branch_transactions(branch_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON branch_transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_type ON branch_transactions(type)');
    await db.execute('CREATE INDEX idx_recurring_costs_branch ON branch_recurring_costs(branch_id)');
    await db.execute('CREATE INDEX idx_recurring_costs_active ON branch_recurring_costs(is_active)');
    
    // Ajouter is_deleted à branch_transactions dans la création initiale
    await db.execute('ALTER TABLE branch_transactions ADD COLUMN is_deleted INTEGER DEFAULT 0');
    await db.execute('CREATE INDEX idx_transactions_deleted ON branch_transactions(is_deleted)');

    // ============================================
    // PHASE 4 : TABLES GESTION EMPLOYÉS ET RÔLES
    // ============================================
    
    // Table roles
    const rolesTable = '''
    CREATE TABLE roles (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      name TEXT NOT NULL,
      department TEXT NOT NULL,
      department_code TEXT,
      permissions TEXT,
      created_by TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      FOREIGN KEY (branch_id) REFERENCES branches (id)
    )
    ''';
    
    // Table permission_requests
    const permissionRequestsTable = '''
    CREATE TABLE permission_requests (
      id TEXT PRIMARY KEY,
      branch_id TEXT NOT NULL,
      employee_id TEXT NOT NULL,
      transaction_id TEXT,
      request_type TEXT NOT NULL,
      reason TEXT NOT NULL,
      status TEXT DEFAULT 'PENDING',
      reviewed_by TEXT,
      reviewed_at TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (branch_id) REFERENCES branches (id),
      FOREIGN KEY (employee_id) REFERENCES employees (id)
    )
    ''';
    
    await db.execute(rolesTable);
    await db.execute(permissionRequestsTable);
    
    // Créer les index pour optimiser les performances
    await db.execute('CREATE INDEX idx_roles_branch ON roles(branch_id)');
    await db.execute('CREATE INDEX idx_roles_department ON roles(department)');
    await db.execute('CREATE INDEX idx_permission_requests_branch ON permission_requests(branch_id)');
    await db.execute('CREATE INDEX idx_permission_requests_status ON permission_requests(status)');
    await db.execute('CREATE INDEX idx_permission_requests_employee ON permission_requests(employee_id)');

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
  Future<String> createUser(UserModel user) async {
    final db = await instance.database;
    final Uuid uuid = const Uuid();
    
    // Générer un UUID si l'utilisateur n'en a pas
    final userMap = user.toMap();
    if (userMap['id'] == null) {
      userMap['id'] = uuid.v4();
    }
    
    await db.insert('users', userMap);
    return userMap['id'] as String;
  }

  Future<UserModel?> loginUser(String phone, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'phone = ? AND password = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      whereArgs: [phone, password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<VendorInfoModel?> getVendorInfo(String vendorId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'id = ? AND role IN (?, ?)',
      whereArgs: [vendorId, 'vendor', 'vendeur'],
    );

    if (result.isEmpty) return null;
    return VendorInfoModel.fromMap(result.first);
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'phone = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      whereArgs: [phone],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
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
    WHERE u.role IN ('vendor', 'vendeur')
    ORDER BY p.id DESC
  ''');

    print('📊 Requête SQL retournée: ${result.length} lignes');

    if (result.isEmpty) {
      print('⚠️ AUCUN PRODUIT DANS LA BASE DE DONNÉES');

      final productsCount = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final vendorsCount = await db.rawQuery("SELECT COUNT(*) as count FROM users WHERE role IN ('vendor', 'vendeur')");

      print('📦 Produits dans la table: ${productsCount.first['count']}');
      print('👤 Vendeurs dans la table: ${vendorsCount.first['count']}');

      return [];
    }

    return result.map((map) {
      // Vérifier que l'ID du produit existe
      final productId = map['id'] as String?;
      if (productId == null || productId.isEmpty) {
        print('⚠️ ATTENTION: Produit "${map['name']}" n\'a pas d\'ID !');
        print('   Données: $map');
      }
      
      final productMap = {
        'id': productId,
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

      print('✅ Produit: ${map['name']} | ID: $productId | Vendeur: ${map['vendor_name']}');

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

    final vendors = await db.query('users', where: "role IN ('vendor', 'vendeur')");
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
  Future<List<MessageModel>> getMessages(String userId, String otherId) async {
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
  Future<void> createOrder(String clientId, double total,
      List<Map<String, dynamic>> items) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final Uuid uuid = const Uuid();
      final orderId = uuid.v4();
      
      await txn.insert('orders', {
        'id': orderId,
        'clientId': clientId,
        'totalAmount': total,
        'status': 'En attente',
        'date': DateTime.now().toIso8601String(),
      });

      for (var item in items) {
        final itemId = uuid.v4();
        await txn.insert('order_items', {
          'id': itemId,
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

  Future<List<OrderModel>> getVendorOrders(String vendorId) async {
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
      String orderId = map['id'] as String;

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

  Future<int> updateOrderStatus(String orderId, String newStatus) async {
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
  Future<List<ClientStatsModel>> getVendorClients(String vendorId) async {
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

  // ============================================
  // RÉCUPÉRER TOUTES LES SUCCURSALES D'UN VENDEUR
  // ============================================
  // Paramètres :
  //   - vendorId : ID du vendeur propriétaire
  // Retour : Liste des succursales triées par date de création (plus récentes en premier)
  Future<List<Map<String, dynamic>>> getBranchesByVendor(String vendorId) async {
    final db = await database;
    return await db.query(
      'branches',
      where: 'vendor_id = ?',
      whereArgs: [vendorId],
      orderBy: 'created_at DESC',
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
    try {
      final db = await database;
      await db.insert('employees', employee);
      print('✅ Employé créé avec succès: ${employee['id']}');
      return employee['id'] as String;
    } catch (e) {
      print('❌ Erreur lors de la création de l\'employé: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeesByBranch(String branchId) async {
    try {
      final db = await database;
      // Charger tous les employés (actifs et inactifs) sauf ceux supprimés
      final result = await db.query(
        'employees',
        where: 'branchId = ? AND is_deleted = 0',
        whereArgs: [branchId],
        orderBy: 'isActive DESC, createdAt DESC', // Actifs en premier
      );
      print('📋 ${result.length} employé(s) trouvé(s) pour la succursale $branchId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des employés par succursale: $e');
      return [];
    }
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
    try {
      final db = await database;
      final results = await db.query(
        'employees',
        where: 'id = ? AND is_deleted = 0',
        whereArgs: [employeeId],
        limit: 1,
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'employé: $e');
      return null;
    }
  }

  Future<int> updateEmployee(String employeeId, Map<String, dynamic> employee) async {
    try {
      final db = await database;
      employee['updatedAt'] = DateTime.now().toIso8601String();
      final result = await db.update(
        'employees',
        employee,
        where: 'id = ?',
        whereArgs: [employeeId],
      );
      print('✅ Employé mis à jour avec succès: $employeeId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de l\'employé: $e');
      rethrow;
    }
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

  // ============================================
  // PHASE 3 : GESTION DES TRANSACTIONS FINANCIÈRES
  // ============================================

  /// Insérer une nouvelle transaction
  Future<String> insertBranchTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('branch_transactions', transaction);
    return transaction['id'] as String;
  }

  /// Récupérer toutes les transactions d'une succursale
  Future<List<Map<String, dynamic>>> getBranchTransactions(String branchId) async {
    final db = await database;
    return await db.query(
      'branch_transactions',
      where: 'branch_id = ?',
      whereArgs: [branchId],
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Récupérer les transactions avec filtres
  Future<List<Map<String, dynamic>>> getBranchTransactionsFiltered({
    required String branchId,
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'branch_id = ?';
    List<dynamic> whereArgs = [branchId];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'branch_transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );
  }

  /// Récupérer une transaction par ID
  Future<Map<String, dynamic>?> getBranchTransaction(String transactionId) async {
    final db = await database;
    final results = await db.query(
      'branch_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Mettre à jour une transaction
  Future<int> updateBranchTransaction(String transactionId, Map<String, dynamic> transaction) async {
    final db = await database;
    transaction['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'branch_transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Supprimer une transaction
  Future<int> deleteBranchTransaction(String transactionId) async {
    final db = await database;
    return await db.delete(
      'branch_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Calculer le total des entrées pour une période
  Future<double> getTotalEntries(String branchId, DateTime? startDate, DateTime? endDate) async {
    final db = await database;
    String whereClause = 'branch_id = ? AND type = ?';
    List<dynamic> whereArgs = [branchId, 'ENTRY'];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM branch_transactions WHERE $whereClause',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Calculer le total des sorties pour une période
  Future<double> getTotalExits(String branchId, DateTime? startDate, DateTime? endDate) async {
    final db = await database;
    String whereClause = 'branch_id = ? AND type = ?';
    List<dynamic> whereArgs = [branchId, 'EXIT'];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM branch_transactions WHERE $whereClause',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Calculer le total des dépenses pour une période
  Future<double> getTotalExpenses(String branchId, DateTime? startDate, DateTime? endDate) async {
    final db = await database;
    String whereClause = 'branch_id = ? AND type = ?';
    List<dynamic> whereArgs = [branchId, 'EXPENSE'];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM branch_transactions WHERE $whereClause',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ============================================
  // PHASE 3 : GESTION DES COÛTS RÉCURRENTS
  // ============================================

  /// Insérer un nouveau coût récurrent
  Future<String> insertBranchRecurringCost(Map<String, dynamic> cost) async {
    final db = await database;
    await db.insert('branch_recurring_costs', cost);
    return cost['id'] as String;
  }

  /// Récupérer tous les coûts récurrents d'une succursale
  Future<List<Map<String, dynamic>>> getBranchRecurringCosts(String branchId) async {
    final db = await database;
    return await db.query(
      'branch_recurring_costs',
      where: 'branch_id = ?',
      whereArgs: [branchId],
      orderBy: 'created_at DESC',
    );
  }

  /// Récupérer les coûts récurrents actifs
  Future<List<Map<String, dynamic>>> getActiveRecurringCosts(String branchId) async {
    final db = await database;
    return await db.query(
      'branch_recurring_costs',
      where: 'branch_id = ? AND is_active = 1',
      whereArgs: [branchId],
      orderBy: 'created_at DESC',
    );
  }

  /// Récupérer un coût récurrent par ID
  Future<Map<String, dynamic>?> getBranchRecurringCost(String costId) async {
    final db = await database;
    final results = await db.query(
      'branch_recurring_costs',
      where: 'id = ?',
      whereArgs: [costId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Mettre à jour un coût récurrent
  Future<int> updateBranchRecurringCost(String costId, Map<String, dynamic> cost) async {
    final db = await database;
    cost['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'branch_recurring_costs',
      cost,
      where: 'id = ?',
      whereArgs: [costId],
    );
  }

  /// Supprimer un coût récurrent
  Future<int> deleteBranchRecurringCost(String costId) async {
    final db = await database;
    return await db.delete(
      'branch_recurring_costs',
      where: 'id = ?',
      whereArgs: [costId],
    );
  }

  /// ============================================
  // PHASE 3 : MÉTHODES UTILITAIRES POUR FILTRES
  // ============================================

  /// Obtenir toutes les années disponibles dans les transactions d'une succursale
  /// Note : Les dates sont stockées au format ISO8601 (ex: 2025-12-15T10:30:00.000)
  /// SQLite peut parser ce format avec datetime() puis strftime
  Future<List<int>> getAvailableYears(String branchId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y', datetime(date)) as year
      FROM branch_transactions
      WHERE branch_id = ?
      ORDER BY year DESC
    ''', [branchId]);
    
    return result.map((row) => int.parse(row['year'] as String)).toList();
  }

  /// Obtenir tous les mois disponibles pour une année donnée
  /// Note : Les dates sont stockées au format ISO8601 (ex: 2025-12-15T10:30:00.000)
  /// SQLite peut parser ce format avec datetime() puis strftime
  Future<List<Map<String, dynamic>>> getAvailableMonths(String branchId, int year) async {
    final db = await database;
    // Utiliser datetime() pour convertir ISO8601 en date SQLite, puis strftime pour extraire l'année et le mois
    // ORDER BY month ASC pour avoir les mois dans l'ordre chronologique (janvier, février, etc.)
    final result = await db.rawQuery('''
      SELECT DISTINCT 
        CAST(strftime('%m', datetime(date)) AS INTEGER) as month,
        strftime('%Y-%m', datetime(date)) as year_month
      FROM branch_transactions
      WHERE branch_id = ? AND strftime('%Y', datetime(date)) = ?
      ORDER BY month ASC
    ''', [branchId, year.toString()]);
    
    final months = result.map((row) => {
      'month': row['month'] as int,
      'year_month': row['year_month'] as String,
    }).toList();
    
    // Debug : afficher les mois trouvés
    print('📅 Mois disponibles pour l\'année $year (succursale $branchId): ${months.map((m) => m['year_month']).join(', ')}');
    
    return months;
  }

  // ============================================
  // PHASE 4 : GESTION DES RÔLES
  // ============================================

  /// Insérer un nouveau rôle
  Future<String> insertRole(Map<String, dynamic> role) async {
    try {
      final db = await database;
      await db.insert('roles', role);
      print('✅ Rôle créé avec succès : ${role['name']}');
      return role['id'] as String;
    } catch (e) {
      print('❌ Erreur lors de la création du rôle: $e');
      rethrow;
    }
  }

  /// Récupérer tous les rôles d'une succursale
  Future<List<Map<String, dynamic>>> getRoles(String branchId) async {
    try {
      final db = await database;
      final result = await db.query(
        'roles',
        where: 'branch_id = ? AND is_active = 1',
        whereArgs: [branchId],
        orderBy: 'created_at DESC',
      );
      print('📋 ${result.length} rôle(s) trouvé(s) pour la succursale $branchId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des rôles: $e');
      return [];
    }
  }

  /// Récupérer un rôle par ID
  Future<Map<String, dynamic>?> getRole(String roleId) async {
    try {
      final db = await database;
      final result = await db.query(
        'roles',
        where: 'id = ?',
        whereArgs: [roleId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  /// Récupérer les rôles par département
  Future<List<Map<String, dynamic>>> getRolesByDepartment(String branchId, String department) async {
    try {
      final db = await database;
      final result = await db.query(
        'roles',
        where: 'branch_id = ? AND department = ? AND is_active = 1',
        whereArgs: [branchId, department],
        orderBy: 'created_at DESC',
      );
      print('📋 ${result.length} rôle(s) trouvé(s) pour le département $department');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des rôles par département: $e');
      return [];
    }
  }

  /// Mettre à jour un rôle
  Future<int> updateRole(String roleId, Map<String, dynamic> role) async {
    try {
      final db = await database;
      role['updated_at'] = DateTime.now().toIso8601String();
      final result = await db.update(
        'roles',
        role,
        where: 'id = ?',
        whereArgs: [roleId],
      );
      print('✅ Rôle mis à jour avec succès : $roleId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du rôle: $e');
      rethrow;
    }
  }

  /// Désactiver un rôle (soft delete)
  Future<int> deactivateRole(String roleId) async {
    try {
      final db = await database;
      final result = await db.update(
        'roles',
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [roleId],
      );
      print('✅ Rôle désactivé avec succès : $roleId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la désactivation du rôle: $e');
      rethrow;
    }
  }

  // ============================================
  // PHASE 4 : GESTION DES DEMANDES DE PERMISSION
  // ============================================

  /// Insérer une nouvelle demande de permission
  Future<String> insertPermissionRequest(Map<String, dynamic> request) async {
    try {
      final db = await database;
      await db.insert('permission_requests', request);
      print('✅ Demande de permission créée avec succès : ${request['id']}');
      return request['id'] as String;
    } catch (e) {
      print('❌ Erreur lors de la création de la demande de permission: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les demandes de permission d'une succursale
  Future<List<Map<String, dynamic>>> getPermissionRequests(String branchId) async {
    try {
      final db = await database;
      final result = await db.query(
        'permission_requests',
        where: 'branch_id = ?',
        whereArgs: [branchId],
        orderBy: 'created_at DESC',
      );
      print('📋 ${result.length} demande(s) de permission trouvée(s) pour la succursale $branchId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des demandes de permission: $e');
      return [];
    }
  }

  /// Récupérer les demandes de permission en attente
  Future<List<Map<String, dynamic>>> getPendingPermissionRequests(String branchId) async {
    try {
      final db = await database;
      final result = await db.query(
        'permission_requests',
        where: 'branch_id = ? AND status = ?',
        whereArgs: [branchId, 'PENDING'],
        orderBy: 'created_at DESC',
      );
      print('📋 ${result.length} demande(s) en attente trouvée(s)');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des demandes en attente: $e');
      return [];
    }
  }

  /// Récupérer une demande de permission par ID
  Future<Map<String, dynamic>?> getPermissionRequest(String requestId) async {
    try {
      final db = await database;
      final result = await db.query(
        'permission_requests',
        where: 'id = ?',
        whereArgs: [requestId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la demande de permission: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'une demande de permission
  Future<int> updatePermissionRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
  }) async {
    try {
      final db = await database;
      final result = await db.update(
        'permission_requests',
        {
          'status': status,
          'reviewed_by': reviewedBy,
          'reviewed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
      print('✅ Demande de permission $status avec succès : $requestId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut de la demande: $e');
      rethrow;
    }
  }

  // ============================================
  // PHASE 4 : GESTION DES EMPLOYÉS (MÉTHODES COMPLÉMENTAIRES)
  // ============================================


  /// Vérifier si un code d'accès existe pour un département
  /// ============================================
  /// VÉRIFIER LE CODE D'ACCÈS PAR DÉPARTEMENT
  /// ============================================
  /// Vérifie directement depuis le rôle (roles.department_code) au lieu de copier dans l'employé
  /// Option B : Source unique de vérité dans la table roles
  Future<bool> verifyDepartmentCode(String branchId, String department, String code) async {
    try {
      final db = await database;
      // Vérifier directement depuis le rôle via la jointure avec l'employé
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM employees e
        JOIN roles r ON e.role_id = r.id
        WHERE e.branchId = ? 
          AND r.department = ?
          AND r.department_code = ?
          AND e.is_deleted = 0
          AND e.isActive = 1
          AND r.is_active = 1
      ''', [branchId, department, code]);
      
      final count = result.first['count'] as int? ?? 0;
      final isValid = count > 0;
      print('🔐 Vérification code département $department: ${isValid ? "✅ Valide" : "❌ Invalide"} (vérifié depuis rôle)');
      return isValid;
    } catch (e) {
      print('❌ Erreur lors de la vérification du code: $e');
      return false;
    }
  }

  /// Vérifier si un employé est admin d'une succursale
  /// Un utilisateur est admin s'il est le créateur de la succursale (vendor_id)
  Future<bool> isAdmin(String branchId, String userId) async {
    try {
      final db = await database;
      // Vérifier si l'utilisateur est le créateur de la succursale (vendor_id)
      final branchResult = await db.query(
        'branches',
        columns: ['vendor_id'],
        where: 'id = ?',
        whereArgs: [branchId],
        limit: 1,
      );
      
      if (branchResult.isNotEmpty) {
        final vendorId = branchResult.first['vendor_id'];
        // Convertir les deux en String pour comparaison fiable
        final vendorIdStr = vendorId.toString();
        final userIdStr = userId.toString();
        final isCreator = vendorIdStr == userIdStr;
        
        print('👤 Vérification admin pour succursale $branchId');
        print('   userId: $userIdStr (type: ${userId.runtimeType})');
        print('   vendorId: $vendorIdStr (type: ${vendorId.runtimeType})');
        print('   Résultat: ${isCreator ? "✅ Admin" : "❌ Non admin"}');
        
        return isCreator;
      }
      
      print('⚠️ Succursale $branchId non trouvée');
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification admin: $e');
      print('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Soft delete d'une transaction
  Future<int> softDeleteTransaction(String transactionId) async {
    try {
      final db = await database;
      final result = await db.update(
        'branch_transactions',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      print('✅ Transaction supprimée (soft delete) : $transactionId');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la suppression de la transaction: $e');
      rethrow;
    }
  }

  // ============================================
  // AUTHENTIFICATION EMPLOYÉ PAR CODE
  // ============================================

  /// Rechercher une succursale par son nom
  /// Retourne la première succursale active trouvée avec ce nom
  Future<Map<String, dynamic>?> getBranchByName(String name) async {
    try {
      final db = await database;
      final results = await db.query(
        'branches',
        where: 'name = ? AND is_active = 1',
        whereArgs: [name],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        print('✅ Succursale trouvée par nom "$name": ${results.first['id']}');
        return results.first;
      }
      
      print('⚠️ Aucune succursale active trouvée avec le nom "$name"');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la recherche de succursale par nom: $e');
      return null;
    }
  }

  /// Récupérer toutes les succursales actives
  /// Utilisé pour la liste déroulante dans l'écran de connexion par code
  Future<List<Map<String, dynamic>>> getAllActiveBranches() async {
    try {
      final db = await database;
      final results = await db.query(
        'branches',
        where: 'is_active = 1',
        orderBy: 'name ASC',
      );
      
      print('📋 ${results.length} succursale(s) active(s) trouvée(s)');
      return results;
    } catch (e) {
      print('❌ Erreur lors de la récupération des succursales actives: $e');
      return [];
    }
  }

  /// Vérifier le code d'accès d'un employé et récupérer ses informations
  /// 
  /// Paramètres :
  /// - code : Le code d'accès unique de l'employé (4 caractères)
  /// - branchId : L'ID de la succursale où l'employé doit travailler
  /// 
  /// Retourne : Un Map contenant 'employee' (EmployeeModel) et 'branch' (BranchModel)
  ///            si le code est valide, null sinon
  /// 
  /// Vérifications effectuées :
  /// - Le code existe dans la base de données
  /// - L'employé appartient à la succursale spécifiée
  /// - L'employé est actif (isActive = true)
  /// - L'employé n'est pas supprimé (is_deleted = false)
  /// - La succursale est active (is_active = true)
  Future<Map<String, dynamic>?> verifyEmployeeAccessCode(String code, String branchId) async {
    try {
      final db = await database;
      
      // 1. Rechercher l'employé par code d'accès
      final employeeResults = await db.query(
        'employees',
        where: 'access_code = ? AND branchId = ? AND isActive = 1 AND is_deleted = 0',
        whereArgs: [code, branchId],
        limit: 1,
      );
      
      if (employeeResults.isEmpty) {
        print('❌ Code d\'accès invalide ou employé non trouvé pour la succursale $branchId');
        return null;
      }
      
      final employeeMap = employeeResults.first;
      print('✅ Employé trouvé avec le code $code: ${employeeMap['id']}');
      
      // 2. Vérifier que la succursale existe et est active
      final branchResults = await db.query(
        'branches',
        where: 'id = ? AND is_active = 1',
        whereArgs: [branchId],
        limit: 1,
      );
      
      if (branchResults.isEmpty) {
        print('❌ Succursale $branchId non trouvée ou inactive');
        return null;
      }
      
      final branchMap = branchResults.first;
      print('✅ Succursale trouvée et active: ${branchMap['name']}');
      
      // 3. Retourner les données de l'employé et de la succursale
      return {
        'employee': employeeMap,
        'branch': branchMap,
      };
    } catch (e) {
      print('❌ Erreur lors de la vérification du code d\'accès: $e');
      print('   Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // ============================================
  // 🆕 MARKETING : VENTES PAR SUCCURSALE
  // ============================================

  /// Récupérer les ventes par succursale avec filtres
  Future<List<Map<String, dynamic>>> getSalesByBranch({
    String? branchId,
    String? city,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final db = await database;
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (branchId != null) {
        whereClause += ' AND b.id = ?';
        whereArgs.add(branchId);
      }
      
      if (city != null) {
        whereClause += ' AND b.city = ?';
        whereArgs.add(city);
      }
      
      String orderWhereClause = '1=1';
      List<dynamic> orderWhereArgs = [];
      if (periodStart != null) {
        orderWhereClause += ' AND o.date >= ?';
        orderWhereArgs.add(periodStart.toIso8601String());
      }
      if (periodEnd != null) {
        orderWhereClause += ' AND o.date <= ?';
        orderWhereArgs.add(periodEnd.toIso8601String());
      }
      
      final result = await db.rawQuery('''
        SELECT 
          '${const Uuid().v4()}' as id,
          b.id as branch_id,
          p.id as product_id,
          p.name as product_name,
          COALESCE(c.name, 'Non catégorisé') as category,
          COALESCE(SUM(oi.quantity), 0) as quantity,
          COALESCE(SUM(CASE WHEN o.status = 'Livrée' THEN oi.quantity ELSE 0 END), 0) as sold_quantity,
          COALESCE(SUM(CASE WHEN o.status = 'Livrée' THEN oi.price * oi.quantity ELSE 0 END), 0) as revenue,
          b.city as city,
          b.district as district,
          datetime('now') as last_updated,
          ? as period_start,
          ? as period_end
        FROM branches b
        LEFT JOIN products p ON p.branchId = b.id
        LEFT JOIN order_items oi ON oi.productId = p.id
        LEFT JOIN orders o ON o.id = oi.orderId AND $orderWhereClause
        LEFT JOIN categories c ON c.id = p.categoryId
        WHERE $whereClause AND b.is_active = 1
        GROUP BY b.id, p.id
        HAVING quantity > 0 OR sold_quantity > 0
        ORDER BY revenue DESC
      ''', [
        ...whereArgs,
        periodStart?.toIso8601String(),
        periodEnd?.toIso8601String(),
        ...orderWhereArgs,
      ]);
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des ventes par succursale: $e');
      return [];
    }
  }

  /// Récupérer les résumés de ventes par succursale (pour KPIs)
  Future<List<Map<String, dynamic>>> getBranchSalesSummaries({
    String? city,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final db = await database;
      
      String whereClause = 'b.is_active = 1';
      List<dynamic> whereArgs = [];
      
      if (city != null) {
        whereClause += ' AND b.city = ?';
        whereArgs.add(city);
      }
      
      String orderWhereClause = '1=1';
      List<dynamic> orderWhereArgs = [];
      if (periodStart != null) {
        orderWhereClause += ' AND o.date >= ?';
        orderWhereArgs.add(periodStart.toIso8601String());
      }
      if (periodEnd != null) {
        orderWhereClause += ' AND o.date <= ?';
        orderWhereArgs.add(periodEnd.toIso8601String());
      }
      
      DateTime? prevPeriodStart;
      DateTime? prevPeriodEnd;
      if (periodStart != null && periodEnd != null) {
        final periodDuration = periodEnd.difference(periodStart);
        prevPeriodEnd = periodStart.subtract(const Duration(days: 1));
        prevPeriodStart = prevPeriodEnd.subtract(periodDuration);
      }
      
      final result = await db.rawQuery('''
        SELECT 
          b.id as branch_id,
          b.name as branch_name,
          b.city as city,
          b.district as district,
          COUNT(DISTINCT p.id) as total_products,
          COALESCE(SUM(p.stockQuantity), 0) as total_stock,
          COUNT(DISTINCT CASE WHEN p.stockQuantity > 0 AND p.stockQuantity <= 5 THEN p.id END) as low_stock_count,
          COUNT(DISTINCT CASE WHEN p.stockQuantity = 0 THEN p.id END) as out_of_stock_count,
          COALESCE(SUM(CASE WHEN o.status = 'Livrée' AND $orderWhereClause THEN oi.quantity ELSE 0 END), 0) as sold_quantity,
          COALESCE(SUM(CASE WHEN o.status = 'Livrée' AND $orderWhereClause THEN oi.price * oi.quantity ELSE 0 END), 0) as revenue,
          datetime('now') as last_updated
        FROM branches b
        LEFT JOIN products p ON p.branchId = b.id
        LEFT JOIN order_items oi ON oi.productId = p.id
        LEFT JOIN orders o ON o.id = oi.orderId
        WHERE $whereClause
        GROUP BY b.id
        ORDER BY revenue DESC
      ''', [
        ...orderWhereArgs,
        ...whereArgs,
        ...orderWhereArgs,
      ]);
      
      for (var row in result) {
        final branchId = row['branch_id'] as String;
        final currentRevenue = (row['revenue'] as num?)?.toDouble() ?? 0.0;
        
        if (prevPeriodStart != null && prevPeriodEnd != null) {
          final prevResult = await db.rawQuery('''
            SELECT COALESCE(SUM(CASE WHEN o.status = 'Livrée' THEN oi.price * oi.quantity ELSE 0 END), 0) as prev_revenue
            FROM branches b
            LEFT JOIN products p ON p.branchId = b.id
            LEFT JOIN order_items oi ON oi.productId = p.id
            LEFT JOIN orders o ON o.id = oi.orderId
            WHERE b.id = ? AND o.date >= ? AND o.date <= ?
          ''', [
            branchId,
            prevPeriodStart.toIso8601String(),
            prevPeriodEnd.toIso8601String(),
          ]);
          
          final prevRevenue = (prevResult.first['prev_revenue'] as num?)?.toDouble() ?? 0.0;
          final growthRate = prevRevenue > 0 
              ? ((currentRevenue - prevRevenue) / prevRevenue) * 100 
              : 0.0;
          
          row['growth_rate'] = growthRate;
        } else {
          row['growth_rate'] = 0.0;
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des résumés de ventes: $e');
      return [];
    }
  }

  // ============================================
  // 🆕 MARKETING : DÉPENSES MARKETING
  // ============================================

  /// Insérer une dépense marketing
  Future<String> insertMarketingExpense(Map<String, dynamic> expense) async {
    try {
      final db = await database;
      await db.insert('marketing_expenses', expense);
      print('✅ Dépense marketing créée : ${expense['id']}');
      return expense['id'] as String;
    } catch (e) {
      print('❌ Erreur lors de la création de la dépense marketing: $e');
      rethrow;
    }
  }

  /// Récupérer les dépenses marketing par période
  Future<List<Map<String, dynamic>>> getMarketingExpenses({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final db = await database;
      
      String whereClause = 'branch_id = ?';
      List<dynamic> whereArgs = [branchId];
      
      if (startDate != null) {
        whereClause += ' AND expense_date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND expense_date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (category != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }
      
      final result = await db.query(
        'marketing_expenses',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'expense_date DESC',
      );
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des dépenses marketing: $e');
      return [];
    }
  }

  /// Mettre à jour une dépense marketing
  Future<int> updateMarketingExpense(String id, Map<String, dynamic> expense) async {
    try {
      final db = await database;
      expense['updated_at'] = DateTime.now().toIso8601String();
      final result = await db.update(
        'marketing_expenses',
        expense,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Dépense marketing mise à jour : $id');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la dépense marketing: $e');
      rethrow;
    }
  }

  /// Supprimer une dépense marketing
  Future<int> deleteMarketingExpense(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'marketing_expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Dépense marketing supprimée : $id');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la suppression de la dépense marketing: $e');
      rethrow;
    }
  }

  /// Insérer un budget marketing
  Future<String> insertMarketingBudget(Map<String, dynamic> budget) async {
    try {
      final db = await database;
      await db.insert('marketing_budgets', budget);
      print('✅ Budget marketing créé : ${budget['id']}');
      return budget['id'] as String;
    } catch (e) {
      print('❌ Erreur lors de la création du budget marketing: $e');
      rethrow;
    }
  }

  /// Récupérer les budgets marketing par période
  Future<List<Map<String, dynamic>>> getMarketingBudgets({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? periodType,
  }) async {
    try {
      final db = await database;
      
      String whereClause = 'branch_id = ?';
      List<dynamic> whereArgs = [branchId];
      
      if (startDate != null) {
        whereClause += ' AND period_start >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND period_end <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (category != null) {
        whereClause += ' AND category = ?';
        whereArgs.add(category);
      }
      
      if (periodType != null) {
        whereClause += ' AND period_type = ?';
        whereArgs.add(periodType);
      }
      
      final result = await db.query(
        'marketing_budgets',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'period_start DESC',
      );
      
      return result;
    } catch (e) {
      print('❌ Erreur lors de la récupération des budgets marketing: $e');
      return [];
    }
  }

  /// Mettre à jour un budget marketing
  Future<int> updateMarketingBudget(String id, Map<String, dynamic> budget) async {
    try {
      final db = await database;
      budget['updated_at'] = DateTime.now().toIso8601String();
      final result = await db.update(
        'marketing_budgets',
        budget,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Budget marketing mis à jour : $id');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du budget marketing: $e');
      rethrow;
    }
  }

  /// ============================================
  /// SOFT DELETE D'UN UTILISATEUR (MAGASIN)
  /// ============================================
  /// Description : Marque un utilisateur comme supprimé (is_deleted = 1)
  /// Les données restent en base mais l'utilisateur ne peut plus se connecter
  /// 
  /// Paramètre : userId - L'ID de l'utilisateur à supprimer
  /// Retourne : true si la suppression a réussi, false sinon
  Future<bool> softDeleteUser(String userId) async {
    try {
      final db = await database;
      
      // Mettre à jour is_deleted à 1 et updated_at
      final result = await db.update(
        'users',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (result > 0) {
        print('✅ Utilisateur soft deleted : $userId');
        return true;
      } else {
        print('⚠️ Aucun utilisateur trouvé avec l\'ID : $userId');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors du soft delete de l\'utilisateur: $e');
      return false;
    }
  }








}