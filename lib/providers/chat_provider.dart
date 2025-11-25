import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/message_model.dart';

class ChatProvider with ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // Charger la conversation
  Future<void> loadMessages(int myId, int otherId) async {
    _isLoading = true;
    notifyListeners();

    _messages = await DatabaseHelper.instance.getMessages(myId, otherId);

    _isLoading = false;
    notifyListeners();
  }

  // Envoyer un message
  Future<void> sendMessage(int myId, int otherId, String text) async {
    final newMessage = MessageModel(
      senderId: myId,
      receiverId: otherId,
      text: text,
      date: MessageModel.dateTimeToString(DateTime.now()), // ✅ Converti en String
      isMe: MessageModel.boolToInt(true), // ✅ Converti en int (1)
    );

    // 1. Mise à jour instantanée de l'UI (Optimistic UI)
    _messages.add(newMessage);
    notifyListeners();

    // 2. Sauvegarde BDD
    await DatabaseHelper.instance.insertMessage(newMessage);

    // 3. SIMULATION TEMPS RÉEL (Réponse automatique du vendeur/client)
    _simulateAutoReply(otherId, myId);
  }

  void _simulateAutoReply(int senderId, int receiverId) {
    Future.delayed(const Duration(seconds: 2), () async {
      final reply = MessageModel(
        senderId: senderId,
        receiverId: receiverId,
        text: "Merci pour votre message ! Je vérifie votre commande et je reviens vers vous.",
        date: MessageModel.dateTimeToString(DateTime.now()), // ✅ Converti en String
        isMe: MessageModel.boolToInt(false), // ✅ Converti en int (0)
      );

      _messages.add(reply);
      notifyListeners();
      await DatabaseHelper.instance.insertMessage(reply);
    });
  }

  // Nettoyer les messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}