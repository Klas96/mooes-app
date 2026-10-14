import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/models/training_entry.dart';
import 'package:mooves/screens/reward_qr_screen.dart';
import 'package:mooves/screens/store_goal_detail_screen.dart';
import 'package:mooves/screens/coupons_screen.dart';
import 'package:mooves/services/health_connect_service.dart';
import 'package:mooves/services/google_fit_service.dart';
import 'package:mooves/services/profile_service.dart';
import 'package:mooves/services/user_goal_progress_service.dart';
import 'package:mooves/services/training_session_service.dart';
import 'package:mooves/widgets/app_bar_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.navigateToTab});

  final void Function(int index) navigateToTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  static const _storageKey = 'training_entries';

  List<TrainingEntry> _entries = [];
  List<Map<String, dynamic>> _activeGoals = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEntries();
    _syncGoogleFit();
    _loadActiveGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveGoals() async {
    try {
      final progress = await UserGoalProgressService.getUserProgress();
      // Filter to only show active, non-completed goals
      setState(() {
        _activeGoals = progress
            .where((p) => p['isCompleted'] != true && p['goal'] != null)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading active goals: $e');
    }
  }

  Future<void> _syncGoogleFit() async {
    try {
      // Try syncing from Google Fit
      final googleFitStatus = await GoogleFitService.getStatus();
      if (googleFitStatus['connected'] == true) {
        // Sync activities from last 7 days
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));
        
        final result = await GoogleFitService.syncActivities(
          startDate: startDate,
          endDate: endDate,
        );

        if (result['success'] == true) {
          // Reload entries to show synced activities
          await _loadEntries();
          
          // Check goals for synced activities
          await _checkGoalsForEntries();
          
          if (mounted && result['activities'] != null && (result['activities'] as List).isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Synced ${(result['activities'] as List).length} activities from Google Fit',
                  style: const TextStyle(color: AppColors.textOnPink),
                ),
                backgroundColor: AppColors.pinkCard,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
      
      // Also try syncing from Health Connect if connected
      final healthStatus = await HealthConnectService.getStatus();
      if (healthStatus['connected'] == true) {
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));
        
        final result = await HealthConnectService.syncActivities(
          startDate: startDate,
          endDate: endDate,
        );

        if (result['success'] == true) {
          await _loadEntries();
          await _checkGoalsForEntries();
          
          if (mounted && result['newActivitiesCount'] != null && result['newActivitiesCount'] > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Synced ${result['newActivitiesCount']} activities from Health Connect',
                  style: const TextStyle(color: AppColors.textOnPink),
                ),
                backgroundColor: AppColors.pinkCard,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Silently fail - sync is optional
      debugPrint('Fitness service sync error: $e');
    }
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == null) {
        setState(() {
          _entries = [];
          _isLoading = false;
        });
        return;
      }

      final decoded = json.decode(stored) as List<dynamic>;
      final entries = decoded
          .map((item) => TrainingEntry.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _entries = entries;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load training history: $e';
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }

  Future<void> _showAddEntrySheet({TrainingEntry? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final durationController = TextEditingController(
      text: existing?.durationMinutes != null
          ? existing!.durationMinutes.toString()
          : '',
    );
    final distanceController = TextEditingController(
      text: existing?.distanceKm != null
          ? existing!.distanceKm.toString()
          : '',
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();

    final result = await showModalBottomSheet<TrainingEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pinkCard, // Pink background for modal
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.pinkCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Log training session'
                          : 'Edit training session',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Morning Run, Strength Workout',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: distanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Distance (km)',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Date: ${_formatDate(selectedDate)}',
                        style: const TextStyle(color: AppColors.textOnPink),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final title = titleController.text.trim();
                              final durationRaw =
                                  durationController.text.trim();
                              final duration = durationRaw.isEmpty
                                  ? null
                                  : int.tryParse(durationRaw);
                              final distanceRaw =
                                  distanceController.text.trim();
                              final distance = distanceRaw.isEmpty
                                  ? null
                                  : double.tryParse(distanceRaw);

                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Please add a title for your session.',
                                      style: TextStyle(color: AppColors.textOnPink),
                                    ),
                                    backgroundColor: AppColors.pinkCard,
                                  ),
                                );
                                return;
                              }

                              final entry = (existing ??
                                      TrainingEntry(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        title: title,
                                        date: selectedDate,
                                      ))
                                  .copyWith(
                                title: title,
                                date: selectedDate,
                                durationMinutes: duration,
                                distanceKm: distance,
                              );

                              Navigator.of(context).pop(entry);
                            },
                            // Update store goal progress after creating/updating entry
                            // Note: Backend will automatically update progress, but we refresh UI
                            child: Text(existing == null
                                ? 'Save session'
                                : 'Update session'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      // Save to backend first
      final entryToSave = result; // Non-nullable since result is checked
      try {
        final dateStr = result.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
        
        if (existing == null) {
          // Create new session
          debugPrint('📝 Creating session on backend:');
          debugPrint('  - Title: ${result.title}');
          debugPrint('  - Date: $dateStr');
          debugPrint('  - Distance: ${result.distanceKm} km');
          debugPrint('  - Duration: ${result.durationMinutes} minutes');
          
          final response = await TrainingSessionService.createSession(
            title: result.title,
            date: dateStr,
            durationMinutes: result.durationMinutes,
            distanceKm: result.distanceKm,
            goalReached: result.goalReached,
          );
          
          if (response['success'] == true && response['session'] != null) {
            // Session created successfully on backend
            debugPrint('✅ Session created successfully on backend');
            debugPrint('  - Response: ${response['session']}');
          } else {
            debugPrint('❌ Failed to create session: ${response['message']}');
          }
        } else {
          // Update existing session - need to check if it has a backend ID
          // For now, we'll try to update using the local ID
          // In a production app, you'd want to store backend IDs separately
          await TrainingSessionService.updateSession(
            id: result.id,
            title: result.title,
            date: dateStr,
            durationMinutes: result.durationMinutes,
            distanceKm: result.distanceKm,
            goalReached: result.goalReached,
          );
        }
      } catch (e) {
        debugPrint('Error syncing session to backend: $e');
        // Continue with local save even if backend sync fails
      }
      
      setState(() {
        if (existing == null) {
          _entries = [entryToSave, ..._entries];
        } else {
          _entries = _entries
              .map((entry) => entry.id == entryToSave.id ? entryToSave : entry)
              .toList();
        }
      });
      await _saveEntries();
      // Update store goal progress after creating/updating entry
      // Add a small delay to allow backend to process the update
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadActiveGoals();
    }
  }

  Future<void> _toggleGoalReached(TrainingEntry entry, bool reached) async {
    final updatedEntry = entry.copyWith(goalReached: reached);
    setState(() {
      _entries = _entries
          .map((e) => e.id == entry.id ? updatedEntry : e)
          .toList();
    });
    await _saveEntries();

    if (reached && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RewardQrScreen(entry: updatedEntry),
        ),
      );
    }
  }

  Future<void> _deleteEntry(TrainingEntry entry) async {
    // Delete from backend first
    try {
      await TrainingSessionService.deleteSession(entry.id);
    } catch (e) {
      debugPrint('Error deleting session from backend: $e');
      // Continue with local delete even if backend delete fails
    }
    
    setState(() {
      _entries = _entries.where((e) => e.id != entry.id).toList();
    });
    await _saveEntries();
    // Update store goal progress after deleting entry
    await _loadActiveGoals();
  }

  Future<void> _checkGoalsForEntries() async {
    try {
      // Get user's goals from profile
      final profile = await ProfileService.getProfile();
      final goalDistance = profile['runningGoalDistanceKm'] != null 
          ? (profile['runningGoalDistanceKm'] as num).toDouble() 
          : null;
      final goalDuration = profile['runningGoalDurationMinutes'] as int?;
      final goalPeriod = profile['goalPeriod'] as String? ?? 'daily';

      if (goalDistance == null && goalDuration == null) {
        return; // No goals set
      }

      // Group entries by period
      final now = DateTime.now();
      final entriesByPeriod = <String, List<TrainingEntry>>{};

      for (final entry in _entries) {
        String periodKey;
        if (goalPeriod == 'daily') {
          periodKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
        } else if (goalPeriod == 'weekly') {
          final weekStart = entry.date.subtract(Duration(days: entry.date.weekday - 1));
          periodKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
        } else { // monthly
          periodKey = '${entry.date.year}-${entry.date.month}';
        }

        if (!entriesByPeriod.containsKey(periodKey)) {
          entriesByPeriod[periodKey] = [];
        }
        entriesByPeriod[periodKey]!.add(entry);
      }

      // Check goals for each period
      bool updated = false;
      for (final periodEntries in entriesByPeriod.values) {
        final totalDistance = periodEntries
            .where((e) => e.distanceKm != null)
            .fold<double>(0.0, (sum, e) => sum + (e.distanceKm ?? 0));
        final totalDuration = periodEntries
            .where((e) => e.durationMinutes != null)
            .fold<int>(0, (sum, e) => sum + (e.durationMinutes ?? 0));

        final distanceGoalReached = goalDistance == null || totalDistance >= goalDistance;
        final durationGoalReached = goalDuration == null || totalDuration >= goalDuration;
        final goalReached = distanceGoalReached && durationGoalReached;

        // Update entries in this period
        // Note: We still track goalReached for display purposes, but don't automatically show QR
        // Users will manually mark challenges as complete
        for (final entry in periodEntries) {
          if (entry.goalReached != goalReached) {
            final updatedEntry = entry.copyWith(goalReached: goalReached);
            _entries = _entries.map((e) => e.id == entry.id ? updatedEntry : e).toList();
            updated = true;

            // Disabled automatic QR screen - users will manually mark challenges as complete
            // if (goalReached && mounted) {
            //   Future.delayed(const Duration(milliseconds: 500), () {
            //     if (mounted) {
            //       Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (_) => RewardQrScreen(entry: updatedEntry),
            //         ),
            //       );
            //     }
            //   });
            // }
          }
        }
      }

      if (updated) {
        await _saveEntries();
        if (mounted) {
          setState(() {}); // Refresh UI
        }
      }
    } catch (e) {
      debugPrint('Error checking goals: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _calculateStatistics() {
    if (_entries.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDistanceKm': 0.0,
        'totalDurationMinutes': 0,
        'avgDistanceKm': 0.0,
        'avgDurationMinutes': 0.0,
        'sessionsThisWeek': 0,
        'distanceThisWeek': 0.0,
        'sessionsThisMonth': 0,
        'distanceThisMonth': 0.0,
      };
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    int totalSessions = _entries.length;
    double totalDistanceKm = 0.0;
    int totalDurationMinutes = 0;
    int sessionsThisWeek = 0;
    double distanceThisWeek = 0.0;
    int sessionsThisMonth = 0;
    double distanceThisMonth = 0.0;

    for (final entry in _entries) {
      if (entry.distanceKm != null) {
        totalDistanceKm += entry.distanceKm!;
        if (entry.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
          distanceThisWeek += entry.distanceKm!;
        }
        if (entry.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
          distanceThisMonth += entry.distanceKm!;
        }
      }
      if (entry.durationMinutes != null) {
        totalDurationMinutes += entry.durationMinutes!;
      }
      if (entry.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        sessionsThisWeek++;
      }
      if (entry.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        sessionsThisMonth++;
      }
    }

    final avgDistanceKm = totalSessions > 0 ? totalDistanceKm / totalSessions : 0.0;
    final avgDurationMinutes = totalSessions > 0 ? totalDurationMinutes / totalSessions : 0.0;

    return {
      'totalSessions': totalSessions,
      'totalDistanceKm': totalDistanceKm,
      'totalDurationMinutes': totalDurationMinutes,
      'avgDistanceKm': avgDistanceKm,
      'avgDurationMinutes': avgDurationMinutes,
      'sessionsThisWeek': sessionsThisWeek,
      'distanceThisWeek': distanceThisWeek,
      'sessionsThisMonth': sessionsThisMonth,
      'distanceThisMonth': distanceThisMonth,
    };
  }

  Widget _buildStatisticsCard() {
    final stats = _calculateStatistics();

    String _formatDistance(double km) {
      if (km == 0) return '0 km';
      if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
      return '${km.toStringAsFixed(1)} km';
    }

    String _formatDuration(int minutes) {
      if (minutes == 0) return '0 min';
      if (minutes < 60) return '$minutes min';
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '$hours h';
      return '$hours h $mins min';
    }

    String _formatDurationDouble(double minutes) {
      if (minutes == 0) return '0 min';
      if (minutes < 60) return '${minutes.toStringAsFixed(0)} min';
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).round();
      if (mins == 0) return '$hours h';
      return '$hours h $mins min';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.pinkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primaryPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${stats['totalSessions']}',
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Total Distance',
                    _formatDistance(stats['totalDistanceKm'] as double),
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Duration',
                    _formatDuration(stats['totalDurationMinutes'] as int),
                    Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Avg Distance',
                    _formatDistance(stats['avgDistanceKm'] as double),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.pinkMedium),
            const SizedBox(height: 12),
            // This week
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    '${stats['sessionsThisWeek']}',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Distance',
                    _formatDistance(stats['distanceThisWeek'] as double),
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // This month
            const Text(
              'This Month',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    '${stats['sessionsThisMonth']}',
                    Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Distance',
                    _formatDistance(stats['distanceThisMonth'] as double),
                    Icons.straighten,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPink,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGoalProgressCard(Map<String, dynamic> progress) {
    final goal = progress['goal'] as Map<String, dynamic>?;
    if (goal == null) return const SizedBox.shrink();

    final progressPercent = progress['progressPercent'] as int? ?? 0;
    final isCompleted = progress['isCompleted'] == true;

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
        if (mins == 0) return '$hours h';
        return '$hours h $mins min';
      }
      return '$minutes min';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.pinkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreGoalDetailScreen(goalId: goal['id']),
            ),
          ).then((_) => _loadActiveGoals());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal['title'] ?? 'Challenge',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPink,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentCoral.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Completed!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentCoral,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (goal['targetDistanceMeters'] != null) ...[
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
                      '${_formatDistance(progress['currentDistanceMeters'] as int?)} / ${_formatDistance(goal['targetDistanceMeters'])}',
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
                  value: () {
                    final current = ((progress['currentDistanceMeters'] as num?)?.toDouble() ?? 0.0);
                    final target = ((goal['targetDistanceMeters'] as num?)?.toDouble() ?? 1.0);
                    if (target <= 0) return 0.0;
                    final progressValue = (current / target).clamp(0.0, 1.0);
                    return progressValue;
                  }(),
                  backgroundColor: AppColors.pinkMedium,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  minHeight: 8,
                ),
              ],
              if (goal['targetDurationMinutes'] != null) ...[
                if (goal['targetDistanceMeters'] != null) const SizedBox(height: 12),
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
                      '${_formatDuration(progress['currentDurationMinutes'] as int?)} / ${_formatDuration(goal['targetDurationMinutes'])}',
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
                  value: () {
                    final current = ((progress['currentDurationMinutes'] as num?)?.toDouble() ?? 0.0);
                    final target = ((goal['targetDurationMinutes'] as num?)?.toDouble() ?? 1.0);
                    if (target <= 0) return 0.0;
                    final progressValue = (current / target).clamp(0.0, 1.0);
                    return progressValue;
                  }(),
                  backgroundColor: AppColors.pinkMedium,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  minHeight: 8,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '$progressPercent% complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingEntryCard(TrainingEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.pinkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnPink,
                              ),
                            )),
                          if (entry.goalReached)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentCoral.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Goal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentCoral,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          if (entry.durationMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16,
                                    color: AppColors.textSecondaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.durationMinutes} min',
                                  style: const TextStyle(
                                    color: AppColors.textOnPink,
                                  ),
                                ),
                              ],
                            ),
                          if (entry.distanceKm != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.straighten,
                                    size: 16,
                                    color: AppColors.textSecondaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.distanceKm!.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: AppColors.textOnPink,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.notes!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textOnPink,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${_formatDate(entry.date)}',
                        style: const TextStyle(color: AppColors.textOnPink),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textOnPink),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEntrySheet(existing: entry);
                    } else if (value == 'delete') {
                      _deleteEntry(entry);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit',
                        style: TextStyle(color: AppColors.textOnPink),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.textOnPink),
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPink,
      appBar: AppBar(
        backgroundColor: AppColors.pinkCard,
        elevation: 0,
        title: const AppBarLogo(title: 'Training log'),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          labelColor: AppColors.textOnPink,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Sessions'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEntrySheet(),
              icon: const Icon(Icons.add),
              label: const Text('Log session'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadEntries();
          await _syncGoogleFit();
          await _loadActiveGoals();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // Sessions tab
            _entries.isEmpty && _activeGoals.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 80),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.pinkCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: AppColors.accentCoral,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Let's move!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Log your training sessions and mark the workouts where you reached a goal. We will generate a reward QR code once goals are completed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEntrySheet(),
                        icon: const Icon(Icons.add),
                        label: const Text('Log first session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Store challenges and coupons buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              widget.navigateToTab(1); // Navigate to Rewards tab (challenges & coupons)
                            },
                            icon: const Icon(Icons.local_offer),
                            label: const Text('Rewards'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              side: const BorderSide(color: AppColors.primaryPurple),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active store goals progress section
                      if (_activeGoals.isNotEmpty) ...[
                        const Text(
                          'Active Challenges',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._activeGoals.map((progress) => _buildGoalProgressCard(progress)),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      // Training entries
                      const Text(
                        'Training Sessions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._entries.asMap().entries.map((entry) => _buildTrainingEntryCard(entry.value)),
                    ],
                  ),
            // Statistics tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_entries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No statistics available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnPink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Log some training sessions to see your statistics',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildStatisticsCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
