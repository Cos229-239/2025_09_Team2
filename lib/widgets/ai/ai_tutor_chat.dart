import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';

/// AI Study Assistant Chat Widget
class AITutorChat extends StatefulWidget {
  const AITutorChat({super.key});

  @override
  State<AITutorChat> createState() => _AITutorChatState();
}

class _AITutorChatState extends State<AITutorChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
    });
    
    // Add typing indicator
    setState(() {
      _messages.add(ChatMessage(
        text: "AI is thinking...",
        isFromUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
      ));
    });
    
    // Get AI response (simplified for now)
    final aiProvider = Provider.of<StudyPalsAIProvider>(context, listen: false);
    final response = await _getAIResponse(userMessage, aiProvider);
    
    setState(() {
      // Remove typing indicator
      _messages.removeWhere((msg) => msg.isTyping);
      // Add AI response
      _messages.add(ChatMessage(
        text: response,
        isFromUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }
  
  Future<String> _getAIResponse(String message, StudyPalsAIProvider aiProvider) async {
    // This is a simplified AI response - you can enhance this
    if (message.toLowerCase().contains('study tip')) {
      return await aiProvider.getStudyRecommendation(
        // You'll need to pass actual user and stats
        null as dynamic, // Replace with actual user
        {'cardsToday': 10, 'successRate': 85, 'streak': 5, 'weakSubjects': ['Math']},
      );
    } else if (message.toLowerCase().contains('motivation')) {
      return await aiProvider.getPetMessage(
        'Buddy', // Replace with actual pet name
        {'cardsToday': 10, 'successRate': 85},
      );
    } else {
      return "I'm here to help with your studies! Ask me for study tips, motivation, or help creating flashcards.";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<StudyPalsAIProvider>(
      builder: (context, aiProvider, child) {
        if (!aiProvider.isAIEnabled) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'AI Tutor Not Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configure AI settings to enable the study assistant',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Study Assistant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              // Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              
              // Input area
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask for study help...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isFromUser
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: message.isTyping
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI is thinking...'),
                ],
              )
            : Text(
                message.text,
                style: TextStyle(
                  color: message.isFromUser ? Colors.white : Colors.black87,
                ),
              ),
      ),
    );
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isTyping;
  
  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isTyping = false,
  });
}
