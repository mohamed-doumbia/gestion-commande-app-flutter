import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/local/database_helper.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Mon Panier", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text("Votre panier est vide", style: GoogleFonts.poppins(fontSize: 16)))
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: cart.items.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = cartItems[i];
                return ListTile(
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                  title: Text(item.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text("${item.quantity} x ${item.product.price} = ${item.quantity * item.product.price} F",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cart.removeSingleItem(item.product.id!),
                      ),
                      Text("${item.quantity}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cart.addItem(item.product),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Zone Total & Checkout
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${cart.totalAmount.toStringAsFixed(0)} FCFA",
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (cart.totalAmount <= 0) ? null : () => _processOrder(context, cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text("Commander maintenant", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _processOrder(BuildContext context, CartProvider cart) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (user == null) return;

    // Préparation des données pour la BDD
    final orderItems = cart.items.values.map((item) => {
      'productId': item.product.id,
      'productName': item.product.name,
      'quantity': item.quantity,
      'price': item.product.price,
    }).toList();

    // Sauvegarde SQLite
    await DatabaseHelper.instance.createOrder(
        user.id!,
        cart.totalAmount,
        orderItems
    );

    // Simulation envoi SMS / Notification
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Succès !"),
        content: const Text("Votre commande a été envoyée au vendeur. Vous recevrez un SMS de confirmation."),
        actions: [
          TextButton(
            onPressed: () {
              cart.clear(); // Vider le panier
              Navigator.of(ctx).pop(); // Fermer dialog
              Navigator.of(context).pop(); // Retour au catalogue
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}