class OrderItem {
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productName: map['productName'],
      quantity: map['quantity'],
      price: map['price'],
    );
  }
}

class OrderModel {
  final int id;
  final int clientId;
  final String clientName;
  final double totalAmount;
  final String status;
  final DateTime date;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.totalAmount,
    required this.status,
    required this.date,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return OrderModel(
      id: map['id'],
      clientId: map['clientId'],
      clientName: map['clientName'] ?? 'Client Inconnu',
      totalAmount: map['totalAmount'],
      status: map['status'],
      date: DateTime.parse(map['date']),
      items: items,
    );
  }
}