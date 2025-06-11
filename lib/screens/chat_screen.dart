import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  final String username;

  ChatScreen({required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isSpeakingEnabled = false;
  bool _isSending = false;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late ChatService _chatService;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.username);
    _loadHistory();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <=
          _scrollController.position.minScrollExtent + 50) {
        _loadHistory(loadMore: true);
      }
    });

    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _loadHistory({bool loadMore = false}) async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final history = await _chatService.fetchRecentHistory(offset: _offset);

    setState(() {
      _messages.insertAll(0, history);
      _offset += history.length;
      _isLoadingMore = false;
      if (history.isEmpty) _hasMore = false;
    });
  }

  void _sendMessage({bool isVoice = false}) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(text: text, sender: Sender.user));
      _controller.clear();
    });

    _scrollToBottom();

    final botReplies = await _chatService.sendMessage(text);

    setState(() {
      _messages.addAll(botReplies);
      _isSending = false;
    });

    if (_isSpeakingEnabled && botReplies.isNotEmpty) {
      for (var msg in botReplies) {
        if (msg.sender == Sender.bot) {
          await _flutterTts.speak(msg.text);
        }
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakingEnabled = !_isSpeakingEnabled;
    });
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.sender == Sender.user;
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceVariant;
    final textColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isUser ? Radius.circular(20) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(fontSize: 20, color: textColor), // Larger font size
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat with Bot',
          style: TextStyle(fontSize: 28), // Larger title size
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: const EdgeInsets.all(16), // Increased padding for larger targets
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildBubble(message);
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Increased padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 22, // Larger font size
                      color: colorScheme.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type or use voice input...',
                      hintStyle: TextStyle(fontSize: 18, color: colorScheme.onBackground.withOpacity(0.5)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Larger padding
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    IconButton(
                      iconSize: 40, // Larger button size
                      tooltip: 'Toggle Voice Output',
                      icon: Icon(
                        Icons.volume_up,
                        color: _isSpeakingEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                      onPressed: _toggleSpeaker,
                    ),
                    IconButton(
                      iconSize: 40, // Larger button size
                      tooltip: 'Send Message',
                      icon: Icon(Icons.send),
                      onPressed: _isSending ? null : () => _sendMessage(),
                      color: _isSending
                          ? colorScheme.onSurface.withOpacity(0.4)
                          : colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
