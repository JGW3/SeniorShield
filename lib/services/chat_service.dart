// lib/services/chat_service.dart
import '../models/chat_message.dart';

class ChatService {
  Future<List<ChatMessage>> getBotReply(String userInput) async {
    await Future.delayed(Duration(seconds: 1)); // simulate delay

    String reply = '';

    if (userInput.toLowerCase().contains('hello')) {
      reply = 'Hi there! 👋';
    } else if (userInput.toLowerCase().contains('how are you')) {
      reply = 'I\'m just code, but I\'m doing great!';
    } else {
      reply = 'You said: "$userInput"';
    }

    return [ChatMessage(text: reply, sender: Sender.bot)];
  }
}
