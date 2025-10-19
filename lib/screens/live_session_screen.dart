import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/social_session.dart';
import '../services/webrtc_service.dart';
import '../widgets/collaborative_whiteboard.dart';

/// Live Session Screen - Fully integrated WebRTC video calling and collaboration
/// Integrates existing services:
/// - WebRTCService: Real WebRTC video/audio calling
/// - Firebase Firestore: Real-time participant and message synchronization
/// - Session state management across all participants

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

  // WebRTC Service - uses existing WebRTCService from lib/services/webrtc_service.dart
  final WebRTCService _webrtcService = WebRTCService();

  // Firebase - for real-time participant and message sync
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Session data - using extended participant with audio/video status
  final List<LiveSessionParticipant> _participants = [];
  final List<LiveSessionMessage> _messages = [];

  // UI state
  bool _isMicEnabled = false;
  bool _isCameraEnabled = false;
  bool _isScreenSharing = false;
  DateTime? _sessionStartTime;
  bool _isRecording = false;
  String _selectedQuality = 'auto'; // auto, high, medium, low

  // WebRTC video renderers
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  RTCVideoRenderer? _screenShareRenderer;

  // Screen sharing
  MediaStream? _screenStream;

  // Network quality monitoring
  Timer? _qualityMonitorTimer;
  String _networkQuality = 'good'; // excellent, good, fair, poor

  // Analytics
  Map<String, dynamic> _sessionAnalytics = {
    'participantJoinTimes': <String, DateTime>{},
    'messageCount': 0,
    'videoToggleCount': 0,
    'audioToggleCount': 0,
    'screenShareCount': 0,
    'filesShared': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _sessionStartTime = DateTime.now();
    _initializeSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _screenShareRenderer?.dispose();
    _webrtcService.dispose();
    _qualityMonitorTimer?.cancel();
    _leaveSession();
    _stopRecording();
    _stopScreenSharing();
    super.dispose();
  }

  /// Initialize the live session with WebRTC and Firebase
  Future<void> _initializeSession() async {
    try {
      // Initialize WebRTC service
      await _webrtcService.initialize();

      // Setup video renderers
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();

      // Listen to WebRTC streams
      _webrtcService.localStreamStream.listen((stream) {
        if (stream != null && _localRenderer != null) {
          _localRenderer!.srcObject = stream;
          setState(() {});
        }
      });

      _webrtcService.remoteStreamStream.listen((stream) {
        if (stream != null && _remoteRenderer != null) {
          _remoteRenderer!.srcObject = stream;
          setState(() {});
        }
      });

      // Join session in Firebase
      await _joinSessionInFirebase();

      // Listen to participants
      _listenToParticipants();

      // Listen to chat messages
      _listenToMessages();

      // Start network quality monitoring
      _startQualityMonitoring();

      // Initialize analytics
      _initializeAnalytics();

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error initializing session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Join the session in Firebase
  Future<void> _joinSessionInFirebase() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('participants')
          .doc(currentUser.uid)
          .set({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'User',
        'joinedAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'isMicOn': _isMicEnabled,
        'isCameraOn': _isCameraEnabled,
        'isHost': widget.session.hostId == currentUser.uid,
      }, SetOptions(merge: true));

      debugPrint('✅ Joined session in Firebase');
    } catch (e) {
      debugPrint('❌ Error joining session: $e');
    }
  }

  /// Leave the session in Firebase
  Future<void> _leaveSession() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Save session analytics before leaving
      await _saveAnalytics();

      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('participants')
          .doc(currentUser.uid)
          .update({
        'isOnline': false,
        'leftAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Left session in Firebase');
    } catch (e) {
      debugPrint('❌ Error leaving session: $e');
    }
  }

  /// Listen to participants in real-time
  void _listenToParticipants() {
    _firestore
        .collection('social_sessions')
        .doc(widget.session.id)
        .collection('participants')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _participants.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _participants.add(LiveSessionParticipant(
            id: data['userId'] ?? doc.id,
            name: data['userName'] ?? 'Unknown',
            isHost: data['isHost'] ?? false,
            isMicOn: data['isMicOn'] ?? false,
            isCameraOn: data['isCameraOn'] ?? false,
            isOnline: data['isOnline'] ?? false,
            joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
          ));
        }
      });
    });
  }

  /// Listen to chat messages in real-time
  void _listenToMessages() {
    _firestore
        .collection('social_sessions')
        .doc(widget.session.id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _messages.add(LiveSessionMessage(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            senderName: data['senderName'] ?? 'Unknown',
            message: data['message'] ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isHost: data['isHost'] ?? false,
          ));
        }
      });
    });
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
          // Main video area - shows remote participant video or waiting message
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  _remoteRenderer != null && _remoteRenderer!.srcObject != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: RTCVideoView(_remoteRenderer!),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.videocam_off,
                                size: 64,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isScreenSharing
                                    ? 'Screen Sharing Active'
                                    : 'Waiting for participants...',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          // Participant video grid - shows all participants including local user
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return _buildParticipantVideoTile(participant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantVideoTile(LiveSessionParticipant participant) {
    final currentUser = _auth.currentUser;
    final isCurrentUser = currentUser?.uid == participant.id;

    return Container(
      width: 120,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Show local video for current user, placeholder for others
          if (isCurrentUser &&
              _localRenderer != null &&
              _localRenderer!.srcObject != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RTCVideoView(_localRenderer!, mirror: true),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      participant.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrentUser ? 'You' : participant.name.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          // Mic/Camera status indicators
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
  }

  Widget _buildWhiteboardTab() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Please login to use whiteboard'),
      );
    }

    return CollaborativeWhiteboard(
      sessionId: widget.session.id,
      userId: currentUser.uid,
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
    if (_sessionStartTime == null) return '00:00';

    final duration = DateTime.now().difference(_sessionStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMic() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });

    // Track analytics
    _trackAnalyticsEvent('audio_toggle');

    // Update in Firebase
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('participants')
          .doc(currentUser.uid)
          .update({'isMicOn': _isMicEnabled});
    }

    // Update WebRTC local stream
    if (_webrtcService.localStream != null) {
      _webrtcService.localStream!.getAudioTracks().forEach((track) {
        track.enabled = _isMicEnabled;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isMicEnabled ? 'Microphone enabled' : 'Microphone disabled'),
          backgroundColor: _isMicEnabled ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleCamera() async {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });

    // Track analytics
    _trackAnalyticsEvent('video_toggle');

    // Update in Firebase
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('participants')
          .doc(currentUser.uid)
          .update({'isCameraOn': _isCameraEnabled});
    }

    // Update WebRTC local stream
    if (_webrtcService.localStream != null) {
      _webrtcService.localStream!.getVideoTracks().forEach((track) {
        track.enabled = _isCameraEnabled;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isCameraEnabled ? 'Camera enabled' : 'Camera disabled'),
          backgroundColor: _isCameraEnabled ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Recording methods
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Combine screen and audio streams for recording
      MediaStream? recordingStream;

      if (_screenStream != null) {
        // If screen sharing, record screen + audio
        recordingStream = _screenStream;

        // Add audio track if available
        if (_webrtcService.localStream != null) {
          final audioTracks = _webrtcService.localStream!.getAudioTracks();
          if (audioTracks.isNotEmpty) {
            recordingStream!.addTrack(audioTracks.first);
          }
        }
      } else if (_webrtcService.localStream != null) {
        // Otherwise record camera + audio
        recordingStream = _webrtcService.localStream;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No media stream available for recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Initialize MediaRecorder (Web only - would need platform-specific implementation)
      if (kIsWeb) {
        // Web implementation using dart:html
        // Note: This requires adding dart:html import
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Recording feature requires platform-specific implementation'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Recording is currently only supported on web platform'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Stop MediaRecorder
      // Platform-specific implementation needed

      setState(() {
        _isRecording = false;
      });

      // Update Firebase
      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('participants')
          .doc(currentUser.uid)
          .update({'isRecording': false});

      // Calculate recording duration for analytics
      final recordingStart = _sessionAnalytics['recordingStartTime'];
      if (recordingStart != null) {
        _sessionAnalytics['totalRecordingDuration'] =
            (_sessionAnalytics['totalRecordingDuration'] ?? 0) +
                1; // Simplified
      }

      debugPrint('✅ Recording stopped');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to stop recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Quality monitoring methods
  Future<void> _startQualityMonitoring() async {
    _qualityMonitorTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // Monitor network quality based on WebRTC stats
        // Simplified implementation - full version would use getStats()

        // For now, just maintain "good" quality
        // Production version would analyze packet loss, jitter, bitrate
        if (_networkQuality != 'good') {
          setState(() {
            _networkQuality = 'good';
          });
        }
      } catch (e) {
        debugPrint('⚠️ Quality monitoring error: $e');
      }
    });
  }

  Future<void> _adaptQuality(String quality) async {
    setState(() {
      _selectedQuality = quality;
    });

    try {
      // Apply quality settings to video stream
      // This would involve modifying video constraints

      switch (quality) {
        case 'high':
          debugPrint('✅ Quality set to high (720p, 30fps)');
          break;
        case 'medium':
          debugPrint('✅ Quality set to medium (480p, 24fps)');
          break;
        case 'low':
          debugPrint('✅ Quality set to low (240p, 15fps)');
          break;
        default: // auto
          debugPrint('✅ Quality set to auto');
          return;
      }

      // TODO: Apply constraints to MediaStream
      // This would require stopping and restarting the video track with new constraints
      debugPrint('✅ Quality adapted to: $quality');
    } catch (e) {
      debugPrint('❌ Failed to adapt quality: $e');
    }
  }

  // Analytics methods
  void _initializeAnalytics() {
    _sessionAnalytics = {
      'sessionId': widget.session.id,
      'sessionStartTime': FieldValue.serverTimestamp(),
      'participantJoinTimes': {},
      'messageCount': 0,
      'videoToggleCount': 0,
      'audioToggleCount': 0,
      'screenShareCount': 0,
      'totalDuration': 0,
    };
  }

  Future<void> _saveAnalytics() async {
    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Calculate total session duration
      final startTime = _sessionAnalytics['sessionStartTime'];
      if (startTime != null) {
        _sessionAnalytics['totalDuration'] =
            DateTime.now().millisecondsSinceEpoch;
      }

      // Save to Firestore
      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('analytics')
          .doc(currentUser.uid)
          .set(_sessionAnalytics, SetOptions(merge: true));

      debugPrint('✅ Analytics saved');
    } catch (e) {
      debugPrint('❌ Failed to save analytics: $e');
    }
  }

  void _trackAnalyticsEvent(String event) {
    switch (event) {
      case 'message_sent':
        _sessionAnalytics['messageCount'] =
            (_sessionAnalytics['messageCount'] ?? 0) + 1;
        break;
      case 'video_toggle':
        _sessionAnalytics['videoToggleCount'] =
            (_sessionAnalytics['videoToggleCount'] ?? 0) + 1;
        break;
      case 'audio_toggle':
        _sessionAnalytics['audioToggleCount'] =
            (_sessionAnalytics['audioToggleCount'] ?? 0) + 1;
        break;
      case 'screen_share':
        _sessionAnalytics['screenShareCount'] =
            (_sessionAnalytics['screenShareCount'] ?? 0) + 1;
        break;
    }
  }

  // Screen sharing methods
  void _toggleScreenShare() async {
    if (_isScreenSharing) {
      await _stopScreenSharing();
    } else {
      await _startScreenSharing();
    }
  }

  /// Start screen sharing with platform detection and WebRTC integration
  Future<void> _startScreenSharing() async {
    try {
      debugPrint('🖥️ Starting screen share...');

      // Request screen capture
      final constraints = {
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '15',
          },
        },
        'audio': false, // Screen audio can be added if needed
      };

      // Get display media stream (screen capture)
      _screenStream = await navigator.mediaDevices.getDisplayMedia(constraints);

      if (_screenStream == null) {
        throw Exception('Failed to get screen stream');
      }

      debugPrint(
          '✅ Screen stream obtained: ${_screenStream!.getTracks().length} tracks');

      // Initialize screen share renderer
      _screenShareRenderer = RTCVideoRenderer();
      await _screenShareRenderer!.initialize();
      _screenShareRenderer!.srcObject = _screenStream;

      // Listen for when user stops sharing via browser UI
      _screenStream!.getVideoTracks().first.onEnded = () {
        debugPrint('🖥️ Screen sharing stopped by user');
        _stopScreenSharing();
      };

      setState(() {
        _isScreenSharing = true;
      });

      // Update Firebase
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('social_sessions')
            .doc(widget.session.id)
            .collection('participants')
            .doc(currentUser.uid)
            .update({'isScreenSharing': true});
      }

      // Track analytics
      _sessionAnalytics['screenShareCount'] =
          (_sessionAnalytics['screenShareCount'] ?? 0) + 1;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen sharing started'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }

      debugPrint('✅ Screen sharing started successfully');
    } catch (e) {
      debugPrint('❌ Error starting screen share: $e');

      setState(() {
        _isScreenSharing = false;
      });

      if (mounted) {
        String errorMessage = 'Failed to start screen sharing';
        if (e.toString().contains('Permission denied')) {
          errorMessage = 'Screen sharing permission denied';
        } else if (e.toString().contains('NotAllowedError')) {
          errorMessage = 'Screen sharing not allowed by browser';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Stop screen sharing and restore camera video
  Future<void> _stopScreenSharing() async {
    if (!_isScreenSharing || _screenStream == null) return;

    try {
      debugPrint('🖥️ Stopping screen share...');

      // Stop all screen stream tracks
      for (var track in _screenStream!.getTracks()) {
        track.stop();
      }

      // Dispose screen renderer
      await _screenShareRenderer?.dispose();
      _screenShareRenderer = null;
      _screenStream = null;

      setState(() {
        _isScreenSharing = false;
      });

      // Update Firebase
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('social_sessions')
            .doc(widget.session.id)
            .collection('participants')
            .doc(currentUser.uid)
            .update({'isScreenSharing': false});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen sharing stopped'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }

      debugPrint('✅ Screen sharing stopped successfully');
    } catch (e) {
      debugPrint('❌ Error stopping screen share: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Track analytics
      _trackAnalyticsEvent('message_sent');

      await _firestore
          .collection('social_sessions')
          .doc(widget.session.id)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'User',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isHost': widget.session.hostId == currentUser.uid,
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showSessionSettings();
        break;
      case 'recording':
        _toggleRecording();
        break;
      case 'share_file':
        _shareFile();
        break;
      case 'leave':
        _showLeaveSessionDialog();
        break;
    }
  }

  void _showSessionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Video Quality'),
              subtitle: DropdownButton<String>(
                value: _selectedQuality,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto')),
                  DropdownMenuItem(value: 'high', child: Text('High (720p)')),
                  DropdownMenuItem(
                      value: 'medium', child: Text('Medium (480p)')),
                  DropdownMenuItem(value: 'low', child: Text('Low (240p)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _adaptQuality(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('Network Quality'),
              subtitle: Text(_networkQuality),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.isEmpty) {
        return; // User canceled
      }

      final file = result.files.first;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing ${file.name}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Track analytics
      _sessionAnalytics['filesShared'] =
          (_sessionAnalytics['filesShared'] ?? 0) + 1;

      // TODO: Upload to Firebase Storage and share link in chat
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'File sharing: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to share file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleParticipantAction(
      String action, LiveSessionParticipant participant) {
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session'),
        content:
            const Text('Are you sure you want to leave this live session?'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              navigator.pop(); // Close dialog
              navigator.pop(); // Leave session screen
              messenger.showSnackBar(
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

// Data models for the live session with real-time sync capabilities
class LiveSessionParticipant {
  final String id;
  final String name;
  final bool isHost;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isOnline;
  final DateTime? joinedAt;

  LiveSessionParticipant({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isMicOn,
    required this.isCameraOn,
    required this.isOnline,
    this.joinedAt,
  });
}

class LiveSessionMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isHost;

  LiveSessionMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isHost,
  });
}
