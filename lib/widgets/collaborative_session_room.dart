import 'package:flutter/material.dart';
import '../models/collaborative_session.dart';

class CollaborativeSessionRoom extends StatefulWidget {
  final CollaborativeSession session;
  final VoidCallback onLeave;

  const CollaborativeSessionRoom({
    super.key,
    required this.session,
    required this.onLeave,
  });

  @override
  State<CollaborativeSessionRoom> createState() =>
      _CollaborativeSessionRoomState();
}

class _CollaborativeSessionRoomState extends State<CollaborativeSessionRoom> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isScreenSharing = false;
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showParticipants,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Main content area (video/screen share)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Text(
                        'Video Stream',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                // Chat/participants sidebar
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildChat(),
                      ),
                      _buildChatInput(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildChat() {
    // Mock chat messages
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 0, // Replace with actual chat messages
      itemBuilder: (context, index) {
        return const SizedBox(); // Replace with actual chat message widget
      },
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
            onPressed: _toggleMute,
          ),
          IconButton(
            icon: Icon(_isVideoOn ? Icons.videocam : Icons.videocam_off),
            onPressed: _toggleVideo,
          ),
          IconButton(
            icon: const Icon(Icons.screen_share),
            onPressed: _toggleScreenShare,
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _toggleChat,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.call_end),
            label: const Text('Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: _leaveSession,
          ),
        ],
      ),
    );
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  // Replace with actual participants list
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoOn = !_isVideoOn);
  }

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
  }

  void _toggleChat() {
    // Implement chat toggle
  }

  void _sendMessage() {
    final message = _chatController.text.trim();
    if (message.isNotEmpty) {
      // Implement send message
      _chatController.clear();
    }
  }

  void _leaveSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session?'),
        content:
            const Text('Are you sure you want to leave this study session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave session
              widget.onLeave(); // Notify parent
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
