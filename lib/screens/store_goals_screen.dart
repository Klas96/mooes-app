import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/services/store_goal_service.dart';
import 'package:mooves/services/user_goal_progress_service.dart';
import 'package:mooves/screens/store_goal_detail_screen.dart';
import 'package:intl/intl.dart';

class StoreGoalsScreen extends StatefulWidget {
  const StoreGoalsScreen({super.key});

  @override
  State<StoreGoalsScreen> createState() => _StoreGoalsScreenState();
}

class _StoreGoalsScreenState extends State<StoreGoalsScreen> {
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final goals = await StoreGoalService.getActiveGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load goals: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDistance(int? meters) {
    if (meters == null) return '';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(0)} km';
    }
    return '$meters m';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '';
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours h';
      }
      return '$hours h $mins min';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard,
        elevation: 0,
        title: const Text(
          'Store Challenges',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGoals,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.textOnPink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadGoals,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _goals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No active challenges',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnPink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new challenges!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          final store = goal['store'] as Map<String, dynamic>?;
                          final isFull = goal['isFull'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppColors.pinkCard,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StoreGoalDetailScreen(goalId: goal['id']),
                                  ),
                                );
                                if (result == true) {
                                  _loadGoals(); // Refresh if user joined
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Store name
                                    if (store != null) ...[
                                      Row(
                                        children: [
                                          if (store['logo'] != null)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: NetworkImage(store['logo']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          if (store['logo'] != null) const SizedBox(width: 8),
                                          Text(
                                            store['storeName'] ?? 'Store',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    // Goal title
                                    Text(
                                      goal['title'] ?? 'Challenge',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textOnPink,
                                      ),
                                    ),
                                    if (goal['description'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        goal['description'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    // Goal targets
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        if (goal['targetDistanceMeters'] != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.straighten,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDistance(goal['targetDistanceMeters']),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textOnPink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (goal['targetDurationMinutes'] != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.timer_outlined,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(goal['targetDurationMinutes']),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textOnPink,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Dates and participants
                                    Row(
                                      children: [
                                        if (goal['startDate'] != null)
                                          Text(
                                            'Starts: ${DateFormat('MMM d, y').format(DateTime.parse(goal['startDate']))}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        if (goal['endDate'] != null) ...[
                                          const SizedBox(width: 16),
                                          Text(
                                            'Ends: ${DateFormat('MMM d, y').format(DateTime.parse(goal['endDate']))}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (goal['participantCount'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${goal['participantCount']} participants',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (isFull) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentCoral.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Full',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accentCoral,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Reward preview
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primaryPurple.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.local_offer,
                                            size: 20,
                                            color: AppColors.primaryPurple,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              goal['couponDescription'] ?? 'Reward coupon',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textOnPink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

