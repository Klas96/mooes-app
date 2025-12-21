import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class StoreService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Get a store by ID
  static Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stores/$storeId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['store'] != null) {
          return data['store'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching store: $e');
      return null;
    }
  }

  /// Get store image URL
  static String getStoreImageUrl(Map<String, dynamic>? store) {
    if (store == null) return '';
    final imagePath = store['profilePicture'] ?? store['logo'];
    if (imagePath == null || imagePath.isEmpty) return '';
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // If it's a relative path, construct full URL
    if (imagePath.startsWith('/uploads/')) {
      return '${ApiConfig.baseUrl.replaceAll('/api', '')}$imagePath';
    }
    
    return imagePath;
  }
}

