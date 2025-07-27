// lib/services/huggingface_chat_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class HuggingFaceChatService {
  late String _username;
  final List<ChatMessage> _conversationHistory = [];
  
  // Using free Hugging Face Inference API - no key required for basic use
  final String _baseUrl = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large';
  
  HuggingFaceChatService(String username) {
    _username = username;
    
    // Add welcome message immediately
    final welcomeMessage = ChatMessage(
      text: "👋 Hello! I'm your SeniorShield AI assistant. I'm here to help you stay safe from scams and fraud.\n\nI can help you with:\n• Identifying phone scams\n• Recognizing email fraud\n• Understanding suspicious calls\n• Protecting your personal information\n\nWhat would you like to know about staying safe?",
      sender: Sender.bot,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(welcomeMessage);
  }

  Future<List<ChatMessage>> sendMessage(String message) async {
    // Add user message to history
    final userMessage = ChatMessage(
      text: message,
      sender: Sender.user,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(userMessage);

    String botResponse;
    
    try {
      // First check for urgent scam scenarios locally (immediate response)
      final urgentResponse = _checkUrgentScams(message.toLowerCase().trim());
      if (urgentResponse != null) {
        botResponse = urgentResponse;
      } else {
        // Use AI for more nuanced responses
        botResponse = await _getAIResponse(message);
      }
    } catch (e) {
      print('AI service error: $e');
      // Fallback to local response
      botResponse = _generateLocalResponse(message.toLowerCase().trim());
    }

    final botMessage = ChatMessage(
      text: botResponse,
      sender: Sender.bot,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(botMessage);

    return [botMessage];
  }

  Future<String> _getAIResponse(String message) async {
    try {
      // Create a scam-focused prompt
      final prompt = """You are SeniorShield, an AI assistant specialized in protecting seniors from scams and fraud. 
      
Context: You help identify scams, provide safety advice, and educate about common fraud tactics targeting seniors.

User message: "$message"

Respond helpfully about scam protection. If the user describes a potential scam, clearly identify it and provide specific safety steps. Keep responses under 200 words and be warm but direct about dangers.""";

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_length': 200,
            'temperature': 0.7,
            'return_full_text': false,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          String aiResponse = data[0]['generated_text'] ?? '';
          
          // Clean up the response
          aiResponse = aiResponse.trim();
          if (aiResponse.isEmpty) {
            return _generateLocalResponse(message.toLowerCase());
          }
          
          return aiResponse;
        }
      }
      
      // If AI fails, use local fallback
      return _generateLocalResponse(message.toLowerCase());
      
    } catch (e) {
      print('Hugging Face API error: $e');
      return _generateLocalResponse(message.toLowerCase());
    }
  }

  // Immediate responses for urgent scam scenarios
  String? _checkUrgentScams(String userInput) {
    if (userInput.contains(RegExp(r'\b(jail|arrest|bail|prison|police|court|legal trouble)\b'))) {
      return "🚨 URGENT: This is a bail/emergency scam! Hang up immediately. Real police never ask for bail money over the phone. Call your family member directly at their known number to verify they're safe. If you sent money, contact your bank and police now.";
    }
    
    if (userInput.contains(RegExp(r'\b(gift card|target card|amazon card|walmart card|apple card|itunes|google play)\b'))) {
      return "🚨 SCAM ALERT! NO legitimate business ever asks for gift card payments. This is 100% a scam. Don't give out gift card numbers. If you already bought cards, contact the retailer immediately to try to recover funds.";
    }
    
    if (userInput.contains(RegExp(r'\b(irs|tax|owe|refund|audit)\b')) && userInput.contains(RegExp(r'\b(call|phone|pay|arrest)\b'))) {
      return "🚨 IRS SCAM! The IRS never calls threatening arrest or demanding immediate payment. They communicate by mail first. Hang up and call the real IRS at 1-800-829-1040 if you have tax concerns.";
    }
    
    return null; // No urgent scam detected, can use AI
  }

  // Fallback local responses with more variety
  String _generateLocalResponse(String userInput) {
    final responses = {
      'greeting': [
        "Hello! What scam protection questions can I help you with today?",
        "Hi there! I'm here to help you stay safe. What's on your mind?",
        "Welcome back! What can I help you with regarding scam protection?",
      ],
      'scam_general': [
        "I can help identify that! Can you tell me more details about what happened?",
        "That does sound suspicious. What specifically made you concerned about it?",
        "Let me help you figure this out. Can you describe the situation in more detail?",
        "I'm here to help! What exactly happened that seemed suspicious to you?",
      ],
      'phone_related': [
        "Phone scams are very common. Can you tell me what the caller said or asked for?",
        "I can help with phone scam questions. What did the caller want from you?",
        "Phone calls can be tricky to identify. What made this call seem suspicious?",
      ],
      'email_related': [
        "Email scams are everywhere! What did the email ask you to do?",
        "I can help identify email fraud. What made this email seem suspicious?",
        "Email scams often look very real. Can you describe what the email said?",
      ],
      'general_help': [
        "I can help with many scam-related questions. What specific situation are you dealing with?",
        "There are many types of scams out there. What would you like to learn about?",
        "I'm here to help you stay safe! What particular concern do you have?",
        "I can provide advice on various scam types. What's your specific question?",
      ]
    };
    
    if (userInput.contains(RegExp(r'\b(hello|hi|hey|good morning|good afternoon)\b'))) {
      return responses['greeting']![math.Random().nextInt(responses['greeting']!.length)];
    }
    
    if (userInput.contains(RegExp(r'\b(phone|call|caller|called)\b'))) {
      return responses['phone_related']![math.Random().nextInt(responses['phone_related']!.length)];
    }
    
    if (userInput.contains(RegExp(r'\b(email|message|text|link)\b'))) {
      return responses['email_related']![math.Random().nextInt(responses['email_related']!.length)];
    }
    
    if (userInput.contains(RegExp(r'\b(scam|fraud|suspicious|fake)\b'))) {
      return responses['scam_general']![math.Random().nextInt(responses['scam_general']!.length)];
    }
    
    if (userInput.contains(RegExp(r'\b(help|advice|what|how|can you|tell me)\b'))) {
      return responses['general_help']![math.Random().nextInt(responses['general_help']!.length)];
    }
    
    // Default varied responses
    return responses['general_help']![math.Random().nextInt(responses['general_help']!.length)];
  }

  Future<List<ChatMessage>> fetchRecentHistory({int offset = 0, int limit = 10}) async {
    final startIndex = math.max(0, _conversationHistory.length - offset - limit);
    final endIndex = _conversationHistory.length - offset;
    
    if (startIndex >= endIndex) return [];
    
    return _conversationHistory.sublist(startIndex, endIndex);
  }
}