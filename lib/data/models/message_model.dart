class MessageModel {
  final int? id;
  final int? senderId;
  final int? receiverId;
  final String? text;
  final String? date; // ⚠️ STRING et non DateTime
  final int isMe; // ⚠️ INTEGER (0 ou 1) et non bool

  MessageModel({
    this.id,
    this.senderId,
    this.receiverId,
    this.text,
    this.date,
    required this.isMe,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'date': date,
      'isMe': isMe,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      date: map['date'],
      isMe: map['isMe'],
    );
  }

  // Helper pour convertir DateTime en String
  static String dateTimeToString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Helper pour convertir String en DateTime
  DateTime? get dateTime {
    if (date == null) return null;
    try {
      return DateTime.parse(date!);
    } catch (e) {
      return null;
    }
  }

  // Helper pour convertir bool en int
  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }

  // Helper pour convertir int en bool
  bool get isMeBool => isMe == 1;
}