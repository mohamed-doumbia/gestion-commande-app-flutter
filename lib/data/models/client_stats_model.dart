class ClientStatsModel {
  final int id;
  final String name;
  final String phone;
  final int totalOrders;
  final double totalSpent;
  final String? lastOrderDate;

  ClientStatsModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalSpent,
    this.lastOrderDate,
  });

  // LOGIQUE VIP : Au moins 5 commandes OU 50000 FCFA dépensés
  bool get isVip => totalOrders >= 5 || totalSpent >= 50000;

  // Niveau client (Bronze, Silver, Gold, VIP)
  String get clientLevel {
    if (totalSpent >= 100000) return 'VIP';
    if (totalSpent >= 50000) return 'Gold';
    if (totalSpent >= 20000) return 'Silver';
    return 'Bronze';
  }

  // Badge couleur selon le niveau
  String get levelColor {
    switch (clientLevel) {
      case 'VIP':
        return 'amber';
      case 'Gold':
        return 'yellow';
      case 'Silver':
        return 'grey';
      default:
        return 'brown';
    }
  }

  factory ClientStatsModel.fromMap(Map<String, dynamic> map) {
    return ClientStatsModel(
      id: map['id'],
      name: map['fullName'],
      phone: map['phone'],
      totalOrders: map['orderCount'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      lastOrderDate: map['lastOrderDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': name,
      'phone': phone,
      'orderCount': totalOrders,
      'totalSpent': totalSpent,
      'lastOrderDate': lastOrderDate,
    };
  }
}