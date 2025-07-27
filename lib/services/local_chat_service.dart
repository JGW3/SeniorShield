// lib/services/local_chat_service.dart
import 'dart:math' as math;
import '../models/chat_message.dart';

class LocalChatService {
  late String _username;
  final List<ChatMessage> _conversationHistory = [];

  LocalChatService(String username) {
    _username = username;
  }

  Future<List<ChatMessage>> sendMessage(String message) async {
    // Add user message to history
    final userMessage = ChatMessage(
      text: message,
      sender: Sender.user,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(userMessage);

    // Generate bot response
    final botResponse = _generateResponse(message.toLowerCase().trim());
    final botMessage = ChatMessage(
      text: botResponse,
      sender: Sender.bot,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(botMessage);

    return [botMessage];
  }

  Future<List<ChatMessage>> fetchRecentHistory({int offset = 0, int limit = 10}) async {
    final startIndex = math.max(0, _conversationHistory.length - offset - limit);
    final endIndex = _conversationHistory.length - offset;
    
    if (startIndex >= endIndex) return [];
    
    return _conversationHistory.sublist(startIndex, endIndex);
  }

  String _generateResponse(String userInput) {
    // Specific scam scenarios - check these first
    if (userInput.contains(RegExp(r'\b(jail|arrest|bail|prison|police|court|legal trouble)\b'))) {
      return "🚨 THIS IS A SCAM! This is called a 'grandparent scam' or 'emergency scam.' Real police/courts never ask for bail money over the phone or via gift cards. Your family member is likely safe. Hang up immediately and call your family member directly to verify they're okay. If you already sent money, contact your bank and local police immediately.";
    }
    
    if (userInput.contains(RegExp(r'\b(gift card|target card|amazon card|walmart card|apple card|itunes|google play)\b'))) {
      return "🚨 SCAM ALERT! NO legitimate business, government agency, or court ever asks for payment via gift cards. Gift cards are like cash and impossible to trace. This is 100% a scam. If you bought gift cards, don't give the numbers - contact the card company immediately to see if you can recover the money.";
    }
    
    if (userInput.contains(RegExp(r'\b(grandson|granddaughter|son|daughter|family member|relative)\b')) && userInput.contains(RegExp(r'\b(trouble|emergency|accident|hospital|money)\b'))) {
      return "This sounds like a family emergency scam! Before sending any money: 1) Hang up, 2) Call your family member directly at their known number, 3) Verify they're safe. Scammers research families on social media to make these calls convincing. Real emergencies go through proper channels, not phone requests for money.";
    }
    
    if (userInput.contains(RegExp(r'\b(irs|tax|owe|refund|audit)\b'))) {
      return "🚨 IRS SCAM! The IRS never calls demanding immediate payment or threatening arrest. They communicate by mail first. Real IRS agents don't ask for payment via gift cards, wire transfers, or prepaid cards. If concerned about taxes, call the IRS directly at 1-800-829-1040.";
    }
    
    if (userInput.contains(RegExp(r'\b(microsoft|windows|computer|virus|infected|fix)\b'))) {
      return "This is a tech support scam! Microsoft, Apple, and other tech companies NEVER call you unsolicited about computer problems. Never give remote access to your computer or pay for 'tech support' from unsolicited callers. Hang up and run your own antivirus scan if concerned.";
    }
    
    if (userInput.contains(RegExp(r'\b(won|lottery|sweepstakes|prize|congratulations)\b'))) {
      return "Lottery/prize scams! Remember: You cannot win a contest you didn't enter. Legitimate prizes never require upfront payments, fees, or taxes before you receive your winnings. Real lotteries deduct taxes from your winnings, not before. This is always a scam.";
    }

    // Scam protection knowledge base
    final scamKeywords = {
      'phishing': [
        "Phishing attacks try to steal your personal information through fake emails or websites. Never click suspicious links or give personal info to unsolicited contacts.",
        "Watch out for phishing! Legitimate companies won't ask for passwords or Social Security numbers via email or text.",
      ],
      'robocall': [
        "Robocalls are automated calls, often used for scams. You can register with the Do Not Call Registry, but scammers ignore it. It's best to not answer unknown numbers.",
        "If you get robocalls, don't press any buttons - this confirms your number is active. Hang up immediately and block the number.",
      ],
      'identity theft': [
        "Identity theft happens when someone uses your personal information without permission. Monitor your credit reports and bank statements regularly.",
        "Protect yourself from identity theft: never give out your Social Security number unless absolutely necessary, and shred documents with personal info.",
      ],
      'lottery': [
        "Lottery scams claim you've won money but need to pay fees first. Real lotteries don't require upfront payments. If you didn't enter, you didn't win!",
        "Remember: You cannot win a lottery you didn't enter. Legitimate lotteries take taxes from your winnings, not before.",
      ],
      'romance': [
        "Romance scams target people looking for love online. Be suspicious if someone professes love quickly, has limited photos, or asks for money.",
        "Red flags in online dating: They avoid phone/video calls, their photos look too professional, or they have emergencies requiring money.",
      ],
      'tech support': [
        "Tech support scams involve callers claiming your computer is infected. Real companies like Microsoft don't make unsolicited calls about computer problems.",
        "Never give remote access to your computer to unsolicited callers. Legitimate tech support doesn't call you out of the blue.",
      ],
      'social security': [
        "Social Security scams threaten that your benefits will be suspended unless you pay immediately. SSA doesn't call threatening legal action.",
        "The Social Security Administration will never call demanding immediate payment or threatening arrest. These calls are always scams.",
      ],
      'medicare': [
        "Medicare scams often involve fake calls about new cards or benefits. Medicare will never call asking for personal information or payment.",
        "Be wary of Medicare scams offering 'free' medical equipment or services in exchange for your Medicare number.",
      ],
      'charity': [
        "Charity scams increase after disasters. Research charities before donating and be suspicious of high-pressure tactics.",
        "Legitimate charities give you time to think about donations. Be wary of charities that only accept cash, gift cards, or wire transfers.",
      ],
      'investment': [
        "Investment scams promise guaranteed returns with no risk. All investments carry risk - if it sounds too good to be true, it is.",
        "Red flags for investment scams: pressure to act immediately, promises of guaranteed profits, or requests for secrecy.",
      ],
    };

    final generalResponses = [
      "I'm here to help protect you from scams. What specific type of scam or suspicious activity are you concerned about?",
      "Great question! Staying informed about scams is the best protection. Is there a particular situation you'd like advice on?",
      "I can help you identify and avoid scams. What would you like to know about staying safe?",
    ];

    final greetings = [
      "Hello! I'm your SeniorShield assistant. I'm here to help you stay safe from scams and fraud. What can I help you with?",
      "Hi there! I specialize in helping people avoid scams and protect their personal information. How can I assist you today?",
      "Welcome! I'm here to help you recognize and avoid scams. What questions do you have about staying safe?",
    ];

    final goodbyes = [
      "Stay safe and remember: when in doubt, hang up and verify independently. Take care!",
      "Remember the golden rule: if something seems too good to be true, it probably is. Stay vigilant!",
      "Keep being cautious - it's your best defense against scammers. Have a safe day!",
    ];

    // Check for greetings
    if (userInput.contains(RegExp(r'\b(hello|hi|hey|good morning|good afternoon|good evening)\b'))) {
      return greetings[math.Random().nextInt(greetings.length)];
    }

    // Check for goodbyes
    if (userInput.contains(RegExp(r'\b(bye|goodbye|thanks|thank you|see you)\b'))) {
      return goodbyes[math.Random().nextInt(goodbyes.length)];
    }

    // Check for specific scam types
    for (final entry in scamKeywords.entries) {
      if (userInput.contains(entry.key)) {
        return entry.value[math.Random().nextInt(entry.value.length)];
      }
    }

    // Check for general scam-related keywords
    if (userInput.contains(RegExp(r'\b(scam|fraud|suspicious|call|email|text|money|payment|card|account|password|personal|information)\b'))) {
      final responses = [
        "That sounds like it could be a scam. Never give out personal information to unsolicited contacts. Can you tell me more details?",
        "Be very cautious! Scammers often use urgency and fear tactics. What specifically happened that made you suspicious?",
        "Trust your instincts - if something feels wrong, it probably is. Can you describe the situation in more detail?",
        "Red flags include: asking for personal info, demanding immediate action, or requesting unusual payment methods. What are you seeing?",
      ];
      return responses[math.Random().nextInt(responses.length)];
    }

    // Check for help requests
    if (userInput.contains(RegExp(r'\b(help|advice|what should|how do|can you)\b'))) {
      final helpResponses = [
        "I can help with identifying scams, protecting personal information, and reporting fraud. What specific situation are you dealing with?",
        "I'm here to help! I can provide advice on phone scams, email fraud, identity theft, and more. What's your concern?",
        "Absolutely! I can guide you through recognizing and avoiding various types of scams. What would you like to know about?",
      ];
      return helpResponses[math.Random().nextInt(helpResponses.length)];
    }

    // Default responses
    return generalResponses[math.Random().nextInt(generalResponses.length)];
  }
}