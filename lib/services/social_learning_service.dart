import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firestore_service.dart';

/// TODO: CRITICAL SOCIAL LEARNING SERVICE IMPLEMENTATION GAPS
/// - Current implementation uses ONLY SharedPreferences - NO REAL SOCIAL FEATURES
/// - Need to implement complete Firebase/Firestore integration for real social data
/// - Missing real-time friend discovery and connection system
/// - Need to implement actual user matching and compatibility algorithms
/// - Missing real-time messaging and communication features
/// - Need to implement proper study group creation and management functionality
/// - Missing integration with video calling and live collaboration features
/// - Need to implement proper social notifications and activity feeds
/// - Missing user reporting and moderation system for safety
/// - Need to implement proper privacy controls and user blocking features
/// - Missing integration with study session sharing and collaboration
/// - Need to implement social gamification and leaderboards
/// - Missing proper user verification and trust scoring system
/// - Need to implement social learning analytics and effectiveness tracking
/// - Missing integration with educational institution and class management
/// - Need to implement proper social search and discovery features
/// - Missing integration with external social platforms for friend import
/// - Need to implement proper social onboarding and tutorial system

/// Represents a user's privacy settings
enum PrivacyLevel {
  public,
  friends,
  private,
}

/// Represents different study group roles
enum StudyGroupRole {
  owner,
  moderator,
  member,
}

/// Represents study group membership status
enum MembershipStatus {
  pending,
  active,
  banned,
  left,
}

/// Represents a user profile in the social learning system
class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatar;
  final String? bio;
  final DateTime joinDate;
  final int level;
  final int totalXP;
  final String title;
  final List<String> interests;
  final Map<String, dynamic> achievements;
  final PrivacyLevel profilePrivacy;
  final PrivacyLevel progressPrivacy;
  final PrivacyLevel friendsPrivacy;
  final bool isOnline;
  final DateTime? lastActive;
  final Map<String, dynamic> studyStats;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatar,
    this.bio,
    required this.joinDate,
    required this.level,
    required this.totalXP,
    required this.title,
    List<String>? interests,
    Map<String, dynamic>? achievements,
    this.profilePrivacy = PrivacyLevel.public,
    this.progressPrivacy = PrivacyLevel.friends,
    this.friendsPrivacy = PrivacyLevel.friends,
    this.isOnline = false,
    this.lastActive,
    Map<String, dynamic>? studyStats,
  })  : interests = interests ?? [],
        achievements = achievements ?? {},
        studyStats = studyStats ?? {};

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatar,
    String? bio,
    int? level,
    int? totalXP,
    String? title,
    List<String>? interests,
    Map<String, dynamic>? achievements,
    PrivacyLevel? profilePrivacy,
    PrivacyLevel? progressPrivacy,
    PrivacyLevel? friendsPrivacy,
    bool? isOnline,
    DateTime? lastActive,
    Map<String, dynamic>? studyStats,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      joinDate: joinDate,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      title: title ?? this.title,
      interests: interests ?? this.interests,
      achievements: achievements ?? this.achievements,
      profilePrivacy: profilePrivacy ?? this.profilePrivacy,
      progressPrivacy: progressPrivacy ?? this.progressPrivacy,
      friendsPrivacy: friendsPrivacy ?? this.friendsPrivacy,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      studyStats: studyStats ?? this.studyStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatar': avatar,
        'bio': bio,
        'joinDate': joinDate.toIso8601String(),
        'level': level,
        'totalXP': totalXP,
        'title': title,
        'interests': interests,
        'achievements': achievements,
        'profilePrivacy': profilePrivacy.name,
        'progressPrivacy': progressPrivacy.name,
        'friendsPrivacy': friendsPrivacy.name,
        'isOnline': isOnline,
        'lastActive': lastActive?.toIso8601String(),
        'studyStats': studyStats,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        username: json['username'],
        displayName: json['displayName'],
        avatar: json['avatar'],
        bio: json['bio'],
        joinDate: DateTime.parse(json['joinDate']),
        level: json['level'],
        totalXP: json['totalXP'],
        title: json['title'],
        interests: List<String>.from(json['interests'] ?? []),
        achievements: Map<String, dynamic>.from(json['achievements'] ?? {}),
        profilePrivacy: PrivacyLevel.values
            .firstWhere((e) => e.name == json['profilePrivacy']),
        progressPrivacy: PrivacyLevel.values
            .firstWhere((e) => e.name == json['progressPrivacy']),
        friendsPrivacy: PrivacyLevel.values
            .firstWhere((e) => e.name == json['friendsPrivacy']),
        isOnline: json['isOnline'] ?? false,
        lastActive: json['lastActive'] != null
            ? DateTime.parse(json['lastActive'])
            : null,
        studyStats: Map<String, dynamic>.from(json['studyStats'] ?? {}),
      );
}

/// Represents a friendship connection
class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final DateTime requestDate;
  final DateTime? acceptDate;
  final bool isAccepted;
  final bool isBlocked;
  final String? requestMessage;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.requestDate,
    this.acceptDate,
    this.isAccepted = false,
    this.isBlocked = false,
    this.requestMessage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'friendId': friendId,
        'requestDate': requestDate.toIso8601String(),
        'acceptDate': acceptDate?.toIso8601String(),
        'isAccepted': isAccepted,
        'isBlocked': isBlocked,
        'requestMessage': requestMessage,
      };

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'],
        userId: json['userId'],
        friendId: json['friendId'],
        requestDate: DateTime.parse(json['requestDate']),
        acceptDate: json['acceptDate'] != null
            ? DateTime.parse(json['acceptDate'])
            : null,
        isAccepted: json['isAccepted'] ?? false,
        isBlocked: json['isBlocked'] ?? false,
        requestMessage: json['requestMessage'],
      );
}

/// Represents a study group
class StudyGroup {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final DateTime createdDate;
  final List<String> subjects;
  final int maxMembers;
  final bool isPrivate;
  final String? password;
  final String? avatar;
  final Map<String, dynamic> settings;
  final List<StudyGroupMember> members;
  final int currentMembers;

  StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.createdDate,
    List<String>? subjects,
    this.maxMembers = 50,
    this.isPrivate = false,
    this.password,
    this.avatar,
    Map<String, dynamic>? settings,
    List<StudyGroupMember>? members,
    this.currentMembers = 1,
  })  : subjects = subjects ?? [],
        settings = settings ?? {},
        members = members ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'createdDate': createdDate.toIso8601String(),
        'subjects': subjects,
        'maxMembers': maxMembers,
        'isPrivate': isPrivate,
        'password': password,
        'avatar': avatar,
        'settings': settings,
        'members': members.map((m) => m.toJson()).toList(),
        'currentMembers': currentMembers,
      };

  factory StudyGroup.fromJson(Map<String, dynamic> json) => StudyGroup(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        ownerId: json['ownerId'],
        createdDate: DateTime.parse(json['createdDate']),
        subjects: List<String>.from(json['subjects'] ?? []),
        maxMembers: json['maxMembers'] ?? 50,
        isPrivate: json['isPrivate'] ?? false,
        password: json['password'],
        avatar: json['avatar'],
        settings: Map<String, dynamic>.from(json['settings'] ?? {}),
        members: (json['members'] as List?)
                ?.map((m) => StudyGroupMember.fromJson(m))
                .toList() ??
            [],
        currentMembers: json['currentMembers'] ?? 1,
      );
}

/// Represents a member of a study group
class StudyGroupMember {
  final String userId;
  final String groupId;
  final StudyGroupRole role;
  final MembershipStatus status;
  final DateTime joinDate;
  final DateTime? lastActive;
  final Map<String, dynamic> contributions;

  StudyGroupMember({
    required this.userId,
    required this.groupId,
    required this.role,
    required this.status,
    required this.joinDate,
    this.lastActive,
    Map<String, dynamic>? contributions,
  }) : contributions = contributions ?? {};

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'groupId': groupId,
        'role': role.name,
        'status': status.name,
        'joinDate': joinDate.toIso8601String(),
        'lastActive': lastActive?.toIso8601String(),
        'contributions': contributions,
      };

  factory StudyGroupMember.fromJson(Map<String, dynamic> json) =>
      StudyGroupMember(
        userId: json['userId'],
        groupId: json['groupId'],
        role: StudyGroupRole.values.firstWhere((e) => e.name == json['role']),
        status:
            MembershipStatus.values.firstWhere((e) => e.name == json['status']),
        joinDate: DateTime.parse(json['joinDate']),
        lastActive: json['lastActive'] != null
            ? DateTime.parse(json['lastActive'])
            : null,
        contributions: Map<String, dynamic>.from(json['contributions'] ?? {}),
      );
}

/// Represents a collaborative study session
class CollaborativeSession {
  final String id;
  final String name;
  final String hostId;
  final String? groupId;
  final DateTime scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> participants;
  final String subject;
  final String? description;
  final Map<String, dynamic> sessionData;
  final bool isActive;
  final bool isRecorded;

  CollaborativeSession({
    required this.id,
    required this.name,
    required this.hostId,
    this.groupId,
    required this.scheduledTime,
    this.startTime,
    this.endTime,
    List<String>? participants,
    required this.subject,
    this.description,
    Map<String, dynamic>? sessionData,
    this.isActive = false,
    this.isRecorded = false,
  })  : participants = participants ?? [],
        sessionData = sessionData ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hostId': hostId,
        'groupId': groupId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'participants': participants,
        'subject': subject,
        'description': description,
        'sessionData': sessionData,
        'isActive': isActive,
        'isRecorded': isRecorded,
      };

  factory CollaborativeSession.fromJson(Map<String, dynamic> json) =>
      CollaborativeSession(
        id: json['id'],
        name: json['name'],
        hostId: json['hostId'],
        groupId: json['groupId'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'])
            : null,
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        participants: List<String>.from(json['participants'] ?? []),
        subject: json['subject'],
        description: json['description'],
        sessionData: Map<String, dynamic>.from(json['sessionData'] ?? {}),
        isActive: json['isActive'] ?? false,
        isRecorded: json['isRecorded'] ?? false,
      );
}

/// Social learning service for managing user profiles, friendships, and study groups
class SocialLearningService {
  static const String _userProfileKey = 'user_profile';
  static const String _friendshipsKey = 'friendships';
  static const String _studyGroupsKey = 'study_groups';
  static const String _collaborativeSessionsKey = 'collaborative_sessions';

  SharedPreferences? _prefs;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _currentUserProfile;
  List<Friendship> _friendships = [];
  List<StudyGroup> _studyGroups = [];
  List<CollaborativeSession> _collaborativeSessions = [];
  
  // Cache for user profiles to avoid redundant Firestore calls
  final Map<String, UserProfile> _profileCache = {};
  
  /// Get current Firebase user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserData();
    _setupPresenceTracking();
  }
  
  /// Set up automatic presence tracking
  void _setupPresenceTracking() {
    final user = _auth.currentUser;
    if (user != null) {
      // Set user as active on initialization
      _updatePresence(isActive: true);
      
      // Update presence periodically (every 5 minutes)
      Timer.periodic(const Duration(minutes: 5), (timer) {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          _updatePresence(isActive: true);
        } else {
          timer.cancel();
        }
      });
    }
  }
  
  /// Update user presence status
  Future<void> _updatePresence({required bool isActive}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestoreService.usersCollection.doc(user.uid).update({
        'isActive': isActive,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Updated presence: isActive=$isActive');
    } catch (e) {
      debugPrint('⚠️ Error updating presence: $e');
    }
  }
  
  /// Set user offline (call when logging out)
  Future<void> setOffline() async {
    await _updatePresence(isActive: false);
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      // First try to load from Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('📥 Loading user profile from Firestore for user: ${user.uid}');
        try {
          final userDoc = await _firestoreService.usersCollection.doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>?;
            if (data != null) {
              debugPrint('✅ Firestore data found: ${data.keys.join(', ')}');
              
              // Convert Firestore data to UserProfile
              _currentUserProfile = UserProfile(
                id: user.uid,
                username: data['username'] ?? 'user_${user.uid.substring(0, 8)}',
                displayName: data['displayName'] ?? 'User',
                bio: data['bio'],
                avatar: data['profilePicture'],
                joinDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                level: data['level'] ?? 1,
                totalXP: data['totalXP'] ?? 0,
                title: data['title'] ?? 'Beginner',
                interests: List<String>.from(data['interests'] ?? []),
                profilePrivacy: _parsePrivacyLevel(data['privacySettings']?['profileVisibility']),
                progressPrivacy: _parsePrivacyLevel(data['privacySettings']?['progressVisibility']),
                friendsPrivacy: _parsePrivacyLevel(data['privacySettings']?['friendsVisibility']),
                isOnline: true,
                lastActive: DateTime.now(),
              );
              
              // Save to local storage for offline access
              await _prefs?.setString(_userProfileKey, jsonEncode(_currentUserProfile!.toJson()));
              debugPrint('✅ User profile loaded from Firestore successfully');
              // Don't return here - continue to load friendships and groups
            }
          } else {
            debugPrint('⚠️ No Firestore document found for user');
          }
        } catch (e) {
          debugPrint('⚠️ Error loading from Firestore: $e');
        }
      } else {
        // Fallback to SharedPreferences if not authenticated
        final profileData = _prefs?.getString(_userProfileKey);
        if (profileData != null) {
          _currentUserProfile = UserProfile.fromJson(jsonDecode(profileData));
          debugPrint('✅ User profile loaded from SharedPreferences');
        }
      }

      // Reload user reference for friendships and groups loading
      final currentUser = _auth.currentUser;
      
      // Load friendships from Firestore if authenticated
      if (currentUser != null) {
        try {
          debugPrint('📥 Loading friendships from Firestore...');
          
          // Load sent requests (where current user is the sender)
          final sentRequests = await _firestoreService.friendshipsCollection
              .where('userId', isEqualTo: currentUser.uid)
              .get();
          
          // Load received requests (where current user is the receiver)
          final receivedRequests = await _firestoreService.friendshipsCollection
              .where('friendId', isEqualTo: currentUser.uid)
              .get();
          
          _friendships.clear();
          
          // Process sent requests
          for (final doc in sentRequests.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _friendships.add(Friendship(
              id: data['id'],
              userId: data['userId'],
              friendId: data['friendId'],
              requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              acceptDate: (data['acceptDate'] as Timestamp?)?.toDate(),
              isAccepted: data['isAccepted'] ?? false,
              requestMessage: data['requestMessage'],
            ));
          }
          
          // Process received requests
          for (final doc in receivedRequests.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _friendships.add(Friendship(
              id: data['id'],
              userId: data['userId'],
              friendId: data['friendId'],
              requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              acceptDate: (data['acceptDate'] as Timestamp?)?.toDate(),
              isAccepted: data['isAccepted'] ?? false,
              requestMessage: data['requestMessage'],
            ));
          }
          
          debugPrint('✅ Loaded ${_friendships.length} friendships from Firestore');
        } catch (e) {
          debugPrint('⚠️ Error loading friendships from Firestore: $e');
          
          // Fallback to local storage
          final friendshipsData = _prefs?.getString(_friendshipsKey);
          if (friendshipsData != null) {
            final List<dynamic> friendshipsList = jsonDecode(friendshipsData);
            _friendships = friendshipsList.map((f) => Friendship.fromJson(f)).toList();
          }
        }
      } else {
        // Load friendships from local storage if not authenticated
        final friendshipsData = _prefs?.getString(_friendshipsKey);
        if (friendshipsData != null) {
          final List<dynamic> friendshipsList = jsonDecode(friendshipsData);
          _friendships = friendshipsList.map((f) => Friendship.fromJson(f)).toList();
        }
      }

      // Load study groups from Firestore if authenticated
      if (currentUser != null) {
        try {
          debugPrint('📥 Loading study groups from Firestore...');
          debugPrint('Current user ID: ${currentUser.uid}');
          
          // Load all groups and filter by membership locally
          // TODO: Add a separate memberIds array field in Firestore for better querying
          final groupsSnapshot = await _firestoreService.studyGroupsCollection.get();
          
          debugPrint('Found ${groupsSnapshot.docs.length} total study groups in Firestore');
          
          _studyGroups.clear();
          int skippedGroups = 0;
          
          for (final doc in groupsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('Processing group: ${data['name']} (ID: ${doc.id})');
            
            final membersList = (data['members'] as List<dynamic>?)?.map((m) {
              final memberData = m as Map<String, dynamic>;
              return StudyGroupMember(
                userId: memberData['userId'],
                groupId: memberData['groupId'],
                role: _parseStudyGroupRole(memberData['role']),
                status: _parseMembershipStatus(memberData['status']),
                joinDate: (memberData['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                lastActive: (memberData['lastActive'] as Timestamp?)?.toDate(),
                contributions: memberData['contributions'] ?? 0,
              );
            }).toList() ?? [];
            
            debugPrint('Group has ${membersList.length} members');
            for (final member in membersList) {
              debugPrint('  - Member: ${member.userId} (${member.role.name})');
            }
            
            // Only include groups where current user is a member
            final isMember = membersList.any((m) => m.userId == currentUser.uid);
            if (!isMember) {
              debugPrint('⏭️ Skipping group "${data['name']}" - current user is not a member');
              skippedGroups++;
              continue;
            }
            
            debugPrint('✅ Adding group "${data['name']}" to user\'s groups');
            
            _studyGroups.add(StudyGroup(
              id: data['id'],
              name: data['name'],
              description: data['description'],
              ownerId: data['ownerId'],
              createdDate: (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              subjects: List<String>.from(data['subjects'] ?? []),
              maxMembers: data['maxMembers'] ?? 50,
              isPrivate: data['isPrivate'] ?? false,
              password: data['password'],
              avatar: data['avatar'],
              currentMembers: data['currentMembers'] ?? membersList.length,
              members: membersList,
              settings: Map<String, dynamic>.from(data['settings'] ?? {}),
            ));
          }
          
          debugPrint('✅ Loaded ${_studyGroups.length} study groups from Firestore (skipped $skippedGroups groups)');
        } catch (e) {
          debugPrint('⚠️ Error loading study groups from Firestore: $e');
          
          // Fallback to local storage
          final groupsData = _prefs?.getString(_studyGroupsKey);
          if (groupsData != null) {
            final List<dynamic> groupsList = jsonDecode(groupsData);
            _studyGroups = groupsList.map((g) => StudyGroup.fromJson(g)).toList();
          }
        }
      } else {
        // Load study groups from local storage if not authenticated
        final groupsData = _prefs?.getString(_studyGroupsKey);
        if (groupsData != null) {
          final List<dynamic> groupsList = jsonDecode(groupsData);
          _studyGroups = groupsList.map((g) => StudyGroup.fromJson(g)).toList();
        }
      }

      // Load collaborative sessions
      final sessionsData = _prefs?.getString(_collaborativeSessionsKey);
      if (sessionsData != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsData);
        _collaborativeSessions =
            sessionsList.map((s) => CollaborativeSession.fromJson(s)).toList();
      }
    } catch (e) {
      debugPrint('Error loading social learning data: $e');
    }
  }
  
  /// Parse privacy level from string
  PrivacyLevel _parsePrivacyLevel(String? value) {
    switch (value) {
      case 'public':
        return PrivacyLevel.public;
      case 'friends':
        return PrivacyLevel.friends;
      case 'private':
        return PrivacyLevel.private;
      default:
        return PrivacyLevel.public;
    }
  }
  
  /// Parse study group role from string
  StudyGroupRole _parseStudyGroupRole(String? value) {
    switch (value) {
      case 'owner':
        return StudyGroupRole.owner;
      case 'moderator':
        return StudyGroupRole.moderator;
      case 'member':
        return StudyGroupRole.member;
      default:
        return StudyGroupRole.member;
    }
  }
  
  /// Parse membership status from string
  MembershipStatus _parseMembershipStatus(String? value) {
    switch (value) {
      case 'pending':
        return MembershipStatus.pending;
      case 'active':
        return MembershipStatus.active;
      case 'banned':
        return MembershipStatus.banned;
      case 'left':
        return MembershipStatus.left;
      default:
        return MembershipStatus.active;
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      // Save user profile to local storage
      if (_currentUserProfile != null) {
        await _prefs?.setString(
            _userProfileKey, jsonEncode(_currentUserProfile!.toJson()));
        
        // Also save to Firestore if user is authenticated
        final user = _auth.currentUser;
        if (user != null) {
          await _firestoreService.usersCollection.doc(user.uid).update({
            'displayName': _currentUserProfile!.displayName,
            'username': _currentUserProfile!.username,
            'bio': _currentUserProfile!.bio,
            'profilePicture': _currentUserProfile!.avatar,
            'privacySettings': {
              'profileVisibility': _currentUserProfile!.profilePrivacy.name,
              'progressVisibility': _currentUserProfile!.progressPrivacy.name,
              'friendsVisibility': _currentUserProfile!.friendsPrivacy.name,
            },
            'lastActiveAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ User profile saved to Firestore successfully');
        }
      }

      // Save friendships
      final friendshipsList = _friendships.map((f) => f.toJson()).toList();
      await _prefs?.setString(_friendshipsKey, jsonEncode(friendshipsList));

      // Save study groups
      final groupsList = _studyGroups.map((g) => g.toJson()).toList();
      await _prefs?.setString(_studyGroupsKey, jsonEncode(groupsList));

      // Save collaborative sessions
      final sessionsList =
          _collaborativeSessions.map((s) => s.toJson()).toList();
      await _prefs?.setString(
          _collaborativeSessionsKey, jsonEncode(sessionsList));
    } catch (e) {
      debugPrint('Error saving social learning data: $e');
    }
  }

  /// Create or update user profile
  Future<void> createUserProfile({
    required String username,
    required String displayName,
    String? bio,
    List<String>? interests,
    PrivacyLevel? profilePrivacy,
    PrivacyLevel? progressPrivacy,
    PrivacyLevel? friendsPrivacy,
  }) async {
    final profileId = _generateId();

    _currentUserProfile = UserProfile(
      id: profileId,
      username: username,
      displayName: displayName,
      bio: bio,
      joinDate: DateTime.now(),
      level: 1,
      totalXP: 0,
      title: 'Beginner',
      interests: interests ?? [],
      profilePrivacy: profilePrivacy ?? PrivacyLevel.public,
      progressPrivacy: progressPrivacy ?? PrivacyLevel.friends,
      friendsPrivacy: friendsPrivacy ?? PrivacyLevel.friends,
      isOnline: true,
      lastActive: DateTime.now(),
    );

    await _saveUserData();
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? username,
    String? displayName,
    String? avatar,
    String? bio,
    List<String>? interests,
    PrivacyLevel? profilePrivacy,
    PrivacyLevel? progressPrivacy,
    PrivacyLevel? friendsPrivacy,
  }) async {
    if (_currentUserProfile == null) return;

    _currentUserProfile = _currentUserProfile!.copyWith(
      username: username,
      displayName: displayName,
      avatar: avatar,
      bio: bio,
      interests: interests,
      profilePrivacy: profilePrivacy,
      progressPrivacy: progressPrivacy,
      friendsPrivacy: friendsPrivacy,
    );

    await _saveUserData();
    
    // Clear cache so friends see updated profile
    final userId = _currentUserProfile!.id;
    _profileCache.remove(userId);
    debugPrint('🔄 Cleared profile cache for user: $userId');
  }
  
  /// Clear cached profile for a specific user (useful when profile is updated)
  void clearProfileCache(String userId) {
    _profileCache.remove(userId);
    debugPrint('🔄 Cleared profile cache for user: $userId');
  }
  
  /// Clear all cached profiles
  void clearAllProfileCaches() {
    _profileCache.clear();
    debugPrint('🔄 Cleared all profile caches');
  }

  /// Send friend request
  Future<bool> sendFriendRequest({
    required String friendId,
    String? message,
  }) async {
    if (_currentUserProfile == null) {
      debugPrint('❌ Cannot send friend request: No user profile');
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot send friend request: Not authenticated');
      return false;
    }

    try {
      // Check if friendship already exists in Firestore
      debugPrint('🔍 Checking for existing friendship between ${user.uid} and $friendId');
      
      final existingFriendships = await _firestoreService.friendshipsCollection
          .where('userId', isEqualTo: user.uid)
          .where('friendId', isEqualTo: friendId)
          .get();
      
      debugPrint('Found ${existingFriendships.docs.length} friendships where userId=${user.uid} and friendId=$friendId');
      
      final reverseExistingFriendships = await _firestoreService.friendshipsCollection
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: user.uid)
          .get();
      
      debugPrint('Found ${reverseExistingFriendships.docs.length} friendships where userId=$friendId and friendId=${user.uid}');

      if (existingFriendships.docs.isNotEmpty || reverseExistingFriendships.docs.isNotEmpty) {
        // Show which friendship exists
        if (existingFriendships.docs.isNotEmpty) {
          final doc = existingFriendships.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('❌ Friendship already exists: ${doc.id}, status: ${data['status']}, isAccepted: ${data['isAccepted']}');
        }
        if (reverseExistingFriendships.docs.isNotEmpty) {
          final doc = reverseExistingFriendships.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('❌ Reverse friendship already exists: ${doc.id}, status: ${data['status']}, isAccepted: ${data['isAccepted']}');
        }
        return false;
      }

      // Create friendship document in Firestore
      final friendshipId = _generateId();
      final friendshipData = {
        'id': friendshipId,
        'userId': user.uid,
        'friendId': friendId,
        'status': 'pending',
        'isAccepted': false,
        'requestDate': FieldValue.serverTimestamp(),
        'requestMessage': message,
        'acceptDate': null,
      };

      await _firestoreService.friendshipsCollection.doc(friendshipId).set(friendshipData);
      
      // Also save locally
      final friendship = Friendship(
        id: friendshipId,
        userId: user.uid,
        friendId: friendId,
        requestDate: DateTime.now(),
        requestMessage: message,
      );

      _friendships.add(friendship);
      await _saveUserData();
      
      debugPrint('✅ Friend request sent successfully to $friendId');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String friendshipId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot accept friend request: Not authenticated');
      return false;
    }

    try {
      // Update in Firestore
      await _firestoreService.friendshipsCollection.doc(friendshipId).update({
        'isAccepted': true,
        'status': 'accepted',
        'acceptDate': FieldValue.serverTimestamp(),
      });

      // Update locally
      final friendshipIndex = _friendships.indexWhere((f) => f.id == friendshipId);
      if (friendshipIndex != -1) {
        final friendship = _friendships[friendshipIndex];
        _friendships[friendshipIndex] = Friendship(
          id: friendship.id,
          userId: friendship.userId,
          friendId: friendship.friendId,
          requestDate: friendship.requestDate,
          acceptDate: DateTime.now(),
          isAccepted: true,
          requestMessage: friendship.requestMessage,
        );
      }

      await _saveUserData();
      debugPrint('✅ Friend request accepted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error accepting friend request: $e');
      return false;
    }
  }

  /// Create study group
  Future<StudyGroup?> createStudyGroup({
    required String name,
    required String description,
    List<String>? subjects,
    int maxMembers = 50,
    bool isPrivate = false,
    String? password,
  }) async {
    if (_currentUserProfile == null) {
      debugPrint('❌ Cannot create study group: No user profile');
      return null;
    }

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot create study group: Not authenticated');
      return null;
    }

    try {
      final groupId = _generateId();
      
      final group = StudyGroup(
        id: groupId,
        name: name,
        description: description,
        ownerId: user.uid,
        createdDate: DateTime.now(),
        subjects: subjects ?? [],
        maxMembers: maxMembers,
        isPrivate: isPrivate,
        password: password,
        members: [
          StudyGroupMember(
            userId: user.uid,
            groupId: groupId,
            role: StudyGroupRole.owner,
            status: MembershipStatus.active,
            joinDate: DateTime.now(),
            lastActive: DateTime.now(),
          ),
        ],
        currentMembers: 1,
      );

      // Save to Firestore
      final groupData = {
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'ownerId': group.ownerId,
        'createdDate': FieldValue.serverTimestamp(),
        'subjects': group.subjects,
        'maxMembers': group.maxMembers,
        'isPrivate': group.isPrivate,
        'password': group.password,
        'avatar': group.avatar,
        'currentMembers': 1,
        'members': group.members.map((m) => {
          'userId': m.userId,
          'groupId': m.groupId,
          'role': m.role.name,
          'status': m.status.name,
          'joinDate': Timestamp.fromDate(m.joinDate),
          'lastActive': m.lastActive != null ? Timestamp.fromDate(m.lastActive!) : FieldValue.serverTimestamp(),
          'contributions': m.contributions,
        }).toList(),
        'settings': group.settings,
      };

      await _firestoreService.studyGroupsCollection.doc(groupId).set(groupData);
      
      // Also save locally
      _studyGroups.add(group);
      await _saveUserData();
      
      debugPrint('✅ Study group created successfully: ${group.name} (ID: ${group.id})');
      return group;
    } catch (e) {
      debugPrint('❌ Error creating study group: $e');
      return null;
    }
  }

  /// Join study group
  Future<bool> joinStudyGroup({
    required String groupId,
    String? password,
  }) async {
    if (_currentUserProfile == null) return false;

    final groupIndex = _studyGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return false;

    final group = _studyGroups[groupIndex];

    // Check if group is private and password is required
    if (group.isPrivate && group.password != password) {
      return false;
    }

    // Check if user is already a member
    final isAlreadyMember =
        group.members.any((m) => m.userId == _currentUserProfile!.id);
    if (isAlreadyMember) return false;

    // Check if group is full
    if (group.currentMembers >= group.maxMembers) return false;

    final newMember = StudyGroupMember(
      userId: _currentUserProfile!.id,
      groupId: groupId,
      role: StudyGroupRole.member,
      status: MembershipStatus.active,
      joinDate: DateTime.now(),
      lastActive: DateTime.now(),
    );

    final updatedMembers = [...group.members, newMember];
    _studyGroups[groupIndex] = StudyGroup(
      id: group.id,
      name: group.name,
      description: group.description,
      ownerId: group.ownerId,
      createdDate: group.createdDate,
      subjects: group.subjects,
      maxMembers: group.maxMembers,
      isPrivate: group.isPrivate,
      password: group.password,
      avatar: group.avatar,
      settings: group.settings,
      members: updatedMembers,
      currentMembers: group.currentMembers + 1,
    );

    await _saveUserData();
    return true;
  }

  /// Schedule collaborative session
  Future<CollaborativeSession?> scheduleCollaborativeSession({
    required String name,
    required DateTime scheduledTime,
    required String subject,
    String? description,
    String? groupId,
    List<String>? invitedParticipants,
  }) async {
    if (_currentUserProfile == null) return null;

    final session = CollaborativeSession(
      id: _generateId(),
      name: name,
      hostId: _currentUserProfile!.id,
      groupId: groupId,
      scheduledTime: scheduledTime,
      subject: subject,
      description: description,
      participants: [_currentUserProfile!.id, ...(invitedParticipants ?? [])],
    );

    _collaborativeSessions.add(session);
    await _saveUserData();
    return session;
  }

  /// Get current user profile
  UserProfile? get currentUserProfile => _currentUserProfile;

  /// Get friends list
  List<Friendship> get friends =>
      _friendships.where((f) => f.isAccepted).toList();

  /// Get pending friend requests (received)
  List<Friendship> get pendingFriendRequests => _friendships
      .where((f) => !f.isAccepted && f.friendId == _currentUserProfile?.id)
      .toList();

  /// Get sent friend requests
  List<Friendship> get sentFriendRequests => _friendships
      .where((f) => !f.isAccepted && f.userId == _currentUserProfile?.id)
      .toList();

  /// Refresh friendships from Firestore
  /// Call this to check for new friend requests
  Future<void> refreshFriendships() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ Cannot refresh friendships: Not authenticated');
      return;
    }

    try {
      debugPrint('🔄 Refreshing friendships from Firestore...');
      
      // Load sent requests (where current user is the sender)
      final sentRequests = await _firestoreService.friendshipsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      // Load received requests (where current user is the receiver)
      final receivedRequests = await _firestoreService.friendshipsCollection
          .where('friendId', isEqualTo: currentUser.uid)
          .get();
      
      _friendships.clear();
      
      // Process sent requests
      for (final doc in sentRequests.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _friendships.add(Friendship(
          id: data['id'],
          userId: data['userId'],
          friendId: data['friendId'],
          requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          acceptDate: (data['acceptDate'] as Timestamp?)?.toDate(),
          isAccepted: data['isAccepted'] ?? false,
          requestMessage: data['requestMessage'],
        ));
      }
      
      // Process received requests
      for (final doc in receivedRequests.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _friendships.add(Friendship(
          id: data['id'],
          userId: data['userId'],
          friendId: data['friendId'],
          requestDate: (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          acceptDate: (data['acceptDate'] as Timestamp?)?.toDate(),
          isAccepted: data['isAccepted'] ?? false,
          requestMessage: data['requestMessage'],
        ));
      }
      
      debugPrint('✅ Refreshed ${_friendships.length} friendships from Firestore');
      debugPrint('📊 Pending requests: ${pendingFriendRequests.length}, Sent requests: ${sentFriendRequests.length}');
    } catch (e) {
      debugPrint('❌ Error refreshing friendships: $e');
    }
  }

  /// Get user profile by ID from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    // Check cache first
    if (_profileCache.containsKey(userId)) {
      debugPrint('✅ Using cached profile for: $userId');
      return _profileCache[userId];
    }
    
    try {
      debugPrint('📥 Fetching user profile for: $userId');
      
      final doc = await _firestoreService.usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        debugPrint('❌ User profile not found: $userId');
        
        // Check if this might be a demo user by searching all users
        final allUsersSnapshot = await _firestoreService.usersCollection.get();
        for (final userDoc in allUsersSnapshot.docs) {
          final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final docId = userDoc.id;
            // Check if document ID matches or if there's any reference to this userId
            if (docId == userId || data['uid'] == userId) {
              debugPrint('🔍 Found user in document: $docId with uid: ${data['uid']}');
              // Recursively call with the correct document ID
              if (docId != userId) {
                return await getUserProfile(docId);
              }
            }
          }
        }
        
        // If still not found, create a demo user profile
        debugPrint('⚠️ Creating demo profile for: $userId');
        final demoProfile = UserProfile(
          id: userId,
          username: 'demo_${userId.substring(0, 8)}',
          displayName: 'Demo User',
          bio: 'This is a demo account',
          joinDate: DateTime.now(),
          level: 1,
          totalXP: 0,
          title: 'Demo',
          interests: [],
        );
        _profileCache[userId] = demoProfile;
        return demoProfile;
      }
      
      final rawData = doc.data();
      if (rawData == null) {
        debugPrint('❌ User document has no data: $userId');
        return null;
      }
      
      // Safely convert to Map<String, dynamic>
      Map<String, dynamic> data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      } else {
        debugPrint('❌ Unexpected data type for user $userId: ${rawData.runtimeType}');
        return null;
      }
      
      // Check if this is a demo user (missing critical fields)
      final hasValidUid = data['uid'] != null && data['uid'] == userId;
      final hasEmail = data['email'] != null && (data['email'] as String).isNotEmpty;
      
      if (!hasValidUid || !hasEmail) {
        debugPrint('⚠️ User $userId appears to be a demo account (uid: ${data['uid']}, hasEmail: $hasEmail)');
        // Mark it as a demo user in the display
        final demoProfile = UserProfile(
          id: userId,
          username: data['username'] ?? 'demo_user',
          displayName: '${data['displayName'] ?? 'Demo User'} [Demo]',
          avatar: data['profilePicture'],
          bio: data['bio'] ?? 'Demo account',
          joinDate: DateTime.now(),
          level: 1,
          totalXP: 0,
          title: 'Demo',
          interests: [],
        );
        _profileCache[userId] = demoProfile;
        return demoProfile;
      }
      
      // Helper function to safely get Map from dynamic data
      Map<String, dynamic>? getMapSafely(dynamic value) {
        if (value == null) return null;
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value);
        return null;
      }
      
      // Helper function to safely get List from dynamic data
      List<String> getListSafely(dynamic value) {
        if (value == null) return [];
        if (value is List) return value.map((e) => e.toString()).toList();
        return [];
      }
      
      final studyStatsData = getMapSafely(data['studyStats']);
      final privacySettingsData = getMapSafely(data['privacySettings']);
      
      // Determine if user is truly online based on lastActiveAt timestamp
      final lastActive = (data['lastActiveAt'] as Timestamp?)?.toDate();
      final isActive = data['isActive'] ?? false;
      
      // Consider user online if they're marked active AND were active within last 10 minutes
      final isTrulyOnline = isActive && lastActive != null && 
          DateTime.now().difference(lastActive).inMinutes < 10;
      
      final profile = UserProfile(
        id: userId,
        username: data['username'] ?? 'unknown',
        displayName: data['displayName'] ?? 'Unknown User',
        avatar: data['profilePicture'],
        bio: data['bio'],
        joinDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        level: studyStatsData?['level'] ?? 1,
        totalXP: studyStatsData?['totalXP'] ?? 0,
        title: studyStatsData?['title'] ?? 'Beginner',
        interests: getListSafely(data['interests']),
        profilePrivacy: _parsePrivacyLevel(privacySettingsData?['profileVisibility']),
        progressPrivacy: _parsePrivacyLevel(privacySettingsData?['progressVisibility']),
        friendsPrivacy: _parsePrivacyLevel(privacySettingsData?['friendsVisibility']),
        isOnline: isTrulyOnline,
        lastActive: lastActive,
        studyStats: studyStatsData ?? {},
        achievements: getMapSafely(data['achievements']) ?? {},
      );
      
      // Cache the profile
      _profileCache[userId] = profile;
      
      debugPrint('✅ Loaded profile: ${profile.displayName} (@${profile.username}) - Online: $isTrulyOnline');
      return profile;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get study groups where user is a member
  List<StudyGroup> get myStudyGroups => _studyGroups
      .where((g) => g.members.any((m) => m.userId == _currentUserProfile?.id))
      .toList();

  /// Get all public study groups (for discovery)
  /// This returns only locally loaded groups - use getPublicStudyGroupsForDiscovery for full list
  List<StudyGroup> get publicStudyGroups =>
      _studyGroups.where((g) => !g.isPrivate).toList();
      
  /// Get all public study groups from Firestore for discovery
  Future<List<StudyGroup>> getPublicStudyGroupsForDiscovery({int limit = 20}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot load public groups: Not authenticated');
        return [];
      }
      
      debugPrint('🔍 Loading public study groups from Firestore...');
      
      // Query Firestore for public groups
      final groupsSnapshot = await _firestoreService.studyGroupsCollection
          .where('isPrivate', isEqualTo: false)
          .limit(limit)
          .get();
      
      debugPrint('Found ${groupsSnapshot.docs.length} public study groups');
      
      final groups = <StudyGroup>[];
      
      for (final doc in groupsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Parse members array
          final membersData = data['members'] as List<dynamic>? ?? [];
          final members = <StudyGroupMember>[];
          
          for (final memberData in membersData) {
            final member = memberData as Map<String, dynamic>;
            members.add(StudyGroupMember(
              userId: member['userId'] ?? '',
              groupId: data['id'] ?? doc.id,
              role: _parseStudyGroupRole(member['role']),
              status: _parseMembershipStatus(member['status']),
              joinDate: (member['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              lastActive: (member['lastActive'] as Timestamp?)?.toDate(),
              contributions: member['contributions'] ?? 0,
            ));
          }
          
          final group = StudyGroup(
            id: data['id'] ?? doc.id,
            name: data['name'] ?? 'Unnamed Group',
            description: data['description'] ?? '',
            ownerId: data['ownerId'] ?? '',
            createdDate: (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            subjects: List<String>.from(data['subjects'] ?? []),
            maxMembers: data['maxMembers'] ?? 50,
            isPrivate: data['isPrivate'] ?? false,
            password: data['password'],
            avatar: data['avatar'],
            currentMembers: members.length,
            members: members,
            settings: data['settings'] as Map<String, dynamic>? ?? {},
          );
          
          groups.add(group);
          debugPrint('✅ Loaded group: ${group.name} (${group.currentMembers}/${group.maxMembers} members)');
        } catch (e) {
          debugPrint('⚠️ Error parsing group ${doc.id}: $e');
        }
      }
      
      debugPrint('✅ Loaded ${groups.length} public study groups for discovery');
      return groups;
    } catch (e) {
      debugPrint('❌ Error loading public study groups: $e');
      return [];
    }
  }

  /// Get a specific study group by ID from Firestore
  Future<StudyGroup?> getStudyGroupById(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot load group: Not authenticated');
        return null;
      }
      
      debugPrint('🔍 Loading study group $groupId from Firestore...');
      
      final groupDoc = await _firestoreService.studyGroupsCollection.doc(groupId).get();
      
      if (!groupDoc.exists) {
        debugPrint('❌ Group $groupId not found');
        return null;
      }
      
      final data = groupDoc.data() as Map<String, dynamic>;
      
      // Parse members array
      final membersData = data['members'] as List<dynamic>? ?? [];
      final members = <StudyGroupMember>[];
      
      for (final memberData in membersData) {
        final member = memberData as Map<String, dynamic>;
        members.add(StudyGroupMember(
          userId: member['userId'] ?? '',
          groupId: data['id'] ?? groupDoc.id,
          role: _parseStudyGroupRole(member['role']),
          status: _parseMembershipStatus(member['status']),
          joinDate: (member['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastActive: (member['lastActive'] as Timestamp?)?.toDate(),
          contributions: member['contributions'] ?? 0,
        ));
      }
      
      final group = StudyGroup(
        id: data['id'] ?? groupDoc.id,
        name: data['name'] ?? 'Unnamed Group',
        description: data['description'] ?? '',
        ownerId: data['ownerId'] ?? '',
        createdDate: (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        subjects: List<String>.from(data['subjects'] ?? []),
        maxMembers: data['maxMembers'] ?? 50,
        isPrivate: data['isPrivate'] ?? false,
        password: data['password'],
        avatar: data['avatar'],
        currentMembers: members.length,
        members: members,
        settings: data['settings'] as Map<String, dynamic>? ?? {},
      );
      
      debugPrint('✅ Loaded group: ${group.name} (${group.currentMembers}/${group.maxMembers} members)');
      return group;
    } catch (e) {
      debugPrint('❌ Error loading study group $groupId: $e');
      return null;
    }
  }

  /// Get member profiles for a study group
  Future<List<UserProfile>> getGroupMembers(StudyGroup group) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot load group members: Not authenticated');
        return [];
      }
      
      debugPrint('🔍 Loading ${group.members.length} members for group ${group.name}...');
      
      final memberProfiles = <UserProfile>[];
      
      for (final member in group.members) {
        // Skip inactive/banned members
        if (member.status != MembershipStatus.active) {
          debugPrint('⏭️ Skipping non-active member: ${member.userId}');
          continue;
        }
        
        final profile = await getUserProfile(member.userId);
        if (profile != null) {
          memberProfiles.add(profile);
          debugPrint('✅ Loaded member profile: ${profile.displayName}');
        } else {
          debugPrint('⚠️ Could not load profile for member: ${member.userId}');
        }
      }
      
      debugPrint('✅ Loaded ${memberProfiles.length} member profiles for group ${group.name}');
      return memberProfiles;
    } catch (e) {
      debugPrint('❌ Error loading group members: $e');
      return [];
    }
  }

  // ==================== CHAT SYSTEM ====================
  
  /// Get unique chat ID for two users (always same order)
  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
  
  /// Send a message to another user
  Future<void> sendMessage({
    required String recipientId,
    required String messageText,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot send message: Not authenticated');
        return;
      }
      
      if (messageText.trim().isEmpty) {
        debugPrint('❌ Cannot send empty message');
        return;
      }
      
      final chatId = getChatId(currentUser.uid, recipientId);
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      debugPrint('💬 Sending message to chat: $chatId');
      
      // Create message data
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': currentUser.uid,
        'recipientId': recipientId,
        'message': messageText.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      
      // Save message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);
      
      // Update chat metadata (last message, timestamp)
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': [currentUser.uid, recipientId],
        'lastMessage': messageText.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Clear typing indicator
      await updateTypingStatus(recipientId: recipientId, isTyping: false);
      
      debugPrint('✅ Message sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }
  
  /// Listen to messages in a chat (real-time)
  Stream<List<Map<String, dynamic>>> listenToMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ Cannot listen to messages: Not authenticated');
      return Stream.value([]);
    }
    
    final chatId = getChatId(currentUser.uid, otherUserId);
    debugPrint('👂 Listening to messages in chat: $chatId');
    
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('📨 Received ${snapshot.docs.length} messages');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] ?? doc.id,
          'senderId': data['senderId'] ?? '',
          'recipientId': data['recipientId'] ?? '',
          'message': data['message'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isRead': data['isRead'] ?? false,
          'isMe': data['senderId'] == currentUser.uid,
          // Discord features: reactions and attachments
          'reactions': data['reactions'] ?? {},
          'attachmentUrl': data['attachmentUrl'],
          'attachmentType': data['attachmentType'],
          'attachmentName': data['attachmentName'],
          'attachmentSize': data['attachmentSize'],
        };
      }).toList();
    });
  }
  
  /// Update typing status
  Future<void> updateTypingStatus({
    required String recipientId,
    required bool isTyping,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final chatId = getChatId(currentUser.uid, recipientId);
      
      await FirebaseFirestore.instance
          .collection('chat_typing')
          .doc(chatId)
          .set({
        currentUser.uid: {
          'isTyping': isTyping,
          'timestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      debugPrint('⌨️ Updated typing status: $isTyping');
    } catch (e) {
      debugPrint('❌ Error updating typing status: $e');
    }
  }
  
  /// Listen to other user's typing status
  Stream<bool> listenToTypingStatus(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }
    
    final chatId = getChatId(currentUser.uid, otherUserId);
    
    return FirebaseFirestore.instance
        .collection('chat_typing')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      // Get OTHER user's typing status (not yours)
      final otherUserData = data[otherUserId] as Map<String, dynamic>?;
      if (otherUserData == null) return false;
      
      final isTyping = otherUserData['isTyping'] ?? false;
      final timestamp = (otherUserData['timestamp'] as Timestamp?)?.toDate();
      
      // Only show typing if timestamp is recent (within 5 seconds)
      if (timestamp != null && isTyping) {
        final age = DateTime.now().difference(timestamp).inSeconds;
        return age < 5;
      }
      
      return false;
    });
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final chatId = getChatId(currentUser.uid, otherUserId);
      
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      debugPrint('✅ Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  // ==================== ENHANCED MESSAGING (Discord Features) ====================
  
  /// Send message with optional attachment, GIF, or sticker
  Future<void> sendEnhancedMessage({
    required String recipientId,
    String? messageText,
    String? attachmentUrl,
    String? attachmentType, // 'image', 'file', 'gif', 'sticker'
    String? attachmentName,
    int? attachmentSize,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Cannot send message: Not authenticated');
        return;
      }
      
      // Must have either text or attachment
      if ((messageText == null || messageText.trim().isEmpty) && 
          attachmentUrl == null) {
        debugPrint('❌ Cannot send empty message');
        return;
      }
      
      final chatId = getChatId(currentUser.uid, recipientId);
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      debugPrint('💬 Sending enhanced message to chat: $chatId');
      
      // Create message data
      final messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': currentUser.uid,
        'recipientId': recipientId,
        'message': messageText?.trim() ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'reactions': {}, // Map of emoji -> List of user IDs
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentType != null) 'attachmentType': attachmentType,
        if (attachmentName != null) 'attachmentName': attachmentName,
        if (attachmentSize != null) 'attachmentSize': attachmentSize,
      };
      
      // Save message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);
      
      // Update chat metadata
      final lastMessagePreview = attachmentType != null
          ? _getAttachmentPreview(attachmentType)
          : (messageText?.trim() ?? '');
          
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': [currentUser.uid, recipientId],
        'lastMessage': lastMessagePreview,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Clear typing indicator
      await updateTypingStatus(recipientId: recipientId, isTyping: false);
      
      debugPrint('✅ Enhanced message sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending enhanced message: $e');
      rethrow;
    }
  }
  
  String _getAttachmentPreview(String type) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'gif':
        return '🎬 GIF';
      case 'sticker':
        return '🎨 Sticker';
      case 'file':
        return '📎 File';
      default:
        return '📎 Attachment';
    }
  }
  
  /// Upload file/image to Firebase Storage
  Future<Map<String, dynamic>> uploadAttachment({
    required String filePath,
    required String fileName,
    required String fileType, // 'image', 'file'
    required String recipientId,
    Function(double)? onProgress,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }
      
      debugPrint('📤 Uploading $fileType: $fileName');
      
      final chatId = getChatId(currentUser.uid, recipientId);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chats')
          .child(chatId)
          .child('$timestamp\_$fileName');
      
      // Read file
      final file = File(filePath);
      final fileSize = await file.length();
      
      // Upload with progress tracking
      final uploadTask = storageRef.putFile(file);
      
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Upload complete: $downloadUrl');
      
      return {
        'url': downloadUrl,
        'name': fileName,
        'size': fileSize,
        'type': fileType,
      };
    } catch (e) {
      debugPrint('❌ Error uploading attachment: $e');
      rethrow;
    }
  }
  
  /// Add reaction to a message
  Future<void> addReaction({
    required String otherUserId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final chatId = getChatId(currentUser.uid, otherUserId);
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      debugPrint('👍 Adding reaction $emoji to message $messageId');
      
      // Use transaction to safely update reactions
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);
        
        if (!messageDoc.exists) {
          throw Exception('Message not found');
        }
        
        final data = messageDoc.data()!;
        final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
        
        // Get existing users who reacted with this emoji
        final List<String> users = List<String>.from(reactions[emoji] ?? []);
        
        if (!users.contains(currentUser.uid)) {
          users.add(currentUser.uid);
          reactions[emoji] = users;
          
          transaction.update(messageRef, {'reactions': reactions});
          debugPrint('✅ Reaction added successfully');
        } else {
          debugPrint('⚠️ User already reacted with this emoji');
        }
      });
    } catch (e) {
      debugPrint('❌ Error adding reaction: $e');
    }
  }
  
  /// Remove reaction from a message
  Future<void> removeReaction({
    required String otherUserId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final chatId = getChatId(currentUser.uid, otherUserId);
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      debugPrint('👎 Removing reaction $emoji from message $messageId');
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);
        
        if (!messageDoc.exists) return;
        
        final data = messageDoc.data()!;
        final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
        
        if (reactions.containsKey(emoji)) {
          final List<String> users = List<String>.from(reactions[emoji] ?? []);
          users.remove(currentUser.uid);
          
          if (users.isEmpty) {
            reactions.remove(emoji);
          } else {
            reactions[emoji] = users;
          }
          
          transaction.update(messageRef, {'reactions': reactions});
          debugPrint('✅ Reaction removed successfully');
        }
      });
    } catch (e) {
      debugPrint('❌ Error removing reaction: $e');
    }
  }

  /// Get collaborative sessions where user is involved
  List<CollaborativeSession> get myCollaborativeSessions =>
      _collaborativeSessions
          .where((s) => s.participants.contains(_currentUserProfile?.id))
          .toList();

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUserProfile == null) return;

    _currentUserProfile = _currentUserProfile!.copyWith(
      isOnline: isOnline,
      lastActive: DateTime.now(),
    );

    await _saveUserData();
  }

  /// Update user level and XP from gamification service
  Future<void> updateUserProgress({
    required int level,
    required int totalXP,
    required String title,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? studyStats,
  }) async {
    if (_currentUserProfile == null) return;

    _currentUserProfile = _currentUserProfile!.copyWith(
      level: level,
      totalXP: totalXP,
      title: title,
      achievements: achievements,
      studyStats: studyStats,
    );

    await _saveUserData();
  }

  /// Get users for discovery in the Find People tab
  /// Excludes the current user and returns a list of UserProfile objects
  Future<List<UserProfile>> getUsersForDiscovery({int limit = 20}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user authenticated');
        return [];
      }

      debugPrint('Current user UID: ${currentUser.uid}');
      
      // Get list of friend IDs to exclude from discovery
      final friendIds = <String>{};
      for (final friendship in _friendships) {
        // Add both userId and friendId to cover all friendship records
        friendIds.add(friendship.userId);
        friendIds.add(friendship.friendId);
      }
      // Remove current user from exclusion list
      friendIds.remove(currentUser.uid);
      
      debugPrint('📋 Excluding ${friendIds.length} friends from discovery');

      // Try to get data from Firestore with offline support
      try {
        // First, let's try a simpler query without the isActive filter
        // since that field might not exist on all user documents
        final usersQuery = _firestoreService.usersCollection.limit(limit + friendIds.length);

        final querySnapshot = await usersQuery.get();

        debugPrint(
            'Found ${querySnapshot.docs.length} total documents in users collection');

        List<UserProfile> userProfiles = [];

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = data['uid'] as String?;

          debugPrint(
              'Processing user document - UID: $uid, Data keys: ${data.keys.toList()}');

          // Skip current user
          if (uid == currentUser.uid) {
            debugPrint('Skipping current user: $uid');
            continue;
          }
          
          // Skip friends (existing friendships)
          if (uid != null && friendIds.contains(uid)) {
            debugPrint('Skipping friend: $uid');
            continue;
          }

          // Convert Firestore user data to UserProfile
          final userProfile = _mapFirestoreUserToProfile(data);
          if (userProfile != null) {
            debugPrint(
                'Successfully mapped user profile: ${userProfile.displayName}');
            userProfiles.add(userProfile);
            
            // Stop if we've reached the limit
            if (userProfiles.length >= limit) {
              break;
            }
          } else {
            debugPrint('Failed to map user profile for UID: $uid');
          }
        }

        debugPrint('Returning ${userProfiles.length} user profiles (excluding ${friendIds.length} friends)');
        return userProfiles;
      } catch (firestoreError) {
        debugPrint('Firestore query failed: $firestoreError');
        debugPrint('Error type: ${firestoreError.runtimeType}');
        debugPrint('Error string: ${firestoreError.toString()}');

        // If Firestore is offline or unavailable, return some mock users for demo purposes
        // This ensures the UI doesn't show empty state when there are connection issues
        debugPrint(
            'Firebase client has connection issues, returning demo users');
        return _getMockUsersForOfflineDemo();
      }
    } catch (e) {
      debugPrint('Error getting users for discovery: $e');
      return [];
    }
  }

  /// Provide mock users when Firebase is offline for demo purposes
  List<UserProfile> _getMockUsersForOfflineDemo() {
    return [
      UserProfile(
        id: 'demo_user_1',
        username: 'alex_study',
        displayName: 'Alex Chen',
        bio:
            'Computer Science student passionate about algorithms and data structures.',
        joinDate: DateTime.now().subtract(const Duration(days: 45)),
        level: 7,
        totalXP: 2150,
        title: 'Knowledge Seeker',
        interests: ['Computer Science', 'Mathematics', 'Programming'],
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      UserProfile(
        id: 'demo_user_2',
        username: 'sarah_bio',
        displayName: 'Sarah Johnson',
        bio: 'Biology major with a focus on molecular biology and genetics.',
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
        level: 5,
        totalXP: 1450,
        title: 'Dedicated Learner',
        interests: ['Biology', 'Chemistry', 'Research'],
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UserProfile(
        id: 'demo_user_3',
        username: 'mike_physics',
        displayName: 'Michael Rodriguez',
        bio:
            'Physics enthusiast studying quantum mechanics and theoretical physics.',
        joinDate: DateTime.now().subtract(const Duration(days: 60)),
        level: 8,
        totalXP: 2800,
        title: 'Master Student',
        interests: ['Physics', 'Mathematics', 'Engineering'],
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      UserProfile(
        id: 'demo_user_4',
        username: 'emma_lit',
        displayName: 'Emma Thompson',
        bio:
            'English Literature student with interests in contemporary fiction.',
        joinDate: DateTime.now().subtract(const Duration(days: 25)),
        level: 4,
        totalXP: 980,
        title: 'Scholar',
        interests: ['Literature', 'Writing', 'History'],
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }

  /// Convert Firestore user document to UserProfile object
  UserProfile? _mapFirestoreUserToProfile(Map<String, dynamic> data) {
    try {
      final uid = data['uid'] as String?;
      final displayName = data['displayName'] as String?;
      final email = data['email'] as String?;

      debugPrint(
          'Mapping user profile - UID: $uid, DisplayName: $displayName, Email: $email');

      if (uid == null) {
        debugPrint('Missing UID field');
        return null;
      }

      // Use fallback for displayName if missing
      final finalDisplayName =
          displayName ?? email?.split('@').first ?? 'StudyPal User';

      // Extract bio and interests
      final bio = data['bio'] as String?;
      final studyStats = data['studyStats'] as Map<String, dynamic>?;

      // Create a reasonable username from email or displayName
      String username = email?.split('@').first ??
          finalDisplayName.toLowerCase().replaceAll(' ', '_');

      // Extract study-related interests or generate some based on their data
      List<String> interests = [];
      final major = data['major'] as String?;
      final school = data['school'] as String?;

      if (major != null && major.isNotEmpty) {
        interests.add(major);
      }
      if (school != null && school.isNotEmpty) {
        interests.add(school);
      }

      // Add some study-related interests based on their study stats
      final cardsStudied = studyStats?['cardsStudied'] as int? ?? 0;
      final totalStudyTime = studyStats?['totalStudyTime'] as int? ?? 0;

      if (cardsStudied > 100) interests.add('Flashcards');
      if (totalStudyTime > 1000) interests.add('Study Sessions');

      // If no interests, add some general ones
      if (interests.isEmpty) {
        interests.addAll(['Learning', 'Education']);
      }

      // Calculate level based on study stats
      final level = _calculateLevelFromStudyStats(studyStats);
      final totalXP = (studyStats?['cardsStudied'] as int? ?? 0) * 10 +
          (studyStats?['totalStudyTime'] as int? ?? 0);

      // Generate title based on level
      String title = _getTitleForLevel(level);

      // Determine online status (assume recently active users are online)
      final lastActiveAt = data['lastActiveAt'];
      bool isOnline = false;
      DateTime? lastActive;

      if (lastActiveAt != null) {
        if (lastActiveAt is DateTime) {
          lastActive = lastActiveAt;
        } else {
          // Handle Firestore timestamp
          lastActive = DateTime.now(); // Fallback
        }

        // Consider user online if active within last 10 minutes
        isOnline = DateTime.now().difference(lastActive).inMinutes < 10;
      }

      return UserProfile(
        id: uid,
        username: username,
        displayName: finalDisplayName,
        avatar: data['profilePicture'] as String?,
        bio: bio,
        joinDate: _extractJoinDate(data),
        level: level,
        totalXP: totalXP,
        title: title,
        interests: interests,
        achievements: studyStats ?? {},
        isOnline: isOnline,
        lastActive: lastActive,
        studyStats: studyStats ?? {},
      );
    } catch (e) {
      debugPrint('Error mapping Firestore user to profile: $e');
      return null;
    }
  }

  /// Calculate user level based on study statistics
  int _calculateLevelFromStudyStats(Map<String, dynamic>? studyStats) {
    if (studyStats == null) return 1;

    final cardsStudied = studyStats['cardsStudied'] as int? ?? 0;
    final totalStudyTime = studyStats['totalStudyTime'] as int? ?? 0;
    final tasksCompleted = studyStats['tasksCompleted'] as int? ?? 0;

    // Simple level calculation based on activity
    final totalActivity =
        cardsStudied + (totalStudyTime ~/ 60) + (tasksCompleted * 5);

    if (totalActivity < 50) return 1;
    if (totalActivity < 150) return 2;
    if (totalActivity < 300) return 3;
    if (totalActivity < 500) return 4;
    if (totalActivity < 750) return 5;
    if (totalActivity < 1000) return 6;
    if (totalActivity < 1500) return 7;
    if (totalActivity < 2000) return 8;
    if (totalActivity < 3000) return 9;
    return 10;
  }

  /// Get title based on user level
  String _getTitleForLevel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Novice';
      case 3:
        return 'Student';
      case 4:
        return 'Scholar';
      case 5:
        return 'Dedicated Learner';
      case 6:
        return 'Study Expert';
      case 7:
        return 'Knowledge Seeker';
      case 8:
        return 'Master Student';
      case 9:
        return 'Study Guru';
      case 10:
        return 'Learning Legend';
      default:
        return 'Beginner';
    }
  }

  /// Extract join date from Firestore data
  DateTime _extractJoinDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt != null) {
      if (createdAt is DateTime) return createdAt;
      // Handle Firestore timestamp - fallback to current time
    }
    return DateTime.now()
        .subtract(const Duration(days: 30)); // Default to a month ago
  }

  /// Join a collaborative session
  Future<bool> joinCollaborativeSession({required String sessionId}) async {
    if (_currentUserProfile == null) return false;

    final sessionIndex =
        _collaborativeSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return false;

    final session = _collaborativeSessions[sessionIndex];

    // Check if user is already in the session
    if (session.participants.contains(_currentUserProfile!.id)) {
      return true; // User is already in the session
    }

    // Add user to participants
    final updatedSession = CollaborativeSession(
      id: session.id,
      name: session.name,
      hostId: session.hostId,
      groupId: session.groupId,
      scheduledTime: session.scheduledTime,
      startTime: session.startTime,
      endTime: session.endTime,
      participants: [...session.participants, _currentUserProfile!.id],
      subject: session.subject,
      description: session.description,
      sessionData: session.sessionData,
      isActive: session.isActive,
      isRecorded: session.isRecorded,
    );

    _collaborativeSessions[sessionIndex] = updatedSession;
    await _saveUserData();
    return true;
  }

  /// Get social learning statistics
  Map<String, dynamic> getSocialStats() {
    return {
      'totalFriends': friends.length,
      'pendingRequests': pendingFriendRequests.length,
      'studyGroupsJoined': myStudyGroups.length,
      'studyGroupsOwned': myStudyGroups
          .where((g) => g.ownerId == _currentUserProfile?.id)
          .length,
      'collaborativeSessions': myCollaborativeSessions.length,
      'profileCompleteness': _calculateProfileCompleteness(),
    };
  }

  /// Calculate profile completeness percentage
  double _calculateProfileCompleteness() {
    if (_currentUserProfile == null) return 0.0;

    int completed = 0;
    const int total = 6;

    if (_currentUserProfile!.avatar != null &&
        _currentUserProfile!.avatar!.isNotEmpty) {
      completed++;
    }
    if (_currentUserProfile!.bio != null &&
        _currentUserProfile!.bio!.isNotEmpty) {
      completed++;
    }
    if (_currentUserProfile!.interests.isNotEmpty) completed++;
    if (_currentUserProfile!.displayName.isNotEmpty) completed++;
    if (_currentUserProfile!.username.isNotEmpty) completed++;
    if (_currentUserProfile!.studyStats.isNotEmpty) completed++;

    return completed / total;
  }

  /// Decline a friend request
  Future<bool> declineFriendRequest(String friendshipId) async {
    try {
      // Delete from Firestore
      await _firestoreService.friendshipsCollection.doc(friendshipId).delete();
      
      // Remove locally
      final friendshipIndex = _friendships.indexWhere((f) => f.id == friendshipId);
      if (friendshipIndex != -1) {
        _friendships.removeAt(friendshipIndex);
      }

      await _saveUserData();
      debugPrint('✅ Friend request declined successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error declining friend request: $e');
      return false;
    }
  }
}
