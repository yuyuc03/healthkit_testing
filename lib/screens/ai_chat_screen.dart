import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _userId = '';
  final String _aiName = 'Health Assistant';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _addInitialMessage();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id') ?? '';
      setState(() {
        _userId = userId;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Hello! I\'m your Health Assistant. How can I help you today?',
          isUserMessage: false,
        ),
      );
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUserMessage: true,
      ));
      _isLoading = true;
    });
    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.46:8000/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'message': userMessage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'] as String;

        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUserMessage: false,
          ));
        });
      } else {
        _addErrorMessage();
      }
    } catch (e) {
      print('Error getting AI response: $e');
      _addErrorMessage();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Sorry, I\'m having trouble connecting. Please try again later.',
        isUserMessage: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with Health Assistant',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[_messages.length - index - 1],
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).primaryColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(
                  hintText: 'Send a message',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: _isLoading
                  ? CircularProgressIndicator()
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.health_and_safety, color: Colors.white),
            ),
            SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUserMessage ? Colors.deepPurple : Color(0xFFEAE6FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUserMessage ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUserMessage) ...[
            SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text('Me', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
