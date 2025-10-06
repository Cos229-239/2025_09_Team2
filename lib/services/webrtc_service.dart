import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum for call types
enum CallType {
  audio,
  video,
}

/// Enum for call state
enum CallState {
  idle,
  connecting,
  ringing,
  connected,
  ended,
  error,
}

/// WebRTC service for managing audio/video calls
class WebRTCService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // WebRTC peer connection
  RTCPeerConnection? _peerConnection;
  
  // Media streams
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Call state
  CallState _callState = CallState.idle;
  CallType? _currentCallType;
  String? _currentCallId;
  String? _otherUserId;
  
  // Stream controllers for state updates
  final _callStateController = StreamController<CallState>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  
  // ICE candidate subscription
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _callStateSubscription;
  StreamSubscription? _incomingCallSubscription;
  
  // ICE candidate queue (for candidates received before remote description is set)
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _remoteDescriptionSet = false;
  
  // Connection timeout
  Timer? _connectionTimeoutTimer;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  
  // Getters
  CallState get callState => _callState;
  CallType? get currentCallType => _currentCallType;
  String? get currentCallId => _currentCallId;
  String? get otherUserId => _otherUserId;
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  
  // Configuration for STUN/TURN servers
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
      // Free TURN servers for testing (replace with your own for production)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };
  
  // Media constraints
  final Map<String, dynamic> _audioConstraints = {
    'audio': true,
    'video': false,
  };
  
  final Map<String, dynamic> _videoConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };
  
  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('🎥 Initializing WebRTC service...');
    _listenForIncomingCalls();
  }
  
  /// Update call state
  void _updateCallState(CallState newState) {
    _callState = newState;
    _callStateController.add(newState);
    debugPrint('📞 Call state updated: $newState');
  }
  
  /// Start a call (audio or video)
  Future<bool> startCall({
    required String recipientId,
    required CallType callType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot start call: Not authenticated');
        return false;
      }
      
      _updateCallState(CallState.connecting);
      _currentCallType = callType;
      _otherUserId = recipientId;
      _remoteDescriptionSet = false;
      _pendingIceCandidates.clear();
      
      // Generate call ID
      _currentCallId = '${currentUser.uid}_${recipientId}_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('📞 Starting $callType call to $recipientId (Call ID: $_currentCallId)');
      
      // Get local media stream
      final constraints = callType == CallType.audio ? _audioConstraints : _videoConstraints;
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      _localStreamController.add(_localStream);
      
      debugPrint('🎙️ Local stream obtained: ${_localStream!.getTracks().length} tracks');
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);
      
      // Add local stream tracks to peer connection with explicit send direction
      _localStream!.getTracks().forEach((track) {
        debugPrint('➕ Adding local track: ${track.kind} (enabled: ${track.enabled})');
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Listen for remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('📥 Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream);
        }
      };
      
      // Listen for ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        debugPrint('🧊 New ICE candidate: ${candidate.candidate}');
        _firestore
            .collection('calls')
            .doc(_currentCallId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      };
      
      // Listen for connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _cancelConnectionTimeout();
          _updateCallState(CallState.connected);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                   state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _updateCallState(CallState.error);
          endCall();
        }
      };
      
      // Create offer with proper media options
      final offerOptions = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == CallType.video,
      };
      RTCSessionDescription offer = await _peerConnection!.createOffer(offerOptions);
      await _peerConnection!.setLocalDescription(offer);
      
      debugPrint('📝 Created offer with ${callType == CallType.video ? "video" : "audio only"}');
      
      // Save call document to Firestore
      await _firestore.collection('calls').doc(_currentCallId).set({
        'callerId': currentUser.uid,
        'calleeId': recipientId,
        'callType': callType.name,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Call offer created and sent');
      _updateCallState(CallState.ringing);
      
      // Start connection timeout
      _startConnectionTimeout();
      
      // Listen for answer
      _listenForAnswer();
      
      // Listen for callee ICE candidates (will be queued until remote description is set)
      _listenForCalleeICECandidates();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      _updateCallState(CallState.error);
      await endCall();
      return false;
    }
  }
  
  /// Answer an incoming call
  Future<bool> answerCall({required String callId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot answer call: Not authenticated');
        return false;
      }
      
      _updateCallState(CallState.connecting);
      _currentCallId = callId;
      _remoteDescriptionSet = false;
      _pendingIceCandidates.clear();
      
      debugPrint('📞 Answering call: $callId');
      
      // Get call document
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (!callDoc.exists) {
        debugPrint('❌ Call document not found');
        return false;
      }
      
      final callData = callDoc.data()!;
      _otherUserId = callData['callerId'];
      _currentCallType = callData['callType'] == 'audio' ? CallType.audio : CallType.video;
      
      // Get local media stream
      final constraints = _currentCallType == CallType.audio ? _audioConstraints : _videoConstraints;
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      _localStreamController.add(_localStream);
      
      debugPrint('🎙️ Local stream obtained: ${_localStream!.getTracks().length} tracks');
      
      // Create peer connection
      _peerConnection = await createPeerConnection(_configuration);
      
      // Add local stream tracks to peer connection with explicit send direction
      _localStream!.getTracks().forEach((track) {
        debugPrint('➕ Adding local track: ${track.kind} (enabled: ${track.enabled})');
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Listen for remote stream
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('📥 Received remote track: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream);
        }
      };
      
      // Listen for ICE candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        debugPrint('🧊 New ICE candidate: ${candidate.candidate}');
        _firestore
            .collection('calls')
            .doc(_currentCallId)
            .collection('calleeCandidates')
            .add(candidate.toMap());
      };
      
      // Listen for connection state changes
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _cancelConnectionTimeout();
          _updateCallState(CallState.connected);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                   state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _updateCallState(CallState.error);
          endCall();
        }
      };
      
      // Set remote description from offer
      final offerData = callData['offer'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], offerData['type']),
      );
      
      // Mark remote description as set
      _remoteDescriptionSet = true;
      debugPrint('✅ Remote description set from offer');
      
      // Create answer with proper media options
      final answerOptions = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': _currentCallType == CallType.video,
      };
      RTCSessionDescription answer = await _peerConnection!.createAnswer(answerOptions);
      await _peerConnection!.setLocalDescription(answer);
      
      debugPrint('📝 Created answer with ${_currentCallType == CallType.video ? "video" : "audio only"}');
      
      // Save answer to Firestore
      await _firestore.collection('calls').doc(callId).update({
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
        'status': 'connected',
      });
      
      debugPrint('✅ Call answer created and sent');
      
      // Start connection timeout
      _startConnectionTimeout();
      
      // Listen for caller ICE candidates (will be queued until remote description is set)
      _listenForCallerICECandidates();
      
      // Process any pending ICE candidates
      await _processPendingIceCandidates();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error answering call: $e');
      _updateCallState(CallState.error);
      await endCall();
      return false;
    }
  }
  
  /// Listen for answer from callee
  void _listenForAnswer() {
    _callStateSubscription = _firestore
        .collection('calls')
        .doc(_currentCallId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null) return;
      
      if (data['answer'] != null && _peerConnection != null && !_remoteDescriptionSet) {
        final answerData = data['answer'];
        final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
        
        debugPrint('📥 Received answer from callee');
        await _peerConnection!.setRemoteDescription(answer);
        
        // Mark remote description as set
        _remoteDescriptionSet = true;
        debugPrint('✅ Remote description set from answer');
        
        // Process any pending ICE candidates
        await _processPendingIceCandidates();
      }
    });
  }
  
  /// Process pending ICE candidates after remote description is set
  Future<void> _processPendingIceCandidates() async {
    if (_pendingIceCandidates.isEmpty) {
      debugPrint('ℹ️ No pending ICE candidates to process');
      return;
    }
    
    debugPrint('🧊 Processing ${_pendingIceCandidates.length} pending ICE candidates');
    
    for (final candidate in _pendingIceCandidates) {
      try {
        await _peerConnection?.addCandidate(candidate);
        debugPrint('✅ Added pending ICE candidate');
      } catch (e) {
        debugPrint('❌ Error adding pending ICE candidate: $e');
      }
    }
    
    _pendingIceCandidates.clear();
    debugPrint('✅ All pending ICE candidates processed');
  }
  
  /// Start connection timeout timer
  void _startConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      if (_callState == CallState.connecting || _callState == CallState.ringing) {
        debugPrint('⏰ Connection timeout - call failed to connect within ${_connectionTimeout.inSeconds} seconds');
        _updateCallState(CallState.error);
        endCall();
      }
    });
    debugPrint('⏰ Connection timeout started (${_connectionTimeout.inSeconds}s)');
  }
  
  /// Cancel connection timeout timer
  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
    debugPrint('⏰ Connection timeout cancelled');
  }
  
  /// Listen for caller ICE candidates
  void _listenForCallerICECandidates() {
    _iceCandidateSubscription = _firestore
        .collection('calls')
        .doc(_currentCallId)
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && _peerConnection != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            
            // Only add candidate if remote description is set, otherwise queue it
            if (_remoteDescriptionSet) {
              try {
                await _peerConnection!.addCandidate(candidate);
                debugPrint('🧊 Added caller ICE candidate');
              } catch (e) {
                debugPrint('❌ Error adding caller ICE candidate: $e');
              }
            } else {
              _pendingIceCandidates.add(candidate);
              debugPrint('🧊 Queued caller ICE candidate (waiting for remote description)');
            }
          }
        }
      }
    });
  }
  
  /// Listen for callee ICE candidates
  void _listenForCalleeICECandidates() {
    _iceCandidateSubscription = _firestore
        .collection('calls')
        .doc(_currentCallId)
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && _peerConnection != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            
            // Only add candidate if remote description is set, otherwise queue it
            if (_remoteDescriptionSet) {
              try {
                await _peerConnection!.addCandidate(candidate);
                debugPrint('🧊 Added callee ICE candidate');
              } catch (e) {
                debugPrint('❌ Error adding callee ICE candidate: $e');
              }
            } else {
              _pendingIceCandidates.add(candidate);
              debugPrint('🧊 Queued callee ICE candidate (waiting for remote description)');
            }
          }
        }
      }
    });
  }
  
  /// Listen for incoming calls
  void _listenForIncomingCalls() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    debugPrint('👂 Listening for incoming calls...');
    
    _incomingCallSubscription = _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final callData = change.doc.data();
          final callId = change.doc.id;
          
          if (callData != null) {
            final callerId = callData['callerId'] as String;
            final calleeId = callData['calleeId'] as String;
            
            // CRITICAL FIX: Only trigger incoming call if ALL conditions are met:
            // 1. We are the callee (our UID matches calleeId)
            // 2. The caller is NOT us (prevent self-calls)
            // 3. We are NOT currently in any call state (idle only)
            // 4. We haven't already processed this call ID
            final isWeTheCallee = calleeId == currentUser.uid;
            final isCallerDifferent = callerId != currentUser.uid;
            final areWeIdle = _callState == CallState.idle;
            final isNewCall = _currentCallId != callId;
            
            if (isWeTheCallee && isCallerDifferent && areWeIdle && isNewCall) {
              debugPrint('📞 Incoming call from $callerId (Call ID: $callId)');
              
              // Store the call details
              _currentCallId = callId;
              _otherUserId = callerId;
              _currentCallType = callData['callType'] == 'audio' ? CallType.audio : CallType.video;
              
              // Trigger ringing state for incoming call
              _updateCallState(CallState.ringing);
            } else {
              // Debug logging for why we ignored this call
              if (!isWeTheCallee) {
                debugPrint('ℹ️ Ignoring call - not for us (calleeId: $calleeId vs our UID: ${currentUser.uid})');
              } else if (!isCallerDifferent) {
                debugPrint('ℹ️ Ignoring our own outgoing call (Call ID: $callId)');
              } else if (!areWeIdle) {
                debugPrint('ℹ️ Ignoring incoming call - already in call state: $_callState');
              } else if (!isNewCall) {
                debugPrint('ℹ️ Ignoring duplicate call notification (Call ID: $callId)');
              }
            }
          }
        }
      }
    });
  }
  
  /// Toggle microphone mute
  Future<void> toggleMute() async {
    if (_localStream == null) return;
    
    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      final enabled = audioTrack.enabled;
      audioTrack.enabled = !enabled;
      debugPrint('🎤 Microphone ${!enabled ? 'muted' : 'unmuted'}');
    }
  }
  
  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    if (_localStream == null || _currentCallType != CallType.video) return;
    
    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      final enabled = videoTrack.enabled;
      videoTrack.enabled = !enabled;
      debugPrint('📹 Camera ${!enabled ? 'disabled' : 'enabled'}');
    }
  }
  
  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream == null || _currentCallType != CallType.video) return;
    
    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      debugPrint('🔄 Camera switched');
    }
  }
  
  /// Enable screen sharing
  Future<void> enableScreenSharing() async {
    try {
      if (_peerConnection == null) return;
      
      debugPrint('🖥️ Enabling screen sharing...');
      
      // Get screen capture stream
      final screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
      
      final screenTrack = screenStream.getVideoTracks().first;
      
      // Find video sender and replace track
      final senders = await _peerConnection!.getSenders();
      final videoSender = senders.firstWhere(
        (sender) => sender.track?.kind == 'video',
        orElse: () => throw Exception('No video sender found'),
      );
      
      await videoSender.replaceTrack(screenTrack);
      
      // Update local stream for UI
      _localStream = screenStream;
      _localStreamController.add(_localStream);
      
      // Listen for screen sharing stop
      screenTrack.onEnded = () async {
        debugPrint('🖥️ Screen sharing ended');
        await disableScreenSharing();
      };
      
      debugPrint('✅ Screen sharing enabled');
    } catch (e) {
      debugPrint('❌ Error enabling screen sharing: $e');
    }
  }
  
  /// Disable screen sharing (back to camera)
  Future<void> disableScreenSharing() async {
    try {
      if (_peerConnection == null || _currentCallType != CallType.video) return;
      
      debugPrint('🖥️ Disabling screen sharing...');
      
      // Stop screen stream
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      
      // Get camera stream again
      _localStream = await navigator.mediaDevices.getUserMedia(_videoConstraints);
      _localStreamController.add(_localStream);
      
      // Add tracks to peer connection
      final videoTrack = _localStream!.getVideoTracks().first;
      final senders = await _peerConnection!.getSenders();
      final videoSender = senders.firstWhere(
        (sender) => sender.track?.kind == 'video',
        orElse: () => throw Exception('No video sender found'),
      );
      
      await videoSender.replaceTrack(videoTrack);
      
      debugPrint('✅ Screen sharing disabled, back to camera');
    } catch (e) {
      debugPrint('❌ Error disabling screen sharing: $e');
    }
  }
  
  /// End the current call
  Future<void> endCall() async {
    debugPrint('📞 Ending call...');
    
    // Cancel connection timeout
    _cancelConnectionTimeout();
    
    try {
      // Stop all local tracks immediately
      _localStream?.getTracks().forEach((track) {
        track.stop();
        debugPrint('🛑 Stopped local track: ${track.kind}');
      });
      
      // Stop all remote tracks
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
        debugPrint('🛑 Stopped remote track: ${track.kind}');
      });
      
      // Close peer connection
      await _peerConnection?.close();
      await _peerConnection?.dispose();
      
      // Cancel subscriptions
      await _iceCandidateSubscription?.cancel();
      await _callStateSubscription?.cancel();
      
      // Update call status in Firestore
      if (_currentCallId != null) {
        try {
          await _firestore.collection('calls').doc(_currentCallId).update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('⚠️ Could not update call status in Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error during call cleanup: $e');
    }
    
    // Clear all state
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _currentCallType = null;
    _otherUserId = null;
    _remoteDescriptionSet = false;
    _pendingIceCandidates.clear();
    
    // Update stream controllers
    _localStreamController.add(null);
    _remoteStreamController.add(null);
    
    // Update state
    _updateCallState(CallState.ended);
    
    // Reset to idle after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_callState == CallState.ended) {
        _updateCallState(CallState.idle);
      }
    });
    
    debugPrint('✅ Call ended and resources cleaned up');
  }
  
  /// Dispose the service
  void dispose() {
    debugPrint('🧹 Disposing WebRTC service...');
    _incomingCallSubscription?.cancel();
    endCall();
    _callStateController.close();
    _remoteStreamController.close();
    _localStreamController.close();
    debugPrint('✅ WebRTC service disposed');
  }
}
