import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ajoute intl au pubspec si besoin pour formater la date
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../data/models/order_model.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Charger les commandes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<OrderProvider>(context, listen: false).loadVendorOrders(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Gestion Commandes", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- Section KPIs (Haut de page) ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiItem("En attente", "${orderProvider.pendingCount}", Colors.orange),
                _buildKpiItem("Commandes", "${orderProvider.orders.length}", Colors.blue),
                _buildKpiItem("Chiffre", "${orderProvider.totalRevenue.toStringAsFixed(0)} F", Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // --- Tabs Navigation ---
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E293B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E293B),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "En attente"),
              Tab(text: "En cours"),
              Tab(text: "Historique"),
            ],
          ),

          // --- Liste des commandes ---
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(orderProvider.pendingOrders, user!.id!, isActionable: true),
                _buildOrderList(orderProvider.activeOrders, user.id!, isActionable: true, isValidation: false),
                _buildOrderList(orderProvider.historyOrders, user.id!, isActionable: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, int vendorId, {bool isActionable = false, bool isValidation = true}) {
    if (orders.isEmpty) {
      return Center(child: Text("Aucune commande ici", style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, vendorId, isActionable, isValidation);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, int vendorId, bool isActionable, bool isValidation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
          child: Icon(Icons.person, color: _getStatusColor(order.status)),
        ),
        title: Text(order.clientName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${order.items.length} articles • ${order.totalAmount.toStringAsFixed(0)} FCFA",
                style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
            Text("Le ${DateFormat('dd/MM à HH:mm').format(order.date)}", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Text(order.status, style: GoogleFonts.poppins(fontSize: 10, color: _getStatusColor(order.status), fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text("Détails de la commande :", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item.quantity}x ${item.productName}", style: GoogleFonts.poppins()),
                      Text("${(item.price * item.quantity).toStringAsFixed(0)} F", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const SizedBox(height: 20),

                // --- Boutons d'action ---
                if (isActionable)
                  Row(
                    children: [
                      if (isValidation) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(order.id, "Rejetée", vendorId),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: Text("Rejeter", style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(order.id, "Validée", vendorId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: Text("Valider", style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(order.id, "Livrée", vendorId),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                            child: Text("Marquer comme Livré", style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ),
                      ]
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente': return Colors.orange;
      case 'Validée': return Colors.blue;
      case 'Livrée': return Colors.green;
      case 'Rejetée': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _updateStatus(int orderId, String status, int vendorId) {
    Provider.of<OrderProvider>(context, listen: false).updateStatus(orderId, status, vendorId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Commande $status ! Notification envoyée.")));
  }
}