import '../models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalChatService {
  final String _username;
  static const String _historyKey = 'chat_history';
  final Map<String, List<String>> _conversationContext = {};

  LocalChatService(this._username);

  Future<List<ChatMessage>> sendMessage(String message) async {
    // Store user message in conversation context
    if (!_conversationContext.containsKey(_username)) {
      _conversationContext[_username] = [];
    }
    _conversationContext[_username]!.add(message.toLowerCase());

    // Generate smart response
    final response = _generateSmartResponse(message);
    
    // Save to local storage
    await _saveToHistory(message, response);

    return [
      ChatMessage(
        text: response,
        sender: Sender.bot,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<List<ChatMessage>> fetchRecentHistory({int offset = 0, int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('${_historyKey}_$_username');
      
      if (historyJson == null) return [];
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      final List<ChatMessage> messages = [];
      
      for (var item in historyList.reversed.skip(offset).take(limit)) {
        final timestamp = DateTime.tryParse(item['timestamp'] ?? '');
        
        // Add user message
        messages.add(ChatMessage(
          text: item['user_input'] ?? '',
          sender: Sender.user,
          timestamp: timestamp,
        ));
        
        // Add bot response
        messages.add(ChatMessage(
          text: item['bot_response'] ?? '',
          sender: Sender.bot,
          timestamp: timestamp,
        ));
      }
      
      return messages.reversed.toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<void> _saveToHistory(String userMessage, String botResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('${_historyKey}_$_username');
      
      List<dynamic> history = [];
      if (historyJson != null) {
        history = jsonDecode(historyJson);
      }
      
      history.add({
        'user_input': userMessage,
        'bot_response': botResponse,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 50 conversations
      if (history.length > 50) {
        history = history.sublist(history.length - 50);
      }
      
      await prefs.setString('${_historyKey}_$_username', jsonEncode(history));
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  String _generateSmartResponse(String message) {
    final messageLower = message.toLowerCase();
    
    // Greeting
    if (_isGreeting(messageLower)) {
      return """Hello! I'm your personal scam prevention assistant. I can help you identify and avoid common scams.

You can ask me about:
- Suspicious phone calls or emails
- Whether something might be a scam
- How to protect yourself from fraud
- What to do if you think you've been scammed

What's on your mind today? Have you encountered something suspicious?""";
    }

    // IRS/Tax scam detection
    if (_containsAny(messageLower, ["irs", "tax", "owe money", "arrest", "warrant", "back taxes", "refund"])) {
      if (_containsAny(messageLower, ["called", "phone", "call"])) {
        return """🚨 This sounds like an IRS phone scam!

The IRS will NEVER:
- Call you to demand immediate payment
- Threaten arrest over the phone  
- Ask for payment via gift cards or wire transfers
- Call without first mailing you a bill

What they told you is a SCAM. The real IRS sends letters first, then follows up. If you're concerned about actual tax issues, call the IRS directly at 1-800-829-1040.

Did they ask you to pay with gift cards or threaten immediate arrest?""";
      } else {
        return "IRS scams are very common. Can you tell me how they contacted you - by phone, email, or mail? This will help me give you specific advice.";
      }
    }

    // Tech support scam detection  
    if (_containsAny(messageLower, ["computer", "microsoft", "windows", "virus", "pop up", "popup", "locked", "infected", "tech support"])) {
      return """🚨 This sounds like a tech support scam!

Real facts:
- Microsoft/Apple NEVER call you about computer problems
- Pop-ups claiming "Your computer is infected" are fake
- Real antivirus software doesn't lock your computer

What to do:
- Close any suspicious pop-ups (don't call numbers shown)
- Never give remote access to strangers
- Run your own antivirus scan

Did they ask you to download software or give them remote access to your computer?""";
    }

    // Romance scam detection
    if (_containsAny(messageLower, ["dating", "online", "love", "relationship", "met on", "can't meet", "emergency", "money", "visit"])) {
      return """❤️ This could be a romance scam - very common targeting seniors.

Warning signs:
- Professes love very quickly
- Always has excuses not to meet in person
- Claims to be military/doctor overseas
- Asks for money for emergencies/travel

Protection tips:
- Never send money to someone you haven't met in person
- Do a reverse image search on their photos
- Real relationships develop slowly and in person

Have they asked you for money or always have excuses not to meet?""";
    }

    // Prize/lottery scam detection
    if (_containsAny(messageLower, ["won", "prize", "lottery", "congratulations", "winner", "claim", "fee", "taxes", "processing"])) {
      return """🎉 This is definitely a prize/lottery scam!

Remember: You can't win a contest you didn't enter!

Scam signs:
- Claiming you won something you didn't enter
- Asking for "taxes" or "fees" upfront
- Pressuring you to act quickly
- Requesting bank account info

Real prizes:
- Don't require upfront payments
- Don't ask for bank details over phone
- Come from companies you actually entered contests with

Did they ask you to pay fees or taxes before getting your "prize"?""";
    }

    // Phone/robocall issues
    if (_containsAny(messageLower, ["robocall", "spam call", "unknown number", "telemarketer", "warranty", "insurance", "social security"])) {
      return """📞 Sounds like you're dealing with scam calls!

Common phone scams:
- Auto warranty extensions (for cars you may not own)
- Social Security "suspension" threats
- Medicare/insurance offers
- "Your account has been compromised"

Best protection:
- Don't answer unknown numbers
- Register at donotcall.gov
- Block repeated spam numbers
- Never give personal info to unsolicited callers

What type of calls are you getting most often?""";
    }

    // Email/phishing detection
    if (_containsAny(messageLower, ["email", "click", "link", "account", "suspended", "verify", "update", "login"])) {
      return """📧 This sounds like a phishing email scam!

Red flags in emails:
- Urgent threats about account suspension
- Generic greetings like "Dear Customer"
- Requests to "verify" or "update" information
- Suspicious links or attachments

Stay safe:
- Don't click links in suspicious emails
- Log into accounts directly through official websites
- Check the sender's email address carefully
- When in doubt, call the company directly

What company is the email claiming to be from?""";
    }

    // Generic responses based on keywords
    if (_containsAny(messageLower, ["call", "called", "phone", "number"])) {
      return """📞 Phone calls from strangers are often scams, especially if they:

- Want money, gift cards, or personal information
- Claim urgency ("act now or else...")
- Say they're from government agencies
- Threaten arrest or legal action
- Offer prizes or say you owe money

SAFE RESPONSE: Hang up and call the organization directly using a number you trust (not the one they gave you).

Most legitimate organizations will send mail first, not call unexpectedly.""";
    }

    if (_containsAny(messageLower, ["email", "text", "message"])) {
      return """📧 Suspicious messages often try to:

- Get you to click links or download files
- Steal passwords or personal information  
- Create false urgency about accounts
- Trick you into paying fake bills

SAFE RESPONSE: Don't click anything. Go directly to the real website by typing it yourself, or call the company using their official number.

Delete the message if you're unsure.""";
    }

    if (_containsAny(messageLower, ["money", "pay", "owe", "debt", "bill"])) {
      return """💰 Money requests are major red flags, especially:

- Demands for immediate payment
- Requests for gift cards, wire transfers, or Bitcoin
- Claims you owe money you don't remember
- "Pay now to avoid arrest/consequences"

REAL ORGANIZATIONS:
- Send bills by mail first
- Accept normal payment methods (checks, credit cards)
- Give you time to verify and pay
- Don't threaten immediate arrest

If someone demands money urgently, it's almost certainly a scam.""";
    }

    // General scam protection advice
    if (_containsAny(messageLower, ["scam", "fraud", "help", "what", "how", "safe", "protect"])) {
      return """🛡️ General Scam Protection Tips:

1. **HANG UP** on suspicious calls - real organizations won't pressure you
2. **DON'T CLICK** links in unexpected emails - go to websites directly  
3. **NEVER PAY** with gift cards, wire transfers, or Bitcoin for legitimate services
4. **TRUST YOUR INSTINCTS** - if something feels wrong, it probably is
5. **ASK FOR HELP** - talk to family, friends, or call organizations directly

Remember: It's always okay to hang up, delete emails, or ask a trusted friend for advice.""";
    }

    // Default helpful response
    return """🛡️ I'm here to help you avoid scams! Here are the most important things to remember:

1. **HANG UP** on suspicious calls - real organizations won't pressure you
2. **DON'T CLICK** links in unexpected emails - go to websites directly  
3. **NEVER PAY** with gift cards, wire transfers, or Bitcoin for legitimate services
4. **TRUST YOUR INSTINCTS** - if something feels wrong, it probably is
5. **ASK FOR HELP** - talk to family, friends, or call organizations directly

What specific situation are you dealing with? I can give you more targeted advice.""";
  }

  bool _isGreeting(String message) {
    return _containsAny(message, ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]);
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any((phrase) => text.contains(phrase));
  }
}