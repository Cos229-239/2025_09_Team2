import 'package:flutter/material.dart';
import '../services/social_learning_service.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile otherUser;
  final SocialLearningService socialService;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.socialService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadChatHistory() {
    // Mock chat history - in a real app, this would load from a database
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          senderId: widget.otherUser.id,
          senderName: widget.otherUser.displayName,
          message: 'Hey! Ready for our study session?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isMe: false,
        ),
        ChatMessage(
          id: '2',
          senderId: widget.socialService.currentUserProfile?.id ?? '',
          senderName:
              widget.socialService.currentUserProfile?.displayName ?? 'You',
          message: 'Yes! I\'ve prepared some notes. What time works for you?',
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
          isMe: true,
        ),
        ChatMessage(
          id: '3',
          senderId: widget.otherUser.id,
          senderName: widget.otherUser.displayName,
          message: 'How about 3 PM? We can meet in the virtual study room.',
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isMe: false,
        ),
        ChatMessage(
          id: '4',
          senderId: widget.socialService.currentUserProfile?.id ?? '',
          senderName:
              widget.socialService.currentUserProfile?.displayName ?? 'You',
          message: 'Perfect! See you at 3 PM 📚',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isMe: true,
        ),
      ]);
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: widget.otherUser.avatar != null
                  ? NetworkImage(widget.otherUser.avatar!)
                  : null,
              child: widget.otherUser.avatar == null
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : widget.otherUser.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.otherUser.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
          ),
          IconButton(
            onPressed: _startVoiceCall,
            icon: const Icon(Icons.call),
            tooltip: 'Voice Call',
          ),
          IconButton(
            onPressed: _showChatOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    child: Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.otherUser.displayName} is typing...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: !message.isMe
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isMe
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.7)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                'You'[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Attach',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: _onMessageChanged,
                minLines: 1,
                maxLines: 5,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed:
                  _messageController.text.trim().isEmpty ? null : _sendMessage,
              icon: Icon(
                Icons.send,
                color: _messageController.text.trim().isEmpty
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  void _onMessageChanged(String text) {
    // Simulate typing indicator
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });

      // Hide typing indicator after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      });
    }
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.socialService.currentUserProfile?.id ?? '',
      senderName: widget.socialService.currentUserProfile?.displayName ?? 'You',
      message: messageText,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate a response after 2-5 seconds
    Future.delayed(
      Duration(seconds: 2 + (DateTime.now().millisecond % 3)),
      () {
        if (mounted) {
          _simulateResponse(messageText);
        }
      },
    );
  }

  void _simulateResponse(String originalMessage) {
    List<String> responses = [
      'That sounds great! 📚',
      'I agree with you on that.',
      'Let me think about it...',
      'Good point! I hadn\'t considered that.',
      'Thanks for sharing that resource!',
      'Should we schedule a study session?',
      'I found a helpful video about this topic.',
      'Can you explain that concept again?',
      'This is really helpful, thanks!',
      'Let\'s review this together later.',
    ];

    // Generate contextual responses based on keywords
    String response;
    if (originalMessage.toLowerCase().contains('study')) {
      response =
          'Great! Let\'s set up a study session. What time works for you?';
    } else if (originalMessage.toLowerCase().contains('help')) {
      response = 'I\'d be happy to help! What do you need assistance with?';
    } else if (originalMessage.toLowerCase().contains('thanks')) {
      response = 'You\'re welcome! Happy to help anytime! 😊';
    } else {
      response = responses[DateTime.now().millisecond % responses.length];
    }

    final responseMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.otherUser.id,
      senderName: widget.otherUser.displayName,
      message: response,
      timestamp: DateTime.now(),
      isMe: false,
    );

    setState(() {
      _messages.add(responseMessage);
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _attachPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _attachVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _attachDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                Navigator.pop(context);
                _searchMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute Conversation'),
              onTap: () {
                Navigator.pop(context);
                _muteConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear Chat History'),
              onTap: () {
                Navigator.pop(context);
                _clearChatHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Starting video call with ${widget.otherUser.displayName} - Coming soon!'),
      ),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Starting voice call with ${widget.otherUser.displayName} - Coming soon!'),
      ),
    );
  }

  void _attachPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo attachment - Coming soon!')),
    );
  }

  void _attachVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video attachment - Coming soon!')),
    );
  }

  void _attachDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document attachment - Coming soon!')),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing - Coming soon!')),
    );
  }

  void _searchMessages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message search - Coming soon!')),
    );
  }

  void _muteConversation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation muted - Coming soon!')),
    );
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.otherUser.displayName}?'),
        content: const Text(
          'This user will no longer be able to send you messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Block user functionality - Coming soon!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });
}
