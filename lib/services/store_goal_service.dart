import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class StoreGoalService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Get all active store goals
  static Future<List<Map<String, dynamic>>> getActiveGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/store-goals/active'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['goals'] != null) {
          return List<Map<String, dynamic>>.from(data['goals']);
        }
        return [];
      } else {
        debugPrint('Error fetching active goals: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching active goals: $e');
      return [];
    }
  }

  /// Get a specific goal by ID
  static Future<Map<String, dynamic>?> getGoal(String goalId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/store-goals/$goalId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['goal'] != null) {
          return data['goal'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching goal: $e');
      return null;
    }
  }

  /// Create a new store goal (store only)
  static Future<Map<String, dynamic>> createGoal({
    required String title,
    String? description,
    int? targetDistanceMeters,
    int? targetDurationMinutes,
    required String startDate,
    String? endDate,
    int? maxParticipants,
    required String couponCode,
    String? couponDescription,
    double? couponDiscount,
    double? couponDiscountAmount,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/store-goals',
        body: json.encode({
          'title': title,
          'description': description,
          'targetDistanceMeters': targetDistanceMeters,
          'targetDurationMinutes': targetDurationMinutes,
          'startDate': startDate,
          'endDate': endDate,
          'maxParticipants': maxParticipants,
          'couponCode': couponCode,
          'couponDescription': couponDescription,
          'couponDiscount': couponDiscount,
          'couponDiscountAmount': couponDiscountAmount,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'goal': data['goal'],
          };
        }
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to create goal',
      };
    } catch (e) {
      debugPrint('Error creating goal: $e');
      return {
        'success': false,
        'message': 'Error creating goal: $e',
      };
    }
  }

  /// Get goals for the current store (store only)
  static Future<List<Map<String, dynamic>>> getStoreGoals() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/store-goals/store/my-goals',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['goals'] != null) {
          return List<Map<String, dynamic>>.from(data['goals']);
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching store goals: $e');
      return [];
    }
  }
}

