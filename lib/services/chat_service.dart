// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  final String _baseUrl = 'http://10.0.2.2:8000/chat';
  final String _apiKey = '#SHSUSOFTWAREENGINEERING';
  late String _username;

  ChatService(String username) {
    _username = username;
  }

  Future<List<ChatMessage>> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': _username,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return [
        ChatMessage(
          text: body['response'] ?? '',
          sender: Sender.bot,
        ),
      ];
    } else {
      return [
        ChatMessage(
          text: 'Failed to get response from server.',
          sender: Sender.bot,
        ),
      ];
    }
  }

  Future<List<ChatMessage>> fetchRecentHistory({int offset = 0, int limit = 5}) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/history'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': _username,
        'offset': offset,
        'limit': limit,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final history = body['history'] as List<dynamic>;

      return history
          .map<List<ChatMessage>>((item) {
        final timestamp = DateTime.tryParse(item['timestamp']);
        return [
          ChatMessage(
            text: item['user_input'],
            sender: Sender.user,
            timestamp: timestamp,
          ),
          ChatMessage(
            text: item['bot_response'],
            sender: Sender.bot,
            timestamp: timestamp,
          ),
        ];
      })
          .expand((pair) => pair)
          .toList();
    } else {
      return [];
    }
  }
}