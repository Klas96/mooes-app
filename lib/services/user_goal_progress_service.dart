import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class UserGoalProgressService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Join a goal (start tracking progress)
  static Future<Map<String, dynamic>> joinGoal(String goalId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/user-goal-progress/join',
        body: json.encode({'goalId': goalId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'progress': data['progress'],
            'message': data['message'] ?? 'Successfully joined goal',
          };
        }
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to join goal',
      };
    } catch (e) {
      debugPrint('Error joining goal: $e');
      return {
        'success': false,
        'message': 'Error joining goal: $e',
      };
    }
  }

  /// Get user's progress on all goals
  static Future<List<Map<String, dynamic>>> getUserProgress() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/user-goal-progress/my-progress',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['progress'] != null) {
          return List<Map<String, dynamic>>.from(data['progress']);
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user progress: $e');
      return [];
    }
  }

  /// Get progress for a specific goal
  static Future<Map<String, dynamic>?> getGoalProgress(String goalId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/user-goal-progress/goal/$goalId',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['progress'] != null) {
          return data['progress'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching goal progress: $e');
      return null;
    }
  }
}

