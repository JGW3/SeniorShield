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

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.sender == Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[400] : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakingEnabled = !_isSpeakingEnabled;
    });
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
    return Scaffold(
      appBar: AppBar(title: Text('Chat with Bot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildBubble(message);
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Type or use voice input...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: _isSpeakingEnabled ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _toggleSpeaker,
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isSending ? null : () => _sendMessage(),
                  color: _isSending ? Colors.grey : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
