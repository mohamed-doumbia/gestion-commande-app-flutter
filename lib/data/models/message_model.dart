class MessageModel {
  final int? id;
  final int senderId;    // ID de celui qui envoie
  final int receiverId;  // ID de celui qui reçoit
  final String text;
  final DateTime date;
  final bool isMe;       // Pour savoir si bulle à droite (Moi) ou gauche (L'autre)

  MessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.date,
    required this.isMe,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'date': date.toIso8601String(),
      'isMe': isMe ? 1 : 0,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      date: DateTime.parse(map['date']),
      isMe: map['isMe'] == 1,
    );
  }
}