import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/social_session.dart';

class SessionResultsScreen extends StatefulWidget {
  final SocialSession session;

  const SessionResultsScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends State<SessionResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Session Results',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Results'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_follow_up',
                child: ListTile(
                  leading: Icon(Icons.event),
                  title: Text('Schedule Follow-up'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Session summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'COMPLETED',
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
                _buildSessionSummaryStats(),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.analytics)),
              Tab(text: 'Rankings', icon: Icon(Icons.leaderboard)),
              Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
              Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRankingsTab(),
                _buildPerformanceTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleFollowUpSession,
        icon: const Icon(Icons.refresh),
        label: const Text('Schedule Follow-up'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSessionSummaryStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryStatItem(
          'Duration',
          '${widget.session.duration.inMinutes} min',
          Icons.timer,
          Colors.blue,
        ),
        _buildSummaryStatItem(
          'Participants',
          '${widget.session.participantIds.length}',
          Icons.people,
          Colors.green,
        ),
        _buildSummaryStatItem(
          'Date',
          DateFormat('MMM dd').format(widget.session.scheduledTime),
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildSummaryStatItem(
          'Success Rate',
          '87%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session completion chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Completion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompletionIndicator('Completed', 85, Colors.green),
                            const SizedBox(height: 8),
                            _buildCompletionIndicator('Partially Completed', 12, Colors.orange),
                            const SizedBox(height: 8),
                            _buildCompletionIndicator('Not Completed', 3, Colors.red),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: 0.85,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            Text(
                              '85%',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Key metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Metrics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Average Score',
                          '84.2%',
                          Icons.grade,
                          Colors.blue,
                          '+5.3%',
                          true,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Response Time',
                          '2.3s',
                          Icons.speed,
                          Colors.orange,
                          '-0.7s',
                          true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Engagement',
                          '92%',
                          Icons.favorite,
                          Colors.red,
                          '+12%',
                          true,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Retention',
                          '78%',
                          Icons.psychology,
                          Colors.purple,
                          '+3%',
                          true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Session timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineItem('Session Started', '14:00', Icons.play_arrow, Colors.green),
                  _buildTimelineItem('First Quiz', '14:05', Icons.quiz, Colors.blue),
                  _buildTimelineItem('Group Discussion', '14:15', Icons.chat, Colors.orange),
                  _buildTimelineItem('Second Quiz', '14:25', Icons.quiz, Colors.blue),
                  _buildTimelineItem('Final Review', '14:35', Icons.rate_review, Colors.purple),
                  _buildTimelineItem('Session Ended', '14:45', Icons.stop, Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionIndicator(String label, int percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          '$percentage%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    // Mock participant data with results
    final participants = [
      ParticipantResult(
        id: widget.session.hostId,
        name: widget.session.hostName,
        score: 95.0,
        accuracy: 94.0,
        responseTime: 1.8,
        streak: 12,
        achievements: ['Perfect Start', 'Speed Demon', 'Knowledge Master'],
        isHost: true,
      ),
      ParticipantResult(
        id: '2',
        name: 'Sarah Chen',
        score: 89.0,
        accuracy: 91.0,
        responseTime: 2.1,
        streak: 8,
        achievements: ['Fast Learner', 'Consistent'],
        isHost: false,
      ),
      ParticipantResult(
        id: '3',
        name: 'Mike Rodriguez',
        score: 82.0,
        accuracy: 86.0,
        responseTime: 2.8,
        streak: 5,
        achievements: ['Good Progress'],
        isHost: false,
      ),
      ParticipantResult(
        id: '4',
        name: 'Emma Wilson',
        score: 78.0,
        accuracy: 82.0,
        responseTime: 3.2,
        streak: 3,
        achievements: ['Steady Learner'],
        isHost: false,
      ),
    ];

    return Column(
      children: [
        // Podium for top 3
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (participants.length > 1) _buildPodiumPosition(participants[1], 2, 60),
              if (participants.isNotEmpty) _buildPodiumPosition(participants[0], 1, 80),
              if (participants.length > 2) _buildPodiumPosition(participants[2], 3, 40),
            ],
          ),
        ),
        const Divider(),
        // Full rankings list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _buildRankingItem(participant, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPosition(ParticipantResult participant, int position, double height) {
    const goldColor = Color(0xFFFFD700);
    final colors = [null, goldColor, Colors.grey, const Color(0xFFCD7F32)]; // Gold, Silver, Bronze
    final icons = [null, Icons.looks_one, Icons.looks_two, Icons.looks_3];

    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: colors[position] ?? Colors.grey,
          child: Text(
            participant.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          participant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          '${participant.score.toInt()}%',
          style: TextStyle(
            color: colors[position],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: colors[position]?.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: colors[position] ?? Colors.grey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icons[position],
                color: colors[position],
                size: 24,
              ),
              Text(
                '#$position',
                style: TextStyle(
                  color: colors[position],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingItem(ParticipantResult participant, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                participant.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (participant.isHost)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(participant.name),
            if (participant.isHost) ...[
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
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Score: ${participant.score.toInt()}%'),
                const SizedBox(width: 16),
                Text('Accuracy: ${participant.accuracy.toInt()}%'),
              ],
            ),
            if (participant.achievements.isNotEmpty)
              Wrap(
                spacing: 4,
                children: participant.achievements.take(2).map((achievement) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ).toList(),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                Text(
                  '${participant.streak}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '${participant.responseTime}s avg',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance trends
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Trends',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Performance Chart',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Score progression over time',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Question breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question Analysis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestionBreakdown('Easy Questions', 12, 11, Colors.green),
                  const SizedBox(height: 8),
                  _buildQuestionBreakdown('Medium Questions', 8, 6, Colors.orange),
                  const SizedBox(height: 8),
                  _buildQuestionBreakdown('Hard Questions', 5, 3, Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Topics performance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Topics Performance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopicPerformance('Mathematics', 0.92, Colors.blue),
                  const SizedBox(height: 8),
                  _buildTopicPerformance('Physics', 0.85, Colors.green),
                  const SizedBox(height: 8),
                  _buildTopicPerformance('Chemistry', 0.78, Colors.orange),
                  const SizedBox(height: 8),
                  _buildTopicPerformance('Biology', 0.71, Colors.purple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBreakdown(String difficulty, int total, int correct, Color color) {
    final accuracy = (correct / total * 100).toInt();
    
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                difficulty,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$correct/$total correct ($accuracy%)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          '$accuracy%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicPerformance(String topic, double performance, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                topic,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${(performance * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: performance,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Study Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    Icons.trending_up,
                    'Strong Performance',
                    'Mathematics and Physics showed excellent results with 90%+ accuracy.',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.watch_later,
                    'Response Time',
                    'Average response time improved by 15% compared to previous sessions.',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.warning,
                    'Areas for Improvement',
                    'Chemistry and Biology topics need more focus in future study sessions.',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.recommend, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendationItem(
                    'Schedule Follow-up Session',
                    'Based on group performance, schedule another session focused on Chemistry topics.',
                    Icons.event,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationItem(
                    'Review Weak Areas',
                    'Create targeted flashcards for Biology concepts that showed lower accuracy.',
                    Icons.library_books,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationItem(
                    'Celebrate Achievements',
                    'Share success in Mathematics and Physics with the study group.',
                    Icons.celebration,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Session feedback
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.feedback, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Session Feedback',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeedbackItem('Engagement', 4.2, Icons.favorite),
                      ),
                      Expanded(
                        child: _buildFeedbackItem('Difficulty', 3.8, Icons.school),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeedbackItem('Pace', 4.0, Icons.speed),
                      ),
                      Expanded(
                        child: _buildFeedbackItem('Overall', 4.1, Icons.star),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(String label, double rating, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              Icon(
                index < rating.floor() ? Icons.star : 
                index < rating ? Icons.star_half : Icons.star_outline,
                size: 12,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    const goldColor = Color(0xFFFFD700);
    switch (rank) {
      case 1: return goldColor;
      case 2: return Colors.grey;
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing results...')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exporting data...')),
        );
        break;
      case 'schedule_follow_up':
        _scheduleFollowUpSession();
        break;
    }
  }

  void _scheduleFollowUpSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening session scheduler...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Data model for participant results
class ParticipantResult {
  final String id;
  final String name;
  final double score;
  final double accuracy;
  final double responseTime;
  final int streak;
  final List<String> achievements;
  final bool isHost;

  ParticipantResult({
    required this.id,
    required this.name,
    required this.score,
    required this.accuracy,
    required this.responseTime,
    required this.streak,
    required this.achievements,
    required this.isHost,
  });
}