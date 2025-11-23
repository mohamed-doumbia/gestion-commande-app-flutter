import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';
import '../data/models/message_model.dart';

class ChatProvider with ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;

  // Charger la conversation
  Future<void> loadMessages(int myId, int otherId) async {
    _isLoading = true;
    // notifyListeners(); // On évite le scintillement
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
      date: DateTime.now(),
      isMe: true, // C'est moi qui envoie
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
        text: "Merci pour votre message ! Je vérifie votre commande et je reviens vers vous.", // Réponse type chatbot
        date: DateTime.now(),
        isMe: false, // C'est l'autre qui parle
      );

      _messages.add(reply);
      notifyListeners();
      await DatabaseHelper.instance.insertMessage(reply);
    });
  }
}