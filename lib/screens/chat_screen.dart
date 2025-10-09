import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/social_learning_service.dart';
import '../services/gif_service.dart';
import '../services/webrtc_service.dart';
import 'call_screen.dart';

/// Real-time chat screen with Discord-like features (reactions, GIFs, attachments)
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
  final ScrollController _scrollController = ScrollController();
  final GifService _gifService = GifService();
  final ImagePicker _imagePicker = ImagePicker();
  final WebRTCService _webrtcService = WebRTCService();

  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _previousMessageCount = 0;
  bool _hasScrolledToBottom = false;
  bool _weInitiatedCall = false; // Track if we started the call

  @override
  void initState() {
    super.initState();
    // Initialize WebRTC service
    _webrtcService.initialize();
    // Add listener to rebuild when text changes (for send button state)
    _messageController.addListener(_onTextChanged);
    // Listen for incoming calls
    _listenForIncomingCalls();
  }

  void _onTextChanged() {
    // Trigger rebuild when text changes to update send button color
    setState(() {});

    // Handle typing indicator
    if (_messageController.text.trim().isNotEmpty) {
      if (!_isCurrentlyTyping) {
        _isCurrentlyTyping = true;
        widget.socialService.updateTypingStatus(
          recipientId: widget.otherUser.id,
          isTyping: true,
        );
      }

      // Reset typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isCurrentlyTyping) {
          _isCurrentlyTyping = false;
          widget.socialService.updateTypingStatus(
            recipientId: widget.otherUser.id,
            isTyping: false,
          );
        }
      });
    } else {
      // Stop typing when text is cleared
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        _typingTimer?.cancel();
        widget.socialService.updateTypingStatus(
          recipientId: widget.otherUser.id,
          isTyping: false,
        );
      }
    }
  }

  @override
  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _webrtcService.dispose();

    // Clear typing status on exit
    if (_isCurrentlyTyping) {
      widget.socialService.updateTypingStatus(
        recipientId: widget.otherUser.id,
        isTyping: false,
      );
    }

    super.dispose();
  }

  /// Listen for incoming calls
  void _listenForIncomingCalls() {
    _webrtcService.callStateStream.listen((state) {
      if (state == CallState.ringing && mounted) {
        // Only show incoming call dialog if WE didn't initiate the call
        if (!_weInitiatedCall) {
          _showIncomingCallDialog();
        } else {
          debugPrint('ℹ️ Not showing incoming dialog - we initiated this call');
        }
      } else if (state == CallState.idle || state == CallState.ended) {
        // Reset the flag when call ends
        _weInitiatedCall = false;
      }
    });
  }

  /// Show incoming call dialog
  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _webrtcService.currentCallType == CallType.video
                  ? Icons.videocam
                  : Icons.call,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              _webrtcService.currentCallType == CallType.video
                  ? 'Incoming Video Call'
                  : 'Incoming Audio Call',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.otherUser.avatar != null
                  ? NetworkImage(widget.otherUser.avatar!)
                  : null,
              child: widget.otherUser.avatar == null
                  ? Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.otherUser.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _webrtcService.currentCallType == CallType.video
                  ? 'wants to video call you'
                  : 'wants to call you',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _webrtcService.endCall();
            },
            icon: const Icon(Icons.call_end, color: Colors.red),
            label: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              debugPrint('🎯 Answer button pressed - starting call answer flow');
              
              // Store the call details before any async operations
              final callId = _webrtcService.currentCallId;
              final callType = _webrtcService.currentCallType ?? CallType.audio;
              
              if (callId == null) {
                debugPrint('❌ No call ID found - cannot answer');
                Navigator.pop(context);
                return;
              }

              // Close the dialog first
              Navigator.pop(context);
              debugPrint('✅ Dialog closed, answering call...');

              // Answer the call - this will acquire media and set up the connection
              final success = await _webrtcService.answerCall(callId: callId);

              if (!success) {
                debugPrint('❌ Failed to answer call');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to answer call. Please check your camera and microphone permissions.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                return;
              }

              debugPrint('✅ Call answered successfully, preparing to navigate');

              // CRITICAL FIX: Wait for a full frame cycle to ensure:
              // 1. Dialog animation is complete
              // 2. Media tracks are properly established
              // 3. Widget tree is in a stable state
              if (mounted) {
                await Future.delayed(const Duration(milliseconds: 100));
                
                if (mounted) {
                  debugPrint('🧭 Navigating to CallScreen...');
                  
                  // Navigate to call screen with the answered call
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        webrtcService: _webrtcService,
                        otherUser: widget.otherUser,
                        isOutgoing: false,
                        callType: callType,
                      ),
                    ),
                  ).then((_) {
                    debugPrint('🔙 Returned from CallScreen');
                  });
                }
              }
            },
            icon: const Icon(Icons.call),
            label: const Text('Answer'),
          ),
        ],
      ),
    );
  }

  /// Start an audio call
  void _startAudioCall() async {
    _weInitiatedCall = true; // Mark that we started this call

    final success = await _webrtcService.startCall(
      recipientId: widget.otherUser.id,
      callType: CallType.audio,
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            webrtcService: _webrtcService,
            otherUser: widget.otherUser,
            isOutgoing: true,
            callType: CallType.audio,
          ),
        ),
      );
    } else {
      _weInitiatedCall = false; // Reset if failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to start audio call.\nPlease allow microphone access in your browser.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Start a video call
  void _startVideoCall() async {
    _weInitiatedCall = true; // Mark that we started this call

    final success = await _webrtcService.startCall(
      recipientId: widget.otherUser.id,
      callType: CallType.video,
    );

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            webrtcService: _webrtcService,
            otherUser: widget.otherUser,
            isOutgoing: true,
            callType: CallType.video,
          ),
        ),
      );
    } else {
      _weInitiatedCall = false; // Reset if failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to start video call.\nPlease allow camera and microphone access in your browser.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
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
                  // Real-time typing status
                  StreamBuilder<bool>(
                    stream: widget.socialService
                        .listenToTypingStatus(widget.otherUser.id),
                    builder: (context, snapshot) {
                      final isTyping = snapshot.data ?? false;

                      if (isTyping) {
                        return Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }

                      return Text(
                        widget.otherUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.otherUser.isOnline
                              ? Colors.green
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Audio call button
          IconButton(
            onPressed: _startAudioCall,
            icon: const Icon(Icons.call),
            tooltip: 'Audio Call',
          ),
          // Video call button
          IconButton(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
          ),
          // Menu button
          IconButton(
            onPressed: _showChatOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List (Real-time from Firestore)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  widget.socialService.listenToMessages(widget.otherUser.id),
              builder: (context, snapshot) {
                // Only show loading on FIRST load, not on every rebuild
                if (!snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start chatting!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom ONLY when:
                // 1. First load (haven't scrolled yet)
                // 2. New message arrives (message count increased)
                final currentMessageCount = messages.length;
                final shouldAutoScroll = !_hasScrolledToBottom ||
                    currentMessageCount > _previousMessageCount;

                if (shouldAutoScroll) {
                  // Schedule multiple scroll attempts to ensure we reach the bottom
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  _previousMessageCount = currentMessageCount;
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubbleWithReactions(message);
                  },
                );
              },
            ),
          ),

          // Upload Progress Indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: _uploadProgress / 100,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Uploading... ${_uploadProgress.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          // Discord-like Message Input Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment Button
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add attachment',
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Text Input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _messageController,
                      onChanged: _handleTyping,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message @${widget.otherUser.username}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // GIF Button
                IconButton(
                  onPressed: _showGifPicker,
                  icon: const Icon(Icons.gif_box_outlined),
                  tooltip: 'Send GIF',
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Emoji Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                  },
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                  ),
                  tooltip: 'Emoji',
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Send Button
                IconButton(
                  onPressed: _canSendMessage ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send',
                  color: _canSendMessage
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ],
            ),
          ),

          // Emoji Picker
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
                config: const Config(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubbleWithReactions(Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    final messageText = message['message'] as String? ?? '';
    final timestamp = message['timestamp'] as DateTime;
    final messageId = message['id'] as String;

    // Attachment data
    final attachmentUrl = message['attachmentUrl'] as String?;
    final attachmentType = message['attachmentType'] as String?;
    final attachmentName = message['attachmentName'] as String?;

    // Reactions data - convert to Map<String, dynamic> to handle LinkedMap from Firestore
    final reactionsRaw = message['reactions'];
    final reactions = reactionsRaw != null
        ? Map<String, dynamic>.from(reactionsRaw as Map)
        : <String, dynamic>{};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Message Content + Reactions
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message Bubble with Hover Reactions (Discord-style)
                _MessageBubbleWithHover(
                  isMe: isMe,
                  messageText: messageText,
                  timestamp: timestamp,
                  messageId: messageId,
                  attachmentUrl: attachmentUrl,
                  attachmentType: attachmentType,
                  attachmentName: attachmentName,
                  onQuickReact: (emoji) async {
                    await widget.socialService.addReaction(
                      otherUserId: widget.otherUser.id,
                      messageId: messageId,
                      emoji: emoji,
                    );
                  },
                  onLongPress: () => _showReactionPicker(messageId, isMe),
                  buildAttachment: _buildAttachment,
                  formatTimestamp: _formatTimestamp,
                ),

                // Reactions Display
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: reactions.entries.map((entry) {
                        final emoji = entry.key;
                        final userIds = List<String>.from(entry.value as List);
                        final currentUserId =
                            widget.socialService.currentUserId;
                        final hasReacted = currentUserId != null &&
                            userIds.contains(currentUserId);

                        return GestureDetector(
                          onTap: () async {
                            if (hasReacted) {
                              await widget.socialService.removeReaction(
                                otherUserId: widget.otherUser.id,
                                messageId: messageId,
                                emoji: emoji,
                              );
                            } else {
                              await widget.socialService.addReaction(
                                otherUserId: widget.otherUser.id,
                                messageId: messageId,
                                emoji: emoji,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasReacted
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                              border: hasReacted
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 1.5,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${userIds.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hasReacted
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAttachment(String url, String? type, String? name) {
    switch (type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 250,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 250,
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 250,
              height: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 48),
            ),
          ),
        );

      case 'gif':
        // Use Image.network for GIFs to ensure animation works
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 250,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 250,
                height: 150,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 250,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        );

      case 'sticker':
        return Image.network(
          url,
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        );

      case 'file':
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 32),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'File',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Open file in browser
                      },
                      child: const Text('Download'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  bool get _canSendMessage {
    return _messageController.text.trim().isNotEmpty && !_isUploading;
  }

  /// Scroll to the absolute bottom of the chat
  /// Uses multiple attempts to ensure we reach the very bottom after layout completes
  /// Especially important for GIFs and images that take time to load
  void _scrollToBottom() async {
    if (!_scrollController.hasClients || !mounted) return;

    // First immediate scroll
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

    // Multiple delayed scrolls to catch GIFs/images as they load and expand
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 100 + (i * 100)));
      if (_scrollController.hasClients && mounted) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }

    _hasScrolledToBottom = true;
  }

  void _showReactionPicker(String messageId, bool isMyMessage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'React to message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) async {
                  await widget.socialService.addReaction(
                    otherUserId: widget.otherUser.id,
                    messageId: messageId,
                    emoji: emoji.emoji,
                  );
                  if (mounted) Navigator.pop(context);
                },
                config: const Config(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final result = await widget.socialService.uploadAttachment(
        filePath: image.path,
        fileName: image.name,
        fileType: 'image',
        recipientId: widget.otherUser.id,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      await widget.socialService.sendEnhancedMessage(
        recipientId: widget.otherUser.id,
        attachmentUrl: result['url'],
        attachmentType: result['type'],
        attachmentName: result['name'],
        attachmentSize: result['size'],
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = result.files.first;
      if (file.path == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final uploadResult = await widget.socialService.uploadAttachment(
        filePath: file.path!,
        fileName: file.name,
        fileType: 'file',
        recipientId: widget.otherUser.id,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      await widget.socialService.sendEnhancedMessage(
        recipientId: widget.otherUser.id,
        attachmentUrl: uploadResult['url'],
        attachmentType: uploadResult['type'],
        attachmentName: uploadResult['name'],
        attachmentSize: uploadResult['size'],
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }

  void _showGifPicker() async {
    final gif = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GifPickerModal(gifService: _gifService),
    );

    if (gif != null) {
      await widget.socialService.sendEnhancedMessage(
        recipientId: widget.otherUser.id,
        attachmentUrl: gif,
        attachmentType: 'gif',
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately
    _messageController.clear();

    try {
      await widget.socialService.sendEnhancedMessage(
        recipientId: widget.otherUser.id,
        messageText: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _handleTyping(String text) {
    // Update typing status (Discord-like debouncing)
    if (text.isNotEmpty) {
      if (!_isCurrentlyTyping) {
        _isCurrentlyTyping = true;
        widget.socialService.updateTypingStatus(
          recipientId: widget.otherUser.id,
          isTyping: true,
        );
      }

      // Reset typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _isCurrentlyTyping = false;
        widget.socialService.updateTypingStatus(
          recipientId: widget.otherUser.id,
          isTyping: false,
        );
      });
    } else if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      widget.socialService.updateTypingStatus(
        recipientId: widget.otherUser.id,
        isTyping: false,
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement clear chat
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block user
              },
            ),
          ],
        ),
      ),
    );
  }
}

// GIF Picker Modal Widget
class _GifPickerModal extends StatefulWidget {
  final GifService gifService;

  const _GifPickerModal({required this.gifService});

  @override
  State<_GifPickerModal> createState() => _GifPickerModalState();
}

class _GifPickerModalState extends State<_GifPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<GifResult> _gifs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  Future<void> _loadTrendingGifs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gifs = await widget.gifService.getTrendingGifs();
      setState(() {
        _gifs = gifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gifs = await widget.gifService.searchGifs(query);
      setState(() {
        _gifs = gifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Choose a GIF',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search GIFs...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              filled: true,
            ),
            onSubmitted: _searchGifs,
          ),

          const SizedBox(height: 16),

          // GIF Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gifs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gif_box_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No GIFs found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tenor API may still be initializing\n(usually takes 5-10 minutes after enabling)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadTrendingGifs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _gifs.length,
                        itemBuilder: (context, index) {
                          final gif = _gifs[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, gif.fullUrl);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                gif.previewUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Discord-style Message Bubble with Hover Reactions
class _MessageBubbleWithHover extends StatefulWidget {
  final bool isMe;
  final String messageText;
  final DateTime timestamp;
  final String messageId;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;
  final Function(String emoji) onQuickReact;
  final VoidCallback onLongPress;
  final Widget Function(String url, String? type, String? name) buildAttachment;
  final String Function(DateTime timestamp) formatTimestamp;

  const _MessageBubbleWithHover({
    required this.isMe,
    required this.messageText,
    required this.timestamp,
    required this.messageId,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    required this.onQuickReact,
    required this.onLongPress,
    required this.buildAttachment,
    required this.formatTimestamp,
  });

  @override
  State<_MessageBubbleWithHover> createState() =>
      _MessageBubbleWithHoverState();
}

class _MessageBubbleWithHoverState extends State<_MessageBubbleWithHover> {
  bool _isHovering = false;

  // Discord's most common quick reactions
  static const List<String> _quickReactions = [
    '😂',
    '👍',
    '❤️',
    '😮',
    '😢',
    '🔥'
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        // Add padding at the top to ensure MouseRegion covers the reaction bar area
        padding: const EdgeInsets.only(top: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Message Bubble
            GestureDetector(
              onLongPress: widget.onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attachment (if present)
                    if (widget.attachmentUrl != null) ...[
                      widget.buildAttachment(
                        widget.attachmentUrl!,
                        widget.attachmentType,
                        widget.attachmentName,
                      ),
                      if (widget.messageText.isNotEmpty)
                        const SizedBox(height: 8),
                    ],

                    // Text Message
                    if (widget.messageText.isNotEmpty)
                      Text(
                        widget.messageText,
                        style: TextStyle(
                          fontSize: 15,
                          color: widget.isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      widget.formatTimestamp(widget.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isMe
                            ? Colors.white70
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

            // Discord-style Quick Reaction Bar (appears on hover)
            if (_isHovering)
              Positioned(
                top: -20,
                right: widget.isMe ? 0 : null,
                left: widget.isMe ? null : 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quick reaction emojis
                      ..._quickReactions.map((emoji) => _QuickReactionButton(
                            emoji: emoji,
                            onTap: () => widget.onQuickReact(emoji),
                          )),

                      // Divider
                      Container(
                        width: 1,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: Theme.of(context).dividerColor,
                      ),

                      // More reactions button (opens full picker)
                      InkWell(
                        onTap: widget.onLongPress,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add_reaction_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Quick Reaction Button Widget
class _QuickReactionButton extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const _QuickReactionButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  State<_QuickReactionButton> createState() => _QuickReactionButtonState();
}

class _QuickReactionButtonState extends State<_QuickReactionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovering
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.emoji,
            style: TextStyle(
              fontSize: _isHovering ? 22 : 20,
            ),
          ),
        ),
      ),
    );
  }
}
