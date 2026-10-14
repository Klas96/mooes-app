import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class StoreService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Get a store by ID
  static Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    try {
      debugPrint('Fetching store with ID: $storeId');
      final response = await http.get(
        Uri.parse('$baseUrl/stores/$storeId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('Store API response status: ${response.statusCode}');
      debugPrint('Store API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['store'] != null) {
          return data['store'] as Map<String, dynamic>;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Store not found (404)');
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching store: $e');
      return null;
    }
  }

  /// Get all active stores
  static Future<List<Map<String, dynamic>>> getAllStores({int? limit, int? offset}) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl/stores').replace(queryParameters: queryParams);
      debugPrint('Fetching all stores from: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('Stores API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['stores'] != null) {
          final stores = data['stores'] as List;
          return stores.map((store) => store as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all stores: $e');
      return [];
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

