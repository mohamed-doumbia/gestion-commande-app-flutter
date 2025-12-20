import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestion_commandes/providers/branch_provider.dart';
import 'package:gestion_commandes/providers/cart_provider.dart';
import 'package:gestion_commandes/providers/chat_provider.dart';
import 'package:gestion_commandes/providers/client_order_provider.dart';
import 'package:gestion_commandes/providers/client_provider.dart';
import 'package:gestion_commandes/providers/order_provider.dart';
import 'package:gestion_commandes/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/auth_provider.dart';
import 'ui/auth/login_screen.dart'; // Créer ce fichier (similaire au register)
import 'ui/auth/register_screen.dart';

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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Commandes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E293B),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const RegisterScreen(), // Pour tester direct, mais normalement LoginScreen
    );
  }
}