import 'dart:convert';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';  // Temporarily disabled
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SessionManager {
  // static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();  // Temporarily disabled
  static const String _sessionKey = 'user_session';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _lastActivityKey = 'last_activity';
  static const String _sessionExpiryKey = 'session_expiry';
  
  // Session timeout duration (7 days)
  static const Duration _sessionTimeout = Duration(days: 7);
  
  /// Initialize session manager and check for existing valid session
  static Future<bool> initializeSession() async {
    try {
      print('=== DEBUG: SessionManager.initializeSession ===');
      
      // Check if we have a stored session
      final sessionData = await _getStoredSession();
      if (sessionData == null) {
        print('No stored session found');
        return false;
      }
      
      // Check if session is still valid
      if (!await _isSessionValid(sessionData)) {
        print('Stored session is invalid or expired');
        await _clearSession();
        return false;
      }
      
      // Validate session with backend with timeout
      try {
        final isValid = await _validateSessionWithBackend(sessionData['token'])
            .timeout(const Duration(seconds: 15)); // 15 second timeout for initialization
        
        if (!isValid) {
          print('Session validation with backend failed');
          await _clearSession();
          return false;
        }
      } catch (e) {
        print('Session validation timeout or error: $e');
        await _clearSession();
        return false;
      }
      
      // Update last activity
      await _updateLastActivity();
      
      print('Session initialized successfully');
      return true;
    } catch (e) {
      print('Session initialization error: $e');
      await _clearSession();
      return false;
    }
  }
  
  /// Store session data securely
  static Future<void> storeSession({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      print('=== DEBUG: SessionManager.storeSession ===');
      
      final sessionData = {
        'token': token,
        'user': userData,
        'created_at': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_sessionTimeout).toIso8601String(),
      };
      
      // Store in SharedPreferences (temporarily using only SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, json.encode(sessionData));
      
      print('Session stored successfully');
    } catch (e) {
      print('Store session error: $e');
      throw Exception('Failed to store session: $e');
    }
  }
  
  /// Get current session data
  static Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final sessionData = await _getStoredSession();
      if (sessionData == null) return null;
      
      // Check if session is still valid
      if (!await _isSessionValid(sessionData)) {
        await _clearSession();
        return null;
      }
      
      // Update last activity
      await _updateLastActivity();
      
      return sessionData;
    } catch (e) {
      print('Get current session error: $e');
      return null;
    }
  }
  
  /// Get authentication token
  static Future<String?> getToken() async {
    try {
      final sessionData = await getCurrentSession();
      return sessionData?['token'];
    } catch (e) {
      print('Get token error: $e');
      return null;
    }
  }
  
  /// Get current user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final sessionData = await getCurrentSession();
      return sessionData?['user'];
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final sessionData = await getCurrentSession();
      return sessionData != null;
    } catch (e) {
      print('Check authentication error: $e');
      return false;
    }
  }
  
  /// Refresh session (extend expiry)
  static Future<bool> refreshSession() async {
    try {
      print('=== DEBUG: SessionManager.refreshSession ===');
      
      final sessionData = await getCurrentSession();
      if (sessionData == null) return false;
      
      // Validate with backend
      if (!await _validateSessionWithBackend(sessionData['token'])) {
        return false;
      }
      
      // Update session with new expiry
      final updatedSessionData = {
        ...sessionData,
        'last_activity': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_sessionTimeout).toIso8601String(),
      };
      
      // Store updated session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, json.encode(updatedSessionData));
      
      print('Session refreshed successfully');
      return true;
    } catch (e) {
      print('Refresh session error: $e');
      return false;
    }
  }
  
  /// Clear session data
  static Future<void> clearSession() async {
    try {
      print('=== DEBUG: SessionManager.clearSession ===');
      await _clearSession();
      print('Session cleared successfully');
    } catch (e) {
      print('Clear session error: $e');
    }
  }
  
  /// Update user data in session
  static Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      final sessionData = await getCurrentSession();
      if (sessionData == null) return;
      
      final updatedSessionData = {
        ...sessionData,
        'user': userData,
        'last_activity': DateTime.now().toIso8601String(),
      };
      
      // Store updated session in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, json.encode(updatedSessionData));
      
      print('User data updated in session');
    } catch (e) {
      print('Update user data error: $e');
    }
  }
  
  /// Get session statistics
  static Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final sessionData = await getCurrentSession();
      if (sessionData == null) {
        return {'has_session': false};
      }
      
      final createdAt = DateTime.parse(sessionData['created_at']);
      final lastActivity = DateTime.parse(sessionData['last_activity']);
      final expiresAt = DateTime.parse(sessionData['expires_at']);
      final now = DateTime.now();
      
      return {
        'has_session': true,
        'created_at': createdAt.toIso8601String(),
        'last_activity': lastActivity.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'session_age_hours': now.difference(createdAt).inHours,
        'last_activity_hours': now.difference(lastActivity).inHours,
        'expires_in_hours': expiresAt.difference(now).inHours,
        'is_expired': now.isAfter(expiresAt),
      };
    } catch (e) {
      print('Get session stats error: $e');
      return {'has_session': false, 'error': e.toString()};
    }
  }
  
  // Private helper methods
  
  static Future<Map<String, dynamic>?> _getStoredSession() async {
    try {
      // Use SharedPreferences only (temporarily)
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString(_sessionKey);
      
      if (sessionString != null) {
        return json.decode(sessionString);
      }
      
      return null;
    } catch (e) {
      print('Get stored session error: $e');
      return null;
    }
  }
  
  static Future<bool> _isSessionValid(Map<String, dynamic> sessionData) async {
    try {
      // Check if session has required fields
      if (!sessionData.containsKey('token') || 
          !sessionData.containsKey('expires_at')) {
        return false;
      }
      
      // Check if session is expired
      final expiresAt = DateTime.parse(sessionData['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        print('Session expired at: $expiresAt');
        return false;
      }
      
      // Check if session is too old (30 days max)
      final createdAt = DateTime.parse(sessionData['created_at']);
      final maxAge = Duration(days: 30);
      if (DateTime.now().difference(createdAt) > maxAge) {
        print('Session too old, created at: $createdAt');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Check session validity error: $e');
      return false;
    }
  }
  
  static Future<bool> _validateSessionWithBackend(String token) async {
    try {
      print('=== DEBUG: Validating session with backend ===');
      
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5), // Reduced timeout from 10 to 5 seconds
        onTimeout: () {
          print('Session validation timeout - backend not responding');
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        print('Session validation successful');
        return true;
      } else {
        print('Session validation failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Validate session with backend error: $e');
      
      // For network errors or timeouts, we'll allow the session to continue
      // but mark it as potentially stale
      if (e.toString().contains('timeout') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        print('Network error during session validation - allowing session to continue');
        return true; // Allow session to continue for network issues
      }
      
      return false;
    }
  }
  
  static Future<void> _updateLastActivity() async {
    try {
      final sessionData = await _getStoredSession();
      if (sessionData == null) return;
      
      final updatedSessionData = {
        ...sessionData,
        'last_activity': DateTime.now().toIso8601String(),
      };
      
      // Update in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, json.encode(updatedSessionData));
    } catch (e) {
      print('Update last activity error: $e');
    }
  }
  
  static Future<void> _clearSession() async {
    try {
      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      
      // Also clear old keys for backward compatibility
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('Clear session error: $e');
    }
  }
} 