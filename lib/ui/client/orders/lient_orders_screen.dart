import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/client_order_provider.dart';
import '../../../data/models/order_model.dart';

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ClientOrderProvider>(context, listen: false).loadClientOrders(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<ClientOrderProvider>(context);

    // Filtrage des listes
    final pending = orderProvider.myOrders.where((o) => o.status == 'En attente').toList();
    final active = orderProvider.myOrders.where((o) => o.status == 'Validée' || o.status == 'En cours').toList();
    final history = orderProvider.myOrders.where((o) => o.status == 'Livrée' || o.status == 'Rejetée' || o.status == 'Annulée').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Mes Commandes", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E293B),
          tabs: const [
            Tab(text: "En attente"),
            Tab(text: "En cours"),
            Tab(text: "Historique"),
          ],
        ),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(pending),
          _buildList(active),
          _buildList(history),
        ],
      ),
    );
  }

  Widget _buildList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade300),
            Text("Aucune commande", style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor = Colors.grey;
    if (order.status == 'Validée') statusColor = Colors.blue;
    if (order.status == 'Livrée') statusColor = Colors.green;
    if (order.status == 'Rejetée') statusColor = Colors.red;
    if (order.status == 'En attente') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Commande #${order.id}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(order.status, style: GoogleFonts.poppins(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Divider(),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${item.quantity}x ${item.productName}", style: GoogleFonts.poppins(fontSize: 13)),
                Text("${(item.price * item.quantity).toStringAsFixed(0)} F", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
          )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd/MM/yyyy HH:mm').format(order.date), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
              Text("Total: ${order.totalAmount.toStringAsFixed(0)} FCFA", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ],
          )
        ],
      ),
    );
  }
}