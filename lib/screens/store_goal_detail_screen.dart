import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/services/store_goal_service.dart';
import 'package:mooves/services/user_goal_progress_service.dart';
import 'package:mooves/screens/coupons_screen.dart';
import 'package:intl/intl.dart';

class StoreGoalDetailScreen extends StatefulWidget {
  final String goalId;

  const StoreGoalDetailScreen({super.key, required this.goalId});

  @override
  State<StoreGoalDetailScreen> createState() => _StoreGoalDetailScreenState();
}

class _StoreGoalDetailScreenState extends State<StoreGoalDetailScreen> {
  Map<String, dynamic>? _goal;
  Map<String, dynamic>? _progress;
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isMarkingComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadProgress();
  }

  Future<void> _loadGoal() async {
    try {
      final goal = await StoreGoalService.getGoal(widget.goalId);
      setState(() {
        _goal = goal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load goal: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await UserGoalProgressService.getGoalProgress(widget.goalId);
      setState(() {
        _progress = progress;
      });
    } catch (e) {
      // User might not have joined yet, which is OK
      debugPrint('No progress found: $e');
    }
  }

  Future<void> _joinGoal() async {
    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final result = await UserGoalProgressService.joinGoal(widget.goalId);
      if (result['success'] == true) {
        await _loadProgress();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Successfully joined challenge!',
                style: const TextStyle(color: AppColors.textOnPink),
              ),
              backgroundColor: AppColors.pinkCard,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate user joined
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to join challenge';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error joining challenge: $e';
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _markGoalComplete() async {
    setState(() {
      _isMarkingComplete = true;
      _error = null;
    });

    try {
      final result = await UserGoalProgressService.markGoalComplete(widget.goalId);
      if (result['success'] == true) {
        await _loadProgress();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Challenge marked as complete!',
                style: const TextStyle(color: AppColors.textOnPink),
              ),
              backgroundColor: AppColors.pinkCard,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to mark challenge as complete';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to mark challenge as complete',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error marking challenge as complete: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMarkingComplete = false;
      });
    }
  }

  String _formatDistance(int? meters) {
    if (meters == null) return '0 m';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '0 min';
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
          'Challenge Details',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            )
          : _goal == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load challenge',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textOnPink,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGoal,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store info
                      if (_goal!['store'] != null) ...[
                        Card(
                          color: AppColors.pinkCard,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (_goal!['store']['logo'] != null)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(_goal!['store']['logo']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (_goal!['store']['logo'] != null) const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _goal!['store']['storeName'] ?? 'Store',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textOnPink,
                                        ),
                                      ),
                                      if (_goal!['store']['location'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _goal!['store']['location'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Goal title and description
                      Text(
                        _goal!['title'] ?? 'Challenge',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPink,
                        ),
                      ),
                      if (_goal!['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _goal!['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Progress (if user has joined)
                      if (_progress != null) ...[
                        Card(
                          color: AppColors.pinkCard,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Progress',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textOnPink,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_goal!['targetDistanceMeters'] != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${_formatDistance(_progress!['currentDistanceMeters'] as int?)} / ${_formatDistance(_goal!['targetDistanceMeters'])}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textOnPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: (_progress!['currentDistanceMeters'] as int? ?? 0) /
                                        (_goal!['targetDistanceMeters'] as int),
                                    backgroundColor: AppColors.pinkMedium,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_goal!['targetDurationMinutes'] != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Duration',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${_formatDuration(_progress!['currentDurationMinutes'] as int?)} / ${_formatDuration(_goal!['targetDurationMinutes'])}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textOnPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: (_progress!['currentDurationMinutes'] as int? ?? 0) /
                                        (_goal!['targetDurationMinutes'] as int),
                                    backgroundColor: AppColors.pinkMedium,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_progress!['isCompleted'] == true) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentCoral.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.accentCoral,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.accentCoral,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Challenge Completed!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accentCoral,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const CouponsScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.local_offer),
                                      label: const Text('View Coupon'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryPurple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Manual completion button
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isMarkingComplete ? null : _markGoalComplete,
                                      icon: _isMarkingComplete
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.check_circle_outline),
                                      label: Text(_isMarkingComplete ? 'Marking Complete...' : 'Mark Challenge as Complete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentCoral,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap this button when you have completed the challenge',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Goal details
                      Card(
                        color: AppColors.pinkCard,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Challenge Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPink,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_goal!['targetDistanceMeters'] != null)
                                _buildDetailRow(
                                  Icons.straighten,
                                  'Target Distance',
                                  _formatDistance(_goal!['targetDistanceMeters']),
                                ),
                              if (_goal!['targetDurationMinutes'] != null)
                                _buildDetailRow(
                                  Icons.timer_outlined,
                                  'Target Duration',
                                  _formatDuration(_goal!['targetDurationMinutes']),
                                ),
                              if (_goal!['startDate'] != null)
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Start Date',
                                  DateFormat('MMM d, y').format(DateTime.parse(_goal!['startDate'])),
                                ),
                              if (_goal!['endDate'] != null)
                                _buildDetailRow(
                                  Icons.event,
                                  'End Date',
                                  DateFormat('MMM d, y').format(DateTime.parse(_goal!['endDate'])),
                                ),
                              if (_goal!['participantCount'] != null)
                                _buildDetailRow(
                                  Icons.people,
                                  'Participants',
                                  '${_goal!['participantCount']}',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reward info
                      Card(
                        color: AppColors.pinkCard,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.local_offer,
                                    color: AppColors.primaryPurple,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Reward',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textOnPink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _goal!['couponDescription'] ?? 'Complete this challenge to unlock your reward!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_goal!['couponDiscount'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_goal!['couponDiscount']}% off',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                              if (_goal!['couponDiscountAmount'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_goal!['couponDiscountAmount']} kr off',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Join button (if not already joined)
                      if (_progress == null) ...[
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _joinGoal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isJoining
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Join Challenge',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPink,
            ),
          ),
        ],
      ),
    );
  }
}

