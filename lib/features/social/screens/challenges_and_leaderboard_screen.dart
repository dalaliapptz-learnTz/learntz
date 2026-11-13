import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learners/learner_providers.dart';
import '../social_models.dart';
import '../social_providers.dart';

class ChallengesAndLeaderboardScreen extends ConsumerStatefulWidget {
  const ChallengesAndLeaderboardScreen({super.key});

  @override
  ConsumerState<ChallengesAndLeaderboardScreen> createState() =>
      _ChallengesAndLeaderboardScreenState();
}

class _ChallengesAndLeaderboardScreenState
    extends ConsumerState<ChallengesAndLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLearner = ref.watch(activeLearnerProvider);

    if (activeLearner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenges & Leaderboards')),
        body: const Center(
          child: Text('Please select an active learner to view competitions.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Challenges & Arena'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Competitions'),
            Tab(icon: Icon(Icons.leaderboard_outlined), text: 'Leaderboard'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(activeChallengesProvider(activeLearner.id));
              ref.invalidate(communityLeaderboardProvider((
                scope: 'national',
                scopeId: activeLearner.countryCode,
                limit: 25,
              )));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChallengesTab(learnerId: activeLearner.id),
          _LeaderboardTab(
            countryCode: activeLearner.countryCode,
            schoolId: activeLearner.schoolId,
            gradeId: activeLearner.gradeId,
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends ConsumerWidget {
  final String learnerId;

  const _ChallengesTab({required this.learnerId});

  String _formatType(String type) {
    switch (type) {
      case 'speed_math':
        return 'Speed Math ⚡';
      case 'weekly_olympiad':
        return 'Weekly Olympiad 🏅';
      case 'monthly_championship':
        return 'Championship 🏆';
      case 'science_quest':
        return 'Science Quest 🔬';
      default:
        return 'Daily Quiz 🎯';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider(learnerId));

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(
            child: Text('No active competitions at the moment. Check back soon!'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final hasCompleted = challenge.attemptStatus == 'completed';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatType(challenge.challengeType),
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '+${challenge.rewardPoints} pts',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      challenge.description,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (hasCompleted) ...[
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Completed (Score: ${challenge.learnerScore}%)',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.timer_outlined,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge.totalQuestions} questions',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                        const Spacer(),
                        FilledButton(
                          onPressed: () => _startChallenge(context, ref, challenge),
                          child: Text(hasCompleted ? 'Try Again' : 'Enter Challenge'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startChallenge(
    BuildContext context,
    WidgetRef ref,
    AcademicChallenge challenge,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ChallengeRunnerDialog(
        challenge: challenge,
        learnerId: learnerId,
        onCompleted: () {
          ref.invalidate(activeChallengesProvider(learnerId));
          ref.invalidate(learnerSocialProfileProvider(learnerId));
        },
      ),
    );
  }
}

class _ChallengeRunnerDialog extends StatefulWidget {
  final AcademicChallenge challenge;
  final String learnerId;
  final VoidCallback onCompleted;

  const _ChallengeRunnerDialog({
    required this.challenge,
    required this.learnerId,
    required this.onCompleted,
  });

  @override
  State<_ChallengeRunnerDialog> createState() => _ChallengeRunnerDialogState();
}

class _ChallengeRunnerDialogState extends State<_ChallengeRunnerDialog> {
  int _currentQuestionIndex = 0;
  final List<int> _selectedAnswers = [];
  late DateTime _startTime;
  bool _isSubmitting = false;

  // Sample mental math rapid questions
  final List<({String question, List<String> options, int correctIndex})>
      _questions = [
    (
      question: 'What is 15 * 8?',
      options: ['100', '120', '140', '110'],
      correctIndex: 1
    ),
    (
      question: 'What is 144 / 12?',
      options: ['10', '11', '12', '14'],
      correctIndex: 2
    ),
    (
      question: 'What is 45 + 55?',
      options: ['90', '95', '100', '105'],
      correctIndex: 2
    ),
    (
      question: 'What is 7 * 9?',
      options: ['56', '63', '64', '72'],
      correctIndex: 1
    ),
    (
      question: 'What is the square root of 81?',
      options: ['7', '8', '9', '10'],
      correctIndex: 2
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _handleAnswer(int optionIndex) async {
    _selectedAnswers.add(optionIndex);

    if (_currentQuestionIndex + 1 < _questions.length) {
      setState(() => _currentQuestionIndex++);
    } else {
      // Calculate score
      setState(() => _isSubmitting = true);
      int correctCount = 0;
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == _questions[i].correctIndex) {
          correctCount++;
        }
      }
      final scorePercent = ((correctCount / _questions.length) * 100).round();
      final timeSpent = DateTime.now().difference(_startTime).inSeconds;

      final container = ProviderScope.containerOf(context, listen: false);
      final repo = container.read(socialRepositoryProvider);

      try {
        final result = await repo.submitChallengeAttempt(
          challengeId: widget.challenge.id,
          learnerId: widget.learnerId,
          score: scorePercent,
          timeSpentSeconds: timeSpent,
          answers: _selectedAnswers,
        );

        if (mounted) {
          Navigator.pop(context);
          widget.onCompleted();

          final earnedPoints = result['earned_points'] ?? 0;
          final awardedBadge = result['awarded_badge'];

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('🎉 Challenge Completed!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your Score: $scorePercent%',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Points Earned: +$earnedPoints pts'),
                  if (awardedBadge != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.military_tech, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text('Badge Awarded: $awardedBadge',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Great!'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Grading attempt...'),
          ],
        ),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];

    return AlertDialog(
      title: Row(
        children: [
          Text('Question ${_currentQuestionIndex + 1} of ${_questions.length}'),
          const Spacer(),
          Text(
            widget.challenge.title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              currentQ.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(currentQ.options.length, (optIdx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => _handleAnswer(optIdx),
                  child: Text(
                    '   ${String.fromCharCode(65 + optIdx)}. ${currentQ.options[optIdx]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quit'),
        ),
      ],
    );
  }
}

class _LeaderboardTab extends ConsumerStatefulWidget {
  final String countryCode;
  final String? schoolId;
  final String? gradeId;

  const _LeaderboardTab({
    required this.countryCode,
    this.schoolId,
    this.gradeId,
  });

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  String _selectedScope = 'national';

  @override
  Widget build(BuildContext context) {
    final scopeId = _selectedScope == 'national'
        ? widget.countryCode
        : (_selectedScope == 'school'
            ? (widget.schoolId ?? widget.countryCode)
            : (widget.gradeId ?? widget.countryCode));

    final leaderboardAsync = ref.watch(communityLeaderboardProvider((
      scope: _selectedScope,
      scopeId: scopeId,
      limit: 25,
    )));

    return Column(
      children: [
        // Scope Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'national',
                label: Text('${widget.countryCode} National 🇹🇿'),
              ),
              if (widget.schoolId != null)
                const ButtonSegment(
                  value: 'school',
                  label: Text('School 🏫'),
                ),
              if (widget.gradeId != null)
                const ButtonSegment(
                  value: 'class',
                  label: Text('Class 📚'),
                ),
            ],
            selected: {_selectedScope},
            onSelectionChanged: (val) {
              setState(() => _selectedScope = val.first);
            },
          ),
        ),
        const Divider(height: 1),

        // Leaderboard List
        Expanded(
          child: leaderboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Text('No participants on the leaderboard yet.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final avatar = getAvatarPreset(entry.avatarPreset);
                  final isTop3 = entry.rank <= 3;

                  Color rankColor = Colors.grey.shade700;
                  if (entry.rank == 1) rankColor = Colors.amber.shade700;
                  if (entry.rank == 2) rankColor = Colors.blueGrey;
                  if (entry.rank == 3) rankColor = Colors.brown;

                  return Card(
                    elevation: isTop3 ? 2 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isTop3
                          ? BorderSide(color: rankColor.withValues(alpha: 0.5))
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(
                              '#${entry.rank}',
                              style: TextStyle(
                                fontSize: isTop3 ? 18 : 15,
                                fontWeight: FontWeight.bold,
                                color: rankColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: avatar.primaryColor,
                            child: Icon(avatar.icon,
                                size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (entry.schoolName != null)
                                  Text(
                                    entry.schoolName!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${entry.points} pts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.badgesCount > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.military_tech,
                                        color: Colors.indigo, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${entry.badgesCount} badges',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
