// lib/models/chat_message.dart
enum Sender { user, bot }

class ChatMessage {
  final String text;
  final Sender sender;
  final DateTime? timestamp; // Optional timestamp

  ChatMessage({
    required this.text,
    required this.sender,
    this.timestamp,
  });
}
