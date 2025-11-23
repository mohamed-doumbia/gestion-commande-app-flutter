import 'package:flutter/material.dart';
import 'package:gestion_commandes/providers/cart_provider.dart';
import 'package:gestion_commandes/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'ui/auth/login_screen.dart'; // Créer ce fichier (similaire au register)
import 'ui/auth/register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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