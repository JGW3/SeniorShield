import 'package:flutter_tts/flutter_tts.dart';
import '../models/chat_message.dart';

class ChatService {
  final FlutterTts _flutterTts = FlutterTts();

  // Initialize FlutterTTS settings
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  // Send a message and get a response
  Future<List<ChatMessage>> sendMessage(String message, {bool voiceResponse = false}) async {
    // Add user message
    List<ChatMessage> chatMessages = [
      ChatMessage(
        text: message,
        sender: Sender.user,
      ),
    ];

    // Simulate a bot response (you could integrate your chatbot here)
    String botResponse = "This is a response from the bot to: $message";

    // Add bot response
    chatMessages.add(
      ChatMessage(
        text: botResponse,
        sender: Sender.bot,
      ),
    );

    // If voice response is enabled, speak the bot's response
    if (voiceResponse) {
      await _initializeTts();
      await _flutterTts.speak(botResponse);
    }

    return chatMessages;
  }

  // Stop speaking (in case you want to stop the TTS)
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
