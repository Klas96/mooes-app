import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

class CouponService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Get user's coupons
  static Future<List<Map<String, dynamic>>> getUserCoupons() async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/coupons/my-coupons',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['coupons'] != null) {
          return List<Map<String, dynamic>>.from(data['coupons']);
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
      return [];
    }
  }

  /// Get a specific coupon
  static Future<Map<String, dynamic>?> getCoupon(String couponId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/coupons/$couponId',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['coupon'] != null) {
          return data['coupon'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching coupon: $e');
      return null;
    }
  }

  /// Mark a coupon as used
  static Future<Map<String, dynamic>> useCoupon(String couponId) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'POST',
        '/coupons/$couponId/use',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'coupon': data['coupon'],
          };
        }
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to use coupon',
      };
    } catch (e) {
      debugPrint('Error using coupon: $e');
      return {
        'success': false,
        'message': 'Error using coupon: $e',
      };
    }
  }
}

