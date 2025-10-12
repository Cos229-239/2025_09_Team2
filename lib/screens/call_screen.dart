import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../services/social_learning_service.dart' as service;

class CallScreen extends StatefulWidget {
  final WebRTCService webrtcService;
  final service.UserProfile otherUser;
  final bool isOutgoing;
  final CallType callType;

  const CallScreen({
    super.key,
    required this.webrtcService,
    required this.otherUser,
    required this.isOutgoing,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true; // Speaker is on by default for calls
  bool _isScreenSharing = false;
  CallState _callState = CallState.idle;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _setupListeners();
    _enableSpeaker(); // Enable speaker by default for calls
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  /// Enable speaker by default when call starts
  Future<void> _enableSpeaker() async {
    try {
      await Helper.setSpeakerphoneOn(true);
      debugPrint('🔊 Speaker enabled by default');
    } catch (e) {
      debugPrint('❌ Error enabling speaker on init: $e');
    }
  }

  void _setupListeners() {
    // Listen to call state
    widget.webrtcService.callStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _callState = state;
        });

        // Auto-close screen when call ends
        if (state == CallState.ended) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });

    // Listen to remote stream
    widget.webrtcService.remoteStreamStream.listen((stream) {
      if (mounted && stream != null) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    });

    // Listen to local stream
    widget.webrtcService.localStreamStream.listen((stream) {
      if (mounted && stream != null) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing CallScreen...');

    // Dispose renderers first to release video tracks
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    debugPrint('✅ CallScreen disposed');
    super.dispose();
  }

  void _toggleMute() async {
    await widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleCamera() async {
    await widget.webrtcService.toggleCamera();
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  void _switchCamera() async {
    await widget.webrtcService.switchCamera();
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    // Enable/disable speaker phone using flutter_webrtc Helper
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
      debugPrint('🔊 Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error toggling speaker: $e');
      // Revert state if error occurs
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    }
  }

  void _toggleScreenShare() async {
    if (_isScreenSharing) {
      await widget.webrtcService.disableScreenSharing();
    } else {
      await widget.webrtcService.enableScreenSharing();
    }
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
  }

  void _endCall() async {
    await widget.webrtcService.endCall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (widget.callType == CallType.video)
              Positioned.fill(
                child: _callState == CallState.connected &&
                        _remoteRenderer.srcObject != null
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      )
                    : _buildWaitingView(),
              )
            else
              // Audio call - show avatar
              Positioned.fill(
                child: _buildAudioCallView(),
              ),

            // Local video (small preview in corner) - only for video calls
            if (widget.callType == CallType.video &&
                _localRenderer.srcObject != null)
              Positioned(
                top: 40,
                right: 20,
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),

            // Top bar with user info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.otherUser.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCallStateText(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom control bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _buildControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              backgroundImage: widget.otherUser.avatar != null
                  ? NetworkImage(widget.otherUser.avatar!)
                  : null,
              child: widget.otherUser.avatar == null
                  ? Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 30),
            if (_callState == CallState.connecting ||
                _callState == CallState.ringing)
              const CircularProgressIndicator(
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCallView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.otherUser.avatar != null
                  ? NetworkImage(widget.otherUser.avatar!)
                  : null,
              child: widget.otherUser.avatar == null
                  ? Text(
                      widget.otherUser.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 40),
            if (_callState == CallState.connecting ||
                _callState == CallState.ringing)
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            if (_callState == CallState.connected)
              Icon(
                Icons.headset,
                size: 48,
                color: Colors.white.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final List<Widget> controls = [];

    // Mute button
    controls.add(
      _buildControlButton(
        icon: _isMuted ? Icons.mic_off : Icons.mic,
        label: _isMuted ? 'Unmute' : 'Mute',
        onPressed: _toggleMute,
        backgroundColor:
            _isMuted ? Colors.red : Colors.white.withValues(alpha: 0.3),
      ),
    );

    // Speaker button (for all call types)
    controls.add(
      _buildControlButton(
        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
        label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
        onPressed: _toggleSpeaker,
        backgroundColor:
            _isSpeakerOn ? Colors.blue : Colors.white.withValues(alpha: 0.3),
      ),
    );

    // Camera button (video calls only)
    if (widget.callType == CallType.video) {
      controls.add(
        _buildControlButton(
          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: _isCameraOff ? 'Camera Off' : 'Camera On',
          onPressed: _toggleCamera,
          backgroundColor:
              _isCameraOff ? Colors.red : Colors.white.withValues(alpha: 0.3),
        ),
      );
    }

    // Screen share button (video calls only)
    if (widget.callType == CallType.video) {
      controls.add(
        _buildControlButton(
          icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
          label: _isScreenSharing ? 'Stop Share' : 'Share Screen',
          onPressed: _toggleScreenShare,
          backgroundColor: _isScreenSharing
              ? Colors.green
              : Colors.white.withValues(alpha: 0.3),
        ),
      );
    }

    // Switch camera button (video calls only, when camera is on)
    if (widget.callType == CallType.video && !_isCameraOff) {
      controls.add(
        _buildControlButton(
          icon: Icons.cameraswitch,
          label: 'Switch',
          onPressed: _switchCamera,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
        ),
      );
    }

    // End call button
    controls.add(
      _buildControlButton(
        icon: Icons.call_end,
        label: 'End Call',
        onPressed: _endCall,
        backgroundColor: Colors.red,
        isEndCall: true,
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: controls,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(isEndCall ? 20 : 16),
              child: Icon(
                icon,
                color: Colors.white,
                size: isEndCall ? 32 : 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getCallStateText() {
    switch (_callState) {
      case CallState.connecting:
        return 'Connecting...';
      case CallState.ringing:
        return widget.isOutgoing ? 'Ringing...' : 'Incoming call...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      case CallState.error:
        return 'Connection error';
      default:
        return '';
    }
  }
}
