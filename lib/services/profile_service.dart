import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../constants/api_config.dart';

class ProfileService {
  // Use the centralized API configuration with /api already included
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Helper method to construct full image URLs
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // If it's already a full URL, return as is (including Google Cloud Storage URLs)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If it's a relative path starting with /uploads/, construct full URL
    if (imagePath.startsWith('/uploads/')) {
      return '${ApiConfig.baseUrl}$imagePath';
    }

    // If it's just a filename, add the uploads path
    if (!imagePath.contains('/')) {
      return '${ApiConfig.baseUrl}/uploads/$imagePath';
    }

    // For any other relative paths, return as is (let the backend handle it)
    return imagePath;
  }

  static Future<Map<String, dynamic>> createProfile({
    String? bio,
    String? birthDate,
    String? gender,
    String? genderPreference,
    String? location,
    List<String>? relationshipType,
    List<String>? keyWords,
    String? locationMode,
  }) async {
    try {
      final response = await AuthService.authenticatedRequest(
        'PUT',
        '/profiles/me',
        body: json.encode({
          if (bio != null) 'bio': bio,
          if (birthDate != null) 'birthDate': birthDate,
          if (gender != null) 'gender': gender,
          if (genderPreference != null) 'genderPreference': genderPreference,
          if (location != null) 'location': location,
          if (relationshipType != null) 'relationshipType': relationshipType,
          if (keyWords != null) 'keyWords': keyWords,
          if (locationMode != null) 'locationMode': locationMode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create profile');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? bio,
    String? birthDate,
    String? gender,
    String? genderPreference,
    String? location,
    List<String>? relationshipType,
    List<String>? keyWords,
    String? locationMode,
    List<Map<String, dynamic>>? images,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Create HTTP client with timeout
      final client = http.Client();

      // Create the request body
      final requestBody = {
        if (bio != null) 'bio': bio,
        if (birthDate != null) 'birthDate': birthDate,
        if (gender != null) 'gender': gender,
        if (genderPreference != null) 'genderPreference': genderPreference,
        if (location != null) 'location': location,
        if (relationshipType != null) 'relationshipType': relationshipType,
        if (keyWords != null) 'keyWords': keyWords,
        if (locationMode != null) 'locationMode': locationMode,
        if (images != null) 'images': images, // Include images if provided
      };

      final jsonBody = json.encode(requestBody);

      try {
        final response = await client
            .put(
          Uri.parse('$baseUrl/profiles/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonBody,
        )
            .timeout(
          const Duration(seconds: 30), // 30 second timeout
          onTimeout: () {
            throw Exception(
                'Request timeout - server took too long to respond');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Transform image URLs to full URLs
          if (data['profilePicture'] != null) {
            data['profilePicture'] = getFullImageUrl(data['profilePicture']);
          }
          if (data['images'] != null && data['images'] is List) {
            for (var image in data['images']) {
              if (image['imageUrl'] != null) {
                image['imageUrl'] = getFullImageUrl(image['imageUrl']);
              }
            }
          }
          return data;
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? 'Failed to update profile';
          throw Exception(errorMessage);
        }
      } finally {
        client.close(); // Always close the client
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> updateImageOrder(
      List<Map<String, dynamic>> images) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/images/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'imageOrders': images}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update image order');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      debugPrint('🔄 Fetching profile...');
      final response = await AuthService.authenticatedRequest(
        'GET',
        '/profiles/me',
      ).timeout(
        const Duration(seconds: 30), // Increased from 15 to 30 seconds
        onTimeout: () {
          debugPrint('❌ Profile request timeout after 30 seconds');
          throw Exception('Profile request timeout - server not responding');
        },
      );

      debugPrint('✅ Profile response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        debugPrint('✅ Profile loaded successfully');
        return data;
      } else if (response.statusCode == 404) {
        // Profile not found - this is expected for new users
        debugPrint('ℹ️  Profile not found (404)');
        throw Exception('Profile not found');
      } else {
        final errorData = json.decode(response.body);
        debugPrint('❌ Profile request failed: ${errorData['error']}');
        throw Exception(errorData['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(
      String imagePath) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      Uint8List bytes;
      String fileName;
      String? contentType;

      if (kIsWeb) {
        // For web, handle blob URL
        try {
          final response = await http.get(Uri.parse(imagePath));
          bytes = response.bodyBytes;
          fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          contentType = response.headers['content-type'] ?? 'image/jpeg';
        } catch (e) {
          throw Exception('Failed to read image data from blob URL: $e');
        }
      } else {
        // For mobile, use File
        final file = File(imagePath);
        bytes = await file.readAsBytes();
        fileName = imagePath.split('/').last;
        // Determine content type from file extension
        final extension = fileName.toLowerCase().split('.').last;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg';
        }
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profiles/upload-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Transform image URLs to full URLs
        if (data['images'] != null &&
            data['images'] is List &&
            data['images'].isNotEmpty) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }

        return data;
      } else {
        String errorMessage = 'Failed to upload profile picture';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {
          // If response body is not JSON, use status code message
          errorMessage = 'Upload failed: ${response.statusCode} ${response.reasonPhrase}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<void> deleteImage(String imageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final url = '$baseUrl/profiles/images/$imageId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete image');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProfileById(String profileId) async {
    try {
      print(
          '📡 ProfileService.getProfileById: Fetching profile with ID: "$profileId"');

      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ ProfileService.getProfileById: No authentication token');
        throw Exception('No authentication token');
      }

      final url = '$baseUrl/profiles/$profileId';
      print('📡 ProfileService.getProfileById: URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '📡 ProfileService.getProfileById: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ ProfileService.getProfileById: Successfully fetched profile ${data['id']}');

        // Transform image URLs to full URLs
        if (data['profilePicture'] != null) {
          data['profilePicture'] = getFullImageUrl(data['profilePicture']);
        }
        if (data['images'] != null && data['images'] is List) {
          for (var image in data['images']) {
            if (image['imageUrl'] != null) {
              image['imageUrl'] = getFullImageUrl(image['imageUrl']);
            }
          }
        }
        return data;
      } else {
        print(
            '❌ ProfileService.getProfileById: Error response: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to get profile by id');
        } catch (e) {
          throw Exception(
              'Failed to get profile: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ ProfileService.getProfileById: Exception: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get location mode from backend
  static Future<String?> getLocationMode() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['locationMode'] as String?;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get location mode');
      }
    } catch (e) {
      return null;
    }
  }

  /// Update location mode in backend
  static Future<void> updateLocationMode(String locationMode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'locationMode': locationMode}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update location mode');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if profile is complete (has all required fields)
  static bool isProfileComplete(Map<String, dynamic> profile) {
    return profile.isNotEmpty;
  }

  /// Get complete profile (profile that has finished initial setup)
  static Future<Map<String, dynamic>?> getCompleteProfile() async {
    try {
      debugPrint('🔍 Checking for complete profile...');
      // getProfile() already has a 30 second timeout, no need to add another
      final profile = await getProfile();

      if (isProfileComplete(profile)) {
        debugPrint('✅ Complete profile found');
        return profile;
      } else {
        // Profile exists but is incomplete
        debugPrint('⚠️  Profile exists but is incomplete');
        throw Exception('Profile incomplete: Missing required fields');
      }
    } catch (e) {
      debugPrint('❌ Error in getCompleteProfile: $e');

      // Check if this is a network or authentication error
      if (e.toString().contains('Network error') ||
          e.toString().contains('No authentication token') ||
          e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('timeout')) {
        rethrow;
      }

      // Check if this is a "Profile not found" error
      if (e.toString().contains('Profile not found')) {
        debugPrint('ℹ️  No profile found for user');
        return null;
      }

      // For other errors (like profile incomplete), return null
      debugPrint('ℹ️  Returning null for error: $e');
      return null;
    }
  }

  /// Hide account - profile will not appear in AI chat or Explore Area
  static Future<Map<String, dynamic>> hideAccount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/hide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to hide account');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Unhide account - profile will appear in AI chat and Explore Area again
  static Future<Map<String, dynamic>> unhideAccount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse('$baseUrl/profiles/unhide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to unhide account');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get account visibility status
  static Future<bool> getAccountVisibility() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/visibility'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isHidden'] ?? false;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['error'] ?? 'Failed to get account visibility');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update running goals
  static Future<Map<String, dynamic>> updateGoals({
    double? runningGoalDistanceKm,
    int? runningGoalDurationMinutes,
    String? goalPeriod,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (runningGoalDistanceKm != null) 'runningGoalDistanceKm': runningGoalDistanceKm,
          if (runningGoalDurationMinutes != null) 'runningGoalDurationMinutes': runningGoalDurationMinutes,
          if (goalPeriod != null) 'goalPeriod': goalPeriod,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update goals');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
