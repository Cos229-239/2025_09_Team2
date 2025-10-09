import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/social_session.dart';
import '../providers/social_session_provider.dart';
import '../widgets/schedule_session_screen.dart';
import '../screens/live_session_screen.dart';
import '../screens/session_details_screen.dart';
import '../screens/session_results_screen.dart';

class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6FB8E9),
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: const Color(0xFF6FB8E9),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Live'),
            Tab(text: 'Completed'),
          ],
        ),

        // Tab bar view
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingTab(context),
              _buildLiveTab(context),
              _buildCompletedTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTab(BuildContext context) {
    return Column(
      children: [
        // Schedule button at top
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _navigateToScheduleSession,
            icon: const Icon(Icons.add),
            label: const Text('Schedule Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Sessions list
        Expanded(
          child: Consumer<SocialSessionProvider>(
            builder: (context, socialProvider, child) {
              final upcomingSessions = socialProvider.upcomingSessions;

              if (upcomingSessions.isEmpty) {
                return _buildEmptyState(
                  context,
                  Icons.event_available,
                  'No upcoming sessions',
                  'Schedule a session to study with friends!',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: upcomingSessions.length,
                itemBuilder: (context, index) {
                  final session = upcomingSessions[index];
                  return _buildSessionCard(context, session);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTab(BuildContext context) {
    return Consumer<SocialSessionProvider>(
      builder: (context, socialProvider, child) {
        final liveSessions = socialProvider.liveSessions;

        if (liveSessions.isEmpty) {
          return _buildEmptyState(
            context,
            Icons.live_tv,
            'No live sessions',
            'Start a scheduled session or join one from friends!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: liveSessions.length,
          itemBuilder: (context, index) {
            final session = liveSessions[index];
            return _buildLiveSessionCard(context, session);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab(BuildContext context) {
    return Consumer<SocialSessionProvider>(
      builder: (context, socialProvider, child) {
        final completedSessions = socialProvider.completedSessions;

        if (completedSessions.isEmpty) {
          return _buildEmptyState(
            context,
            Icons.history,
            'No completed sessions',
            'Complete some study sessions to see them here!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: completedSessions.length,
          itemBuilder: (context, index) {
            final session = completedSessions[index];
            return _buildCompletedSessionCard(context, session);
          },
        );
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, SocialSession session) {
    final socialProvider =
        Provider.of<SocialSessionProvider>(context, listen: false);
    final isHost = session.hostId == socialProvider.currentUserId;
    final canJoin =
        !session.participantIds.contains(socialProvider.currentUserId) &&
            session.canJoin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF242628),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSessionTypeColor(session.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.type.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isHost)
                  const Icon(Icons.star, color: Color(0xFF6FB8E9), size: 16),
                if (session.isStartingSoon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Starting Soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title and description
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9),
              ),
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                session.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Session info
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(session.scheduledTime),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(session.duration),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  '${session.participantCount}/${session.maxParticipants} participants',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  'Host: ${session.hostName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHost && session.isStartingSoon) ...[
                  ElevatedButton.icon(
                    onPressed: () => _startSession(session),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (canJoin) ...[
                  ElevatedButton.icon(
                    onPressed: () => _joinSession(session),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Join'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isHost)
                  OutlinedButton.icon(
                    onPressed: () => _cancelSession(session),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                  )
                else
                  TextButton(
                    onPressed: () => _viewSessionDetails(session),
                    child: const Text('Details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessionCard(BuildContext context, SocialSession session) {
    final socialProvider =
        Provider.of<SocialSessionProvider>(context, listen: false);
    final isParticipant =
        session.participantIds.contains(socialProvider.currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF242628),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live indicator
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    session.type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9D9D9),
                ),
              ),
              const SizedBox(height: 8),

              // Participants
              Text(
                '${session.participantCount} participants active',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 16),

              // Action button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isParticipant)
                    ElevatedButton.icon(
                      onPressed: () => _joinLiveSession(session),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Join Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _viewSessionDetails(session),
                      child: const Text('View Details'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSessionCard(
      BuildContext context, SocialSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF242628),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completion status
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  session.type.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 8),

            // Session info
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(session.scheduledTime),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: Color(0xFF6FB8E9)),
                const SizedBox(width: 4),
                Text(
                  '${session.participantCount} participants',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _viewSessionResults(session),
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text('View Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFF888888),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSessionTypeColor(SessionType type) {
    switch (type) {
      case SessionType.quiz:
        return Colors.blue;
      case SessionType.study:
        return Colors.green;
      case SessionType.challenge:
        return Colors.orange;
      case SessionType.group:
        return Colors.purple;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _navigateToScheduleSession() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScheduleSessionScreen(),
      ),
    );

    if (result == true) {
      // Session was scheduled successfully, refresh the UI
      setState(() {});
    }
  }

  void _startSession(SocialSession session) async {
    final socialProvider =
        Provider.of<SocialSessionProvider>(context, listen: false);

    try {
      final startedSession = await socialProvider.startSession(session.id);
      if (startedSession != null && mounted) {
        // Navigate to live session screen
        _joinLiveSession(startedSession);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _joinSession(SocialSession session) async {
    final socialProvider =
        Provider.of<SocialSessionProvider>(context, listen: false);

    try {
      final success = await socialProvider.joinSession(
          session.id, socialProvider.currentUserId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined session!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelSession(SocialSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: const Text(
            'Are you sure you want to cancel this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final socialProvider =
          Provider.of<SocialSessionProvider>(context, listen: false);

      try {
        final success =
            await socialProvider.cancelSession(session.id, 'Cancelled by host');
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _joinLiveSession(SocialSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveSessionScreen(session: session),
      ),
    );
  }

  void _viewSessionDetails(SocialSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsScreen(session: session),
      ),
    );
  }

  void _viewSessionResults(SocialSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionResultsScreen(session: session),
      ),
    );
  }
}
