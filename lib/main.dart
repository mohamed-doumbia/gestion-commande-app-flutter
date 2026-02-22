import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestion_commandes/providers/branch_provider.dart';
import 'package:gestion_commandes/providers/branch_accounting_provider.dart';
import 'package:gestion_commandes/providers/branch_employee_provider.dart';
import 'package:gestion_commandes/providers/branch_marketing_provider.dart';
import 'package:gestion_commandes/providers/marketing_expense_provider.dart';
import 'package:gestion_commandes/providers/cart_provider.dart';
import 'package:gestion_commandes/providers/chat_provider.dart';
import 'package:gestion_commandes/providers/client_order_provider.dart';
import 'package:gestion_commandes/providers/client_provider.dart';
import 'package:gestion_commandes/providers/order_provider.dart';
import 'package:gestion_commandes/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/auth_provider.dart';
import 'ui/auth/login_screen.dart';
import 'ui/client/home_client.dart';
import 'ui/vendor/home_vendor.dart';

void main() {
  // Initialisation des Widgets
  WidgetsFlutterBinding.ensureInitialized();

  // --- CORRECTION POUR WINDOWS ---
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialise le factory pour PC
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    }
  // --- FIN CORRECTION ---

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ClientOrderProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => BranchAccountingProvider()),
        ChangeNotifierProvider(create: (_) => BranchEmployeeProvider()),
        ChangeNotifierProvider(create: (_) => BranchMarketingProvider()),
        ChangeNotifierProvider(create: (_) => MarketingExpenseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  Widget? _initialRoute;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour garantir que le contexte est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  /// ============================================
  /// VÉRIFIER LA SESSION AU DÉMARRAGE
  /// ============================================
  Future<void> _checkSession() async {
    if (!mounted) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Restaurer UNIQUEMENT les sessions client (pas vendeur, pas employé)
      final hasSession = await authProvider.restoreSession();
      
      // Si aucune session valide, aller sur LoginScreen
      if (!hasSession) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _initialRoute = const LoginScreen();
          });
        }
        return;
      }
      
      // Vérifier le type de session
      if (authProvider.isUserSession) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          print('❌ Session invalide');
          await authProvider.logout();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _initialRoute = const LoginScreen();
            });
          }
          return;
        }
        
        // Rediriger selon le rôle
        if (user.role == 'vendor') {
          _initialRoute = const HomeVendor();
        } else if (user.role == 'client') {
          _initialRoute = const HomeClient();
        } else {
          _initialRoute = const LoginScreen();
        }
      } else {
        // Aucune session valide détectée
        _initialRoute = const LoginScreen();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Gérer les erreurs pour éviter l'écran blanc
      print('❌ Erreur lors de la restauration de session: $e');
      print('Stack trace: $stackTrace');
      
      // En cas d'erreur, nettoyer la session et aller sur LoginScreen
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialRoute = const LoginScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'Gestion Commandes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1E293B),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Gestion Commandes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E293B),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: _initialRoute ?? const LoginScreen(),
    );
  }
}