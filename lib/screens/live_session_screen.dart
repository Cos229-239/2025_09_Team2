import 'package:flutter/material.dart';
import '../models/social_session.dart';

// TODO: Live Session Screen - Critical Video Calling Implementation Gaps
// - Current implementation is 100% FAKE - NO REAL VIDEO CALLING OR LIVE FEATURES
// - Need to implement real WebRTC integration for video/audio calling
// - Missing proper signaling server implementation for peer-to-peer connections
// - Need to implement real-time screen sharing capabilities
// - Missing integration with actual video/audio streaming services
// - Need to implement proper NAT traversal and STUN/TURN server support
// - Missing real-time collaborative whiteboard and drawing tools
// - Need to implement proper session management and participant controls
// - Missing integration with Firebase for real-time session state synchronization
// - Need to implement proper bandwidth adaptation and quality controls
// - Missing recording and playback functionality for study sessions
// - Need to implement proper audio/video device selection and management
// - Missing integration with calendar for session scheduling and reminders
// - Need to implement proper security and privacy controls for live sessions
// - Missing accessibility features for hearing/vision impaired participants
// - Need to implement proper error handling for connection failures
// - Missing integration with study materials sharing and synchronization
// - Need to implement proper session analytics and participation tracking

class LiveSessionScreen extends StatefulWidget {
  final SocialSession session;

  const LiveSessionScreen({
    super.key,
    required this.session,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Participant> _participants = [];
  bool _isMicEnabled = false;
  bool _isCameraEnabled = false;
  bool _isScreenSharing = false;
  String _currentTool = 'pen';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// TODO: MOCK DATA LOADING - REPLACE WITH REAL IMPLEMENTATION
  /// - Current method loads only hardcoded fake participants and messages
  /// - Need to implement real-time participant loading from Firebase/Firestore
  /// - Missing integration with user profiles and authentication
  /// - Need to implement real-time message synchronization across all participants
  /// - Missing proper participant permission and role management
  /// - Need to implement real participant status tracking (online/offline, audio/video state)
  /// - Missing integration with study session actual data and progress
  /// - Need to implement proper session history and message persistence
  void _loadMockData() {
    // Load mock participants
    _participants.addAll([
      Participant(
        id: '1',
        name: 'Alex Johnson',
        isHost: true,
        isMicOn: true,
        isCameraOn: true,
        isOnline: true,
      ),
      Participant(
        id: '2',
        name: 'Sarah Chen',
        isHost: false,
        isMicOn: false,
        isCameraOn: true,
        isOnline: true,
      ),
      Participant(
        id: '3',
        name: 'Mike Rodriguez',
        isHost: false,
        isMicOn: true,
        isCameraOn: false,
        isOnline: true,
      ),
    ]);

    // Load mock messages
    _messages.addAll([
      ChatMessage(
        id: '1',
        senderId: '1',
        senderName: 'Alex Johnson',
        message: 'Welcome everyone! Let\'s start with today\'s topic.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isHost: true,
      ),
      ChatMessage(
        id: '2',
        senderId: '2',
        senderName: 'Sarah Chen',
        message: 'Great! I have my notes ready.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isHost: false,
      ),
    ]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _toggleMic,
            icon: Icon(
              _isMicEnabled ? Icons.mic : Icons.mic_off,
              color: _isMicEnabled ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            onPressed: _toggleCamera,
            icon: Icon(
              _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
              color: _isCameraEnabled ? Colors.green : Colors.red,
            ),
          ),
          IconButton(
            onPressed: _toggleScreenShare,
            icon: Icon(
              Icons.screen_share,
              color: _isScreenSharing ? Colors.blue : Colors.grey,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Session Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'recording',
                child: ListTile(
                  leading: Icon(Icons.fiber_manual_record),
                  title: Text('Start Recording'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text('Leave Session',
                      style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text('LIVE'),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text('${_participants.length} participants'),
                const Spacer(),
                Text(
                  'Duration: ${_getSessionDuration()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Main content area with tabs
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Video', icon: Icon(Icons.videocam)),
                    Tab(text: 'Whiteboard', icon: Icon(Icons.draw)),
                    Tab(text: 'Chat', icon: Icon(Icons.chat)),
                    Tab(text: 'Participants', icon: Icon(Icons.people)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideoTab(),
                      _buildWhiteboardTab(),
                      _buildChatTab(),
                      _buildParticipantsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTab() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Main video area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isScreenSharing
                          ? 'Screen Sharing Active'
                          : 'No video stream',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Participant video grid
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                participant.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              participant.name.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Mic/Camera status
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!participant.isMicOn)
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic_off,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            if (!participant.isCameraOn)
                              Container(
                                margin: const EdgeInsets.only(left: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.videocam_off,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Host indicator
                      if (participant.isHost)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HOST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _buildToolButton('pen', Icons.edit, 'Pen'),
              _buildToolButton('eraser', Icons.cleaning_services, 'Eraser'),
              _buildToolButton('text', Icons.text_fields, 'Text'),
              _buildToolButton('shapes', Icons.crop_square, 'Shapes'),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _clearWhiteboard,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Whiteboard area
        Expanded(
          child: Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.draw,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Collaborative Whiteboard',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Draw, write, and collaborate in real-time',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton(String tool, IconData icon, String label) {
    final isSelected = _currentTool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _currentTool = tool),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: message.isHost
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                      child: Text(
                        message.senderName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                message.senderName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (message.isHost) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'HOST',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(message.message),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsTab() {
    return ListView.builder(
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  participant.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (participant.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Text(participant.name),
              if (participant.isHost) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Icon(
                participant.isMicOn ? Icons.mic : Icons.mic_off,
                size: 16,
                color: participant.isMicOn ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Icon(
                participant.isCameraOn ? Icons.videocam : Icons.videocam_off,
                size: 16,
                color: participant.isCameraOn ? Colors.green : Colors.red,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) =>
                _handleParticipantAction(action, participant),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.mic_off),
                  title: Text('Mute'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'message',
                child: ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Private Message'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!participant.isHost)
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.person_remove, color: Colors.red),
                    title: Text('Remove', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getSessionDuration() {
    // Mock duration calculation
    final duration = DateTime.now().difference(
      DateTime.now().subtract(const Duration(minutes: 15)),
    );
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMic() {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isMicEnabled ? 'Microphone enabled' : 'Microphone disabled'),
        backgroundColor: _isMicEnabled ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCameraEnabled ? 'Camera enabled' : 'Camera disabled'),
        backgroundColor: _isCameraEnabled ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isScreenSharing
            ? 'Screen sharing started'
            : 'Screen sharing stopped'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearWhiteboard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Whiteboard'),
        content: const Text(
            'Are you sure you want to clear the whiteboard? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Whiteboard cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'current_user',
            senderName: 'You',
            message: _messageController.text.trim(),
            timestamp: DateTime.now(),
            isHost: false,
          ),
        );
      });
      _messageController.clear();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session settings')),
        );
        break;
      case 'recording':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording started')),
        );
        break;
      case 'leave':
        _showLeaveSessionDialog();
        break;
    }
  }

  void _handleParticipantAction(String action, Participant participant) {
    switch (action) {
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${participant.name} muted')),
        );
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Private message to ${participant.name}')),
        );
        break;
      case 'remove':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${participant.name} removed from session')),
        );
        break;
    }
  }

  void _showLeaveSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session'),
        content:
            const Text('Are you sure you want to leave this live session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave session
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Left the session'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Data models for the live session
class Participant {
  final String id;
  final String name;
  final bool isHost;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isOnline;

  Participant({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isMicOn,
    required this.isCameraOn,
    required this.isOnline,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isHost;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isHost,
  });
}
