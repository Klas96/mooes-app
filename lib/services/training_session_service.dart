import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:mooves/constants/api_config.dart';
import 'package:http/http.dart' as http;

class TrainingSessionService {
  /// Create a new training session
  static Future<Map<String, dynamic>> createSession({
    required String title,
    required String date, // ISO date string (YYYY-MM-DD)
    int? durationMinutes,
    double? distanceKm,
    bool? goalReached,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/training-sessions',
        body: json.encode({
          'title': title,
          'date': date,
          'durationMinutes': durationMinutes,
          'distanceKm': distanceKm,
          'goalReached': goalReached ?? false,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'session': data,
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to create session',
      };
    } catch (e) {
      debugPrint('Error creating training session: $e');
      return {
        'success': false,
        'message': 'Error creating session: $e',
      };
    }
  }

  /// Update an existing training session
  static Future<Map<String, dynamic>> updateSession({
    required String id,
    String? title,
    String? date,
    int? durationMinutes,
    double? distanceKm,
    bool? goalReached,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (date != null) body['date'] = date;
      if (durationMinutes != null) body['durationMinutes'] = durationMinutes;
      if (distanceKm != null) body['distanceKm'] = distanceKm;
      if (goalReached != null) body['goalReached'] = goalReached;

      final response = await AuthService.authenticatedRequest(
        'PATCH',
        '/training-sessions/$id',
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'session': data,
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to update session',
      };
    } catch (e) {
      debugPrint('Error updating training session: $e');
      return {
        'success': false,
        'message': 'Error updating session: $e',
      };
    }
  }

  /// Delete a training session
  static Future<Map<String, dynamic>> deleteSession(String id) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'DELETE',
        '/training-sessions/$id',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {
          'success': true,
        };
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to delete session',
      };
    } catch (e) {
      debugPrint('Error deleting training session: $e');
      return {
        'success': false,
        'message': 'Error deleting session: $e',
      };
    }
  }

  /// Get all training sessions for the current user
  static Future<List<Map<String, dynamic>>> listSessions() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/training-sessions',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else if (data['sessions'] != null) {
          return (data['sessions'] as List).cast<Map<String, dynamic>>();
        }
        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error listing training sessions: $e');
      return [];
    }
  }
}
