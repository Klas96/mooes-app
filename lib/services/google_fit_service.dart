import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mooves/constants/api_config.dart';
import 'package:mooves/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleFitService {
  static const String _statusKey = 'google_fit_connected';

  /// Get Google Fit authorization URL from backend
  static Future<Map<String, dynamic>> getAuthUrl() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'code': 'NOT_AUTHENTICATED'
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/google-fit/auth-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'authUrl': body['authUrl'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to get auth URL',
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting auth URL: $e',
        'code': 'NETWORK_ERROR'
      };
    }
  }

  /// Open Google Fit authorization URL in browser
  static Future<Map<String, dynamic>> connectGoogleFit() async {
    try {
      final result = await getAuthUrl();
      if (!result['success']) {
        return result;
      }

      final authUrl = result['authUrl'] as String;
      
      // Launch URL in browser
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return {
          'success': true,
          'message': 'Please complete authorization in browser',
        };
      } else {
        return {
          'success': false,
          'message': 'Could not launch authorization URL',
          'code': 'LAUNCH_ERROR'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting Google Fit: $e',
        'code': 'CONNECTION_ERROR'
      };
    }
  }

  /// Handle OAuth callback with authorization code
  static Future<Map<String, dynamic>> handleCallback(String code) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'code': 'NOT_AUTHENTICATED'
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/google-fit/callback'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': code}),
      ).timeout(const Duration(seconds: 30));

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Store connection status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_statusKey, true);

        return {
          'success': true,
          'message': body['message'] ?? 'Google Fit connected successfully',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to connect Google Fit',
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error handling callback: $e',
        'code': 'CALLBACK_ERROR'
      };
    }
  }

  /// Sync running activities from Google Fit
  static Future<Map<String, dynamic>> syncActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'code': 'NOT_AUTHENTICATED'
        };
      }

      final body = <String, dynamic>{};
      if (startDate != null) {
        body['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        body['endDate'] = endDate.toIso8601String();
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/google-fit/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 60));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Activities synced successfully',
          'activities': responseBody['activities'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseBody['error'] ?? 'Failed to sync activities',
          'code': responseBody['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error syncing activities: $e',
        'code': 'SYNC_ERROR'
      };
    }
  }

  /// Get Google Fit connection status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {
          'success': false,
          'connected': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/google-fit/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_statusKey, body['connected'] ?? false);

        return {
          'success': true,
          'connected': body['connected'] ?? false,
          'lastSync': body['lastSync'],
        };
      } else {
        return {
          'success': false,
          'connected': false,
          'message': body['error'] ?? 'Failed to get status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'connected': false,
        'message': 'Error getting status: $e',
      };
    }
  }

  /// Disconnect Google Fit
  static Future<Map<String, dynamic>> disconnect() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'code': 'NOT_AUTHENTICATED'
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/google-fit/disconnect'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_statusKey);

        return {
          'success': true,
          'message': body['message'] ?? 'Google Fit disconnected',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Failed to disconnect',
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error disconnecting: $e',
        'code': 'DISCONNECT_ERROR'
      };
    }
  }

  /// Check if Google Fit is connected (from local storage)
  static Future<bool> isConnected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_statusKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}

