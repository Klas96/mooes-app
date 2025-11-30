import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mooves/constants/colors.dart';
import 'package:mooves/models/training_entry.dart';
import 'package:mooves/screens/reward_qr_screen.dart';
import 'package:mooves/screens/store_goals_screen.dart';
import 'package:mooves/screens/store_goal_detail_screen.dart';
import 'package:mooves/screens/coupons_screen.dart';
import 'package:mooves/services/health_connect_service.dart';
import 'package:mooves/services/google_fit_service.dart';
import 'package:mooves/services/profile_service.dart';
import 'package:mooves/services/user_goal_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.navigateToTab});

  final void Function(int index) navigateToTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const _storageKey = 'training_entries';

  List<TrainingEntry> _entries = [];
  List<Map<String, dynamic>> _activeGoals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _syncGoogleFit();
    _loadActiveGoals();
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
    final notesController = TextEditingController(text: existing?.notes ?? '');
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
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'How did it feel? Any personal records?',
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
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
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
      setState(() {
        if (existing == null) {
          _entries = [result, ..._entries];
        } else {
          _entries = _entries
              .map((entry) => entry.id == result.id ? result : entry)
              .toList();
        }
      });
      await _saveEntries();
      // Update store goal progress after creating/updating entry
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
        for (final entry in periodEntries) {
          if (entry.goalReached != goalReached) {
            final updatedEntry = entry.copyWith(goalReached: goalReached);
            _entries = _entries.map((e) => e.id == entry.id ? updatedEntry : e).toList();
            updated = true;

            // If goal just reached, show QR screen
            if (goalReached && mounted) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RewardQrScreen(entry: updatedEntry),
                    ),
                  );
                }
              });
            }
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
                  value: (progress['currentDistanceMeters'] as int? ?? 0) /
                      (goal['targetDistanceMeters'] as int),
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
                  value: (progress['currentDurationMinutes'] as int? ?? 0) /
                      (goal['targetDurationMinutes'] as int),
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
        title: const Text(
          'Training log',
          style: TextStyle(
            color: AppColors.textOnPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPink),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(),
        icon: const Icon(Icons.add),
        label: const Text('Log session'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadEntries();
          await _syncGoogleFit();
          await _loadActiveGoals();
        },
        child: _entries.isEmpty && _activeGoals.isEmpty
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
                          widget.navigateToTab(1); // Navigate to Challenges tab
                        },
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Challenges'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          side: const BorderSide(color: AppColors.primaryPurple),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          widget.navigateToTab(2); // Navigate to Coupons tab
                        },
                        icon: const Icon(Icons.local_offer),
                        label: const Text('Coupons'),
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
      ),
    );
  }
}
