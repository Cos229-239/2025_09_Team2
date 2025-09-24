import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/social_session.dart';
import '../screens/live_session_screen.dart';

class SessionDetailsScreen extends StatefulWidget {
  final SocialSession session;

  const SessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Check if user has already joined
    _isJoined = widget.session.participantIds.contains('current_user_id');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_canJoinSession())
            IconButton(
              onPressed: _joinSession,
              icon: const Icon(Icons.login),
              tooltip: 'Join Session',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Session'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Add to Calendar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_isSessionHost())
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Session'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_isSessionHost())
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Session', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Session header with key info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.session.type.displayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.session.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.session.description.isNotEmpty)
                  Text(
                    widget.session.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildQuickInfoRow(),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
              Tab(text: 'Participants', icon: Icon(Icons.people)),
              Tab(text: 'Materials', icon: Icon(Icons.folder)),
              Tab(text: 'Discussion', icon: Icon(Icons.chat_bubble_outline)),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildParticipantsTab(),
                _buildMaterialsTab(),
                _buildDiscussionTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildQuickInfoRow() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM dd, yyyy • HH:mm').format(widget.session.scheduledTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.people,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.session.participantIds.length}/${widget.session.maxParticipants} joined',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (widget.session.duration.inMinutes > 0) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.timer,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.session.duration.inMinutes} min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Host', widget.session.hostName, Icons.person),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Date & Time',
                    DateFormat('EEEE, MMM dd, yyyy at HH:mm').format(widget.session.scheduledTime),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 8),
                  if (widget.session.duration.inMinutes > 0)
                    _buildInfoRow(
                      'Duration',
                      '${widget.session.duration.inMinutes} minutes',
                      Icons.timer,
                    ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Max Participants',
                    widget.session.maxParticipants.toString(),
                    Icons.group,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Privacy',
                    widget.session.isPublic ? 'Public' : 'Private',
                    widget.session.isPublic ? Icons.public : Icons.lock,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Session description
          if (widget.session.description.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.session.description),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Session tags/subjects
          if (widget.session.deckIds.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Decks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: widget.session.deckIds.map((deckId) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Deck ${deckId.substring(0, 8)}...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Requirements/Prerequisites
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequirement('Stable internet connection', true),
                  _buildRequirement('Camera and microphone (recommended)', false),
                  _buildRequirement('Study materials ready', false),
                  _buildRequirement('Quiet environment', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(String requirement, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isRequired ? Icons.circle : Icons.circle_outlined,
            size: 8,
            color: isRequired ? Colors.red : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
                color: isRequired ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Joined',
                '${widget.session.participantIds.length}',
                Icons.people,
                Colors.green,
              ),
              _buildStatItem(
                'Available',
                '${widget.session.maxParticipants - widget.session.participantIds.length}',
                Icons.person_add,
                Colors.blue,
              ),
              _buildStatItem(
                'Waiting',
                '0',
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ],
          ),
        ),
        const Divider(),
        // Participants list
        Expanded(
          child: ListView.builder(
            itemCount: widget.session.participantIds.length,
            itemBuilder: (context, index) {
              final participantId = widget.session.participantIds[index];
              final participantName = widget.session.participantNames[participantId] ?? 'Unknown User';
              final isHost = participantId == widget.session.hostId;
              
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        participantName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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
                    Text(participantName),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                subtitle: Text('Joined ${_getJoinedTime(widget.session.createdAt)}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _handleParticipantAction(action, participantId, participantName),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('View Profile'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'message',
                      child: ListTile(
                        leading: Icon(Icons.message),
                        title: Text('Send Message'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_isSessionHost() && !isHost)
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
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    // Mock materials for demonstration
    final materials = [
      SessionMaterial(
        id: '1',
        title: 'Session Agenda',
        type: MaterialType.document,
        size: '245 KB',
        uploadedBy: 'Alex Johnson',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SessionMaterial(
        id: '2',
        title: 'Study Guide - Chapter 5',
        type: MaterialType.pdf,
        size: '1.2 MB',
        uploadedBy: 'Sarah Chen',
        uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SessionMaterial(
        id: '3',
        title: 'Practice Exercises',
        type: MaterialType.link,
        size: '',
        uploadedBy: 'Mike Rodriguez',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    return Column(
      children: [
        // Upload area (if user can upload)
        if (_canUploadMaterials())
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload Study Materials',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share documents, links, or other resources',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _uploadMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('Upload Material'),
                ),
              ],
            ),
          ),
        // Materials list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMaterialColor(material.type).withValues(alpha: 0.1),
                    child: Icon(
                      _getMaterialIcon(material.type),
                      color: _getMaterialColor(material.type),
                    ),
                  ),
                  title: Text(material.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uploaded by ${material.uploadedBy}'),
                      Text(
                        '${_getUploadedTime(material.uploadedAt)}${material.size.isNotEmpty ? ' • ${material.size}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _handleMaterialAction(action, material),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'download',
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title: Text('Download'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (_canDeleteMaterial(material))
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionTab() {
    // Mock discussion messages
    final discussions = [
      DiscussionMessage(
        id: '1',
        senderId: widget.session.hostId,
        senderName: widget.session.hostName,
        message: 'Welcome everyone! Looking forward to our study session.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isHost: true,
      ),
      DiscussionMessage(
        id: '2',
        senderId: '2',
        senderName: 'Sarah Chen',
        message: 'Thanks for organizing this! I have some questions about Chapter 5.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isHost: false,
      ),
      DiscussionMessage(
        id: '3',
        senderId: '3',
        senderName: 'Mike Rodriguez',
        message: 'I\'ll bring my notes on the practice problems.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isHost: false,
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: discussions.length,
            itemBuilder: (context, index) {
              final message = discussions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: message.isHost
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                      child: Text(
                        message.senderName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                message.senderName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (message.isHost) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                                _getMessageTime(message.timestamp),
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
        if (_isJoined)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask a question or share thoughts...',
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent!')),
                    );
                  },
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

  Widget _buildActionBar() {
    if (!_canJoinSession()) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isJoined) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _joinSession,
                icon: const Icon(Icons.login),
                label: const Text('Join Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startLiveSession,
                icon: const Icon(Icons.videocam),
                label: const Text('Enter Live Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _leaveSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Text('Leave'),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText() {
    final now = DateTime.now();
    final sessionStart = widget.session.scheduledTime;
    
    if (now.isAfter(sessionStart)) {
      return 'LIVE';
    } else if (now.isAfter(sessionStart.subtract(const Duration(minutes: 15)))) {
      return 'STARTING SOON';
    } else {
      return 'SCHEDULED';
    }
  }

  Color _getStatusColor() {
    final now = DateTime.now();
    final sessionStart = widget.session.scheduledTime;
    
    if (now.isAfter(sessionStart)) {
      return Colors.red;
    } else if (now.isAfter(sessionStart.subtract(const Duration(minutes: 15)))) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  bool _canJoinSession() {
    return widget.session.participantIds.length < widget.session.maxParticipants;
  }

  bool _isSessionHost() {
    return widget.session.hostId == 'current_user_id'; // Mock current user
  }

  bool _canUploadMaterials() {
    return _isJoined || _isSessionHost();
  }

  bool _canDeleteMaterial(SessionMaterial material) {
    return _isSessionHost() || material.uploadedBy == 'current_user'; // Mock check
  }

  String _getJoinedTime(DateTime joinedAt) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  String _getUploadedTime(DateTime uploadedAt) {
    final now = DateTime.now();
    final difference = now.difference(uploadedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  String _getMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  IconData _getMaterialIcon(MaterialType type) {
    switch (type) {
      case MaterialType.document:
        return Icons.description;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.link:
        return Icons.link;
      case MaterialType.image:
        return Icons.image;
      case MaterialType.video:
        return Icons.play_circle;
    }
  }

  Color _getMaterialColor(MaterialType type) {
    switch (type) {
      case MaterialType.document:
        return Colors.blue;
      case MaterialType.pdf:
        return Colors.red;
      case MaterialType.link:
        return Colors.green;
      case MaterialType.image:
        return Colors.purple;
      case MaterialType.video:
        return Colors.orange;
    }
  }

  void _joinSession() {
    setState(() {
      _isJoined = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully joined the session!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _leaveSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session'),
        content: const Text('Are you sure you want to leave this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isJoined = false;
              });
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

  void _startLiveSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveSessionScreen(session: widget.session),
      ),
    );
  }

  void _uploadMaterial() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload material functionality')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share session functionality')),
        );
        break;
      case 'calendar':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to calendar')),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit session functionality')),
        );
        break;
      case 'delete':
        _showDeleteSessionDialog();
        break;
    }
  }

  void _handleParticipantAction(String action, String participantId, String participantName) {
    switch (action) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View $participantName\'s profile')),
        );
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message $participantName')),
        );
        break;
      case 'remove':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$participantName removed from session')),
        );
        break;
    }
  }

  void _handleMaterialAction(String action, SessionMaterial material) {
    switch (action) {
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${material.title}')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing ${material.title}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${material.title} deleted')),
        );
        break;
    }
  }

  void _showDeleteSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Data models for session details
class SessionMaterial {
  final String id;
  final String title;
  final MaterialType type;
  final String size;
  final String uploadedBy;
  final DateTime uploadedAt;

  SessionMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedAt,
  });
}

enum MaterialType { document, pdf, link, image, video }

class DiscussionMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isHost;

  DiscussionMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isHost,
  });
}