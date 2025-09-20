import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) : interests = interests ?? [],
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
    profilePrivacy: PrivacyLevel.values.firstWhere((e) => e.name == json['profilePrivacy']),
    progressPrivacy: PrivacyLevel.values.firstWhere((e) => e.name == json['progressPrivacy']),
    friendsPrivacy: PrivacyLevel.values.firstWhere((e) => e.name == json['friendsPrivacy']),
    isOnline: json['isOnline'] ?? false,
    lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
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
    acceptDate: json['acceptDate'] != null ? DateTime.parse(json['acceptDate']) : null,
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
  }) : subjects = subjects ?? [],
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
    members: (json['members'] as List?)?.map((m) => StudyGroupMember.fromJson(m)).toList() ?? [],
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

  factory StudyGroupMember.fromJson(Map<String, dynamic> json) => StudyGroupMember(
    userId: json['userId'],
    groupId: json['groupId'],
    role: StudyGroupRole.values.firstWhere((e) => e.name == json['role']),
    status: MembershipStatus.values.firstWhere((e) => e.name == json['status']),
    joinDate: DateTime.parse(json['joinDate']),
    lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
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
  }) : participants = participants ?? [],
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

  factory CollaborativeSession.fromJson(Map<String, dynamic> json) => CollaborativeSession(
    id: json['id'],
    name: json['name'],
    hostId: json['hostId'],
    groupId: json['groupId'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
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
  UserProfile? _currentUserProfile;
  List<Friendship> _friendships = [];
  List<StudyGroup> _studyGroups = [];
  List<CollaborativeSession> _collaborativeSessions = [];

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserData();
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      // Load user profile
      final profileData = _prefs?.getString(_userProfileKey);
      if (profileData != null) {
        _currentUserProfile = UserProfile.fromJson(jsonDecode(profileData));
      }

      // Load friendships
      final friendshipsData = _prefs?.getString(_friendshipsKey);
      if (friendshipsData != null) {
        final List<dynamic> friendshipsList = jsonDecode(friendshipsData);
        _friendships = friendshipsList.map((f) => Friendship.fromJson(f)).toList();
      }

      // Load study groups
      final groupsData = _prefs?.getString(_studyGroupsKey);
      if (groupsData != null) {
        final List<dynamic> groupsList = jsonDecode(groupsData);
        _studyGroups = groupsList.map((g) => StudyGroup.fromJson(g)).toList();
      }

      // Load collaborative sessions
      final sessionsData = _prefs?.getString(_collaborativeSessionsKey);
      if (sessionsData != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsData);
        _collaborativeSessions = sessionsList.map((s) => CollaborativeSession.fromJson(s)).toList();
      }
    } catch (e) {
      debugPrint('Error loading social learning data: $e');
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      // Save user profile
      if (_currentUserProfile != null) {
        await _prefs?.setString(_userProfileKey, jsonEncode(_currentUserProfile!.toJson()));
      }

      // Save friendships
      final friendshipsList = _friendships.map((f) => f.toJson()).toList();
      await _prefs?.setString(_friendshipsKey, jsonEncode(friendshipsList));

      // Save study groups
      final groupsList = _studyGroups.map((g) => g.toJson()).toList();
      await _prefs?.setString(_studyGroupsKey, jsonEncode(groupsList));

      // Save collaborative sessions
      final sessionsList = _collaborativeSessions.map((s) => s.toJson()).toList();
      await _prefs?.setString(_collaborativeSessionsKey, jsonEncode(sessionsList));
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
  }

  /// Send friend request
  Future<bool> sendFriendRequest({
    required String friendId,
    String? message,
  }) async {
    if (_currentUserProfile == null) return false;

    // Check if friendship already exists
    final existingFriendship = _friendships
        .where((f) => (f.userId == _currentUserProfile!.id && f.friendId == friendId) ||
                     (f.userId == friendId && f.friendId == _currentUserProfile!.id))
        .firstOrNull;

    if (existingFriendship != null) return false;

    final friendship = Friendship(
      id: _generateId(),
      userId: _currentUserProfile!.id,
      friendId: friendId,
      requestDate: DateTime.now(),
      requestMessage: message,
    );

    _friendships.add(friendship);
    await _saveUserData();
    return true;
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String friendshipId) async {
    final friendshipIndex = _friendships.indexWhere((f) => f.id == friendshipId);
    if (friendshipIndex == -1) return false;

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

    await _saveUserData();
    return true;
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
    if (_currentUserProfile == null) return null;

    final group = StudyGroup(
      id: _generateId(),
      name: name,
      description: description,
      ownerId: _currentUserProfile!.id,
      createdDate: DateTime.now(),
      subjects: subjects ?? [],
      maxMembers: maxMembers,
      isPrivate: isPrivate,
      password: password,
      members: [
        StudyGroupMember(
          userId: _currentUserProfile!.id,
          groupId: '',
          role: StudyGroupRole.owner,
          status: MembershipStatus.active,
          joinDate: DateTime.now(),
          lastActive: DateTime.now(),
        ),
      ],
    );

    // Update member group ID
    final updatedMembers = group.members.map((m) => StudyGroupMember(
      userId: m.userId,
      groupId: group.id,
      role: m.role,
      status: m.status,
      joinDate: m.joinDate,
      lastActive: m.lastActive,
      contributions: m.contributions,
    )).toList();

    final finalGroup = StudyGroup(
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
      currentMembers: 1,
    );

    _studyGroups.add(finalGroup);
    await _saveUserData();
    return finalGroup;
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
    final isAlreadyMember = group.members.any((m) => m.userId == _currentUserProfile!.id);
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
  List<Friendship> get friends => _friendships.where((f) => f.isAccepted).toList();

  /// Get pending friend requests (received)
  List<Friendship> get pendingFriendRequests => 
      _friendships.where((f) => !f.isAccepted && f.friendId == _currentUserProfile?.id).toList();

  /// Get sent friend requests
  List<Friendship> get sentFriendRequests => 
      _friendships.where((f) => !f.isAccepted && f.userId == _currentUserProfile?.id).toList();

  /// Get study groups where user is a member
  List<StudyGroup> get myStudyGroups => 
      _studyGroups.where((g) => g.members.any((m) => m.userId == _currentUserProfile?.id)).toList();

  /// Get all public study groups (for discovery)
  List<StudyGroup> get publicStudyGroups => 
      _studyGroups.where((g) => !g.isPrivate).toList();

  /// Get collaborative sessions where user is involved
  List<CollaborativeSession> get myCollaborativeSessions => 
      _collaborativeSessions.where((s) => s.participants.contains(_currentUserProfile?.id)).toList();

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

  /// Get social learning statistics
  Map<String, dynamic> getSocialStats() {
    return {
      'totalFriends': friends.length,
      'pendingRequests': pendingFriendRequests.length,
      'studyGroupsJoined': myStudyGroups.length,
      'studyGroupsOwned': myStudyGroups.where((g) => g.ownerId == _currentUserProfile?.id).length,
      'collaborativeSessions': myCollaborativeSessions.length,
      'profileCompleteness': _calculateProfileCompleteness(),
    };
  }

  /// Calculate profile completeness percentage
  double _calculateProfileCompleteness() {
    if (_currentUserProfile == null) return 0.0;

    int completed = 0;
    const int total = 6;

    if (_currentUserProfile!.avatar != null && _currentUserProfile!.avatar!.isNotEmpty) completed++;
    if (_currentUserProfile!.bio != null && _currentUserProfile!.bio!.isNotEmpty) completed++;
    if (_currentUserProfile!.interests.isNotEmpty) completed++;
    if (_currentUserProfile!.displayName.isNotEmpty) completed++;
    if (_currentUserProfile!.username.isNotEmpty) completed++;
    if (_currentUserProfile!.studyStats.isNotEmpty) completed++;

    return completed / total;
  }
}