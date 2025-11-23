class ClientStatsModel {
  final int id;
  final String name;
  final String phone;
  final int totalOrders;
  final double totalSpent;

  ClientStatsModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalSpent,
  });

  factory ClientStatsModel.fromMap(Map<String, dynamic> map) {
    return ClientStatsModel(
      id: map['id'],
      name: map['fullName'],
      phone: map['phone'],
      totalOrders: map['orderCount'],
      totalSpent: map['totalSpent'] ?? 0.0,
    );
  }
}