import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';  // Re-enabled for token storage
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'session_manager.dart';
import '../constants/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Helper method to handle API errors
  static String _handleApiError(dynamic response) {
    try {
      if (response is http.Response) {
        final body = json.decode(response.body);
        
        // Handle structured error responses
        if (body['error'] != null) {
          return body['error'];
        }
        
        if (body['message'] != null) {
          return body['message'];
        }
        
        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 400:
            return 'Invalid request. Please check your input and try again.';
          case 401:
            return 'Authentication failed. Please check your credentials.';
          case 403:
            return 'Access denied. You don\'t have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 500:
            return 'Server error. Please try again later.';
          case 503:
            return 'Service temporarily unavailable. Please try again in a few moments.';
          default:
            return 'An unexpected error occurred. Please try again.';
        }
      }
    } catch (e) {
      print('Error parsing API response: $e');
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  // Helper method to get user-friendly error messages
  static String _getUserFriendlyError(String errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'MISSING_CREDENTIALS':
        return 'Please provide both email and password.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists. Please try logging in instead.';
      case 'USER_NOT_FOUND':
        return 'No account found with this email address.';
      case 'EMAIL_ALREADY_VERIFIED':
        return 'This email is already verified. You can log in to your account.';
      case 'INVALID_CODE':
        return 'Invalid or expired verification code. Please request a new verification email.';
      case 'EXPIRED_CODE':
        return 'Verification code has expired. Please request a new verification email.';
      case 'MISSING_CODE':
        return 'Verification code is required.';
      case 'MISSING_EMAIL':
        return 'Email address is required.';
      case 'VALIDATION_ERROR':
        return 'Please check your input and try again.';
      case 'DATABASE_CONNECTION_ERROR':
        return 'Database connection failed. Please try again in a few moments.';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please wait a moment and try again.';
      case 'SIGNUP_FAILED':
        return 'Registration failed. Please try again.';
      case 'SIGNIN_FAILED':
        return 'Login failed. Please check your credentials and try again.';
      case 'SIGNUP_DISABLED':
        return 'Registration is currently disabled. Please try again later.';
      case 'SIGNIN_DISABLED':
        return 'Login is currently disabled. Please try again later.';
      case 'EMAIL_VERIFICATION_FAILED':
        return 'Email verification failed. Please check your email and try again.';
      case 'EMAIL_NOT_VERIFIED':
        return 'Please verify your email before logging in.';
      default:
        return defaultMessage;
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Registration successful!',
          'user': body['user'],
          'emailSent': body['emailSent'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('=== DEBUG: AuthService.login attempt ===');
      print('Base URL: $baseUrl');
      print('Full URL: $baseUrl/auth/login');
      print('Email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      final body = json.decode(response.body);
      
      print('=== DEBUG: AuthService.login response ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Save token and user data in SharedPreferences (for backward compatibility)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, body['token']);
        await prefs.setString(userKey, json.encode(body['user']));
        
        // Also store the session in SessionManager for proper authentication
        await SessionManager.storeSession(
          token: body['token'],
          userData: body['user'],
        );

        // Save premium status from backend user object
        if (body['user'] != null) {
          final isPremium = body['user']['isPremium'] == true;
          final premiumExpiry = body['user']['premiumExpiry'];
          await prefs.setBool('premium_status', isPremium);
          if (premiumExpiry != null) {
            await prefs.setString('premium_expiry', premiumExpiry);
          } else {
            await prefs.remove('premium_expiry');
          }
        }

        return {
          'success': true,
          'message': 'Login successful!',
          'user': body['user'],
          'token': body['token'],
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      print('=== DEBUG: AuthService.login error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      
      return {
        'success': false,
        'message': 'Network error: $e. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('=== DEBUG: AuthService.signInWithGoogle attempt ===');
      
      // Initialize Google Sign-In
      // Note: On Android, clientId is not needed as it's read from google-services.json
      // On iOS/Web, you can conditionally add clientId using Platform.isIOS
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure account picker shows
      await googleSignIn.signOut();
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return {
          'success': false,
          'message': 'Google Sign-In cancelled',
          'code': 'SIGN_IN_CANCELLED',
        };
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Google Sign-In successful for: ${googleUser.email}');
      print('ID Token: ${googleAuth.idToken != null ? "Present" : "Missing"}');
      
      // Send the ID token to your backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      final body = json.decode(response.body);
      
      print('=== DEBUG: Google login response ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, body['token']);
        await prefs.setString(userKey, json.encode(body['user']));
        
        // Store the session in SessionManager
        await SessionManager.storeSession(
          token: body['token'],
          userData: body['user'],
        );

        // Save premium status
        if (body['user'] != null) {
          final isPremium = body['user']['isPremium'] == true;
          final premiumExpiry = body['user']['premiumExpiry'];
          await prefs.setBool('premium_status', isPremium);
          if (premiumExpiry != null) {
            await prefs.setString('premium_expiry', premiumExpiry);
          } else {
            await prefs.remove('premium_expiry');
          }
        }

        return {
          'success': true,
          'message': 'Google Sign-In successful!',
          'user': body['user'],
          'token': body['token'],
          'isNewUser': body['isNewUser'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      print('=== DEBUG: AuthService.signInWithGoogle error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      
      return {
        'success': false,
        'message': 'Google Sign-In error: $e',
        'code': 'GOOGLE_SIGN_IN_ERROR',
      };
    }
  }

  // Verify email
  static Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Store the JWT token and update user data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final updatedUser = body['user'];
        final jwtToken = body['token'];
        
        // Store the token and user data in SharedPreferences (for backward compatibility)
        if (jwtToken != null) {
          await prefs.setString(tokenKey, jwtToken);
        }
        await prefs.setString(userKey, json.encode(updatedUser));
        
        // Also store the session in SessionManager for proper authentication
        if (jwtToken != null) {
          await SessionManager.storeSession(
            token: jwtToken,
            userData: updatedUser,
          );
        }

        return {
          'success': true,
          'message': body['message'] ?? 'Email verified successfully!',
          'user': updatedUser,
          'token': jwtToken,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Resend verification email
  static Future<Map<String, dynamic>> resendVerification({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Verification email sent successfully!',
          'emailSent': body['emailSent'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': true,
          'message': 'Already logged out.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Clear local storage regardless of response
      await SessionManager.clearSession();
      
      // Also clear old SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Successfully logged out.',
        };
      } else {
        return {
          'success': true,
          'message': 'Logged out locally.',
        };
      }
    } catch (e) {
      // Clear local storage even if network request fails
      await SessionManager.clearSession();
      
      // Also clear old SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
      
      return {
        'success': true,
        'message': 'Logged out locally.',
      };
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('=== DEBUG: getCurrentUser response ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print('=== DEBUG: getCurrentUser parsed body ===');
        print('Body: $body');
        print('User data: ${body['user']}');
        print('Email verified: ${body['user']?['emailVerified']}');
        return body['user']; // Return the user object, not the whole response
      } else {
        // Token might be invalid, clear it
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
        await prefs.remove(userKey);
        return null;
      }
    } catch (e) {
      print('=== DEBUG: getCurrentUser error: $e ===');
      return null;
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    try {
      print('=== DEBUG: AuthService.getToken ===');
      
      // First try to get token from SessionManager
      final sessionData = await SessionManager.getCurrentSession();
      print('SessionManager session data: ${sessionData != null ? 'found' : 'null'}');
      
      if (sessionData != null && sessionData['token'] != null) {
        print('Token found in SessionManager: ${sessionData['token'].substring(0, 20)}...');
        return sessionData['token'];
      }
      
      // Fallback to old SharedPreferences method for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsToken = prefs.getString(tokenKey);
      print('SharedPreferences token: ${sharedPrefsToken != null ? 'found' : 'null'}');
      
      if (sharedPrefsToken != null) {
        print('Token found in SharedPreferences: ${sharedPrefsToken.substring(0, 20)}...');
        return sharedPrefsToken;
      }
      
      print('No token found in either location');
      return null;
    } catch (e) {
      print('GetToken error: $e');
      // Fallback to old method
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(tokenKey);
        print('Fallback SharedPreferences token: ${token != null ? 'found' : 'null'}');
        return token;
      } catch (fallbackError) {
        print('Fallback GetToken error: $fallbackError');
        return null;
      }
    }
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      // First try to get user data from SessionManager
      final sessionData = await SessionManager.getCurrentSession();
      if (sessionData != null && sessionData['user'] != null) {
        return sessionData['user'];
      }
      
      // Fallback to old SharedPreferences method for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(userKey);
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      print('GetUserData error: $e');
      // Fallback to old method
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(userKey);
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Check if user email is verified
  static Future<bool> isEmailVerified() async {
    final userData = await getUserData();
    return userData?['emailVerified'] == true;
  }

  /// Initialize authentication system
  static Future<bool> initialize() async {
    try {
      print('=== DEBUG: AuthService.initialize ===');
      
      // Initialize session manager
      final hasValidSession = await SessionManager.initializeSession();
      
      if (hasValidSession) {
        print('Valid session found and restored');
        return true;
      } else {
        print('No valid session found');
        return false;
      }
    } catch (e) {
      print('AuthService initialization error: $e');
      return false;
    }
  }

  /// Refresh session if needed
  static Future<bool> refreshSessionIfNeeded() async {
    try {
      return await SessionManager.refreshSession();
    } catch (e) {
      print('Refresh session error: $e');
      return false;
    }
  }

  /// Get session statistics for debugging
  static Future<Map<String, dynamic>> getSessionStats() async {
    try {
      return await SessionManager.getSessionStats();
    } catch (e) {
      print('Get session stats error: $e');
      return {'error': e.toString()};
    }
  }

  // Sign in method (alias for login)
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    return await login(email: email, password: password);
  }

  // Sign up method (alias for register)
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  // Sign out method (alias for logout)
  static Future<void> signOut() async {
    await logout();
  }

  /// Handle invalid token errors and clear stored tokens
  static Future<void> handleInvalidToken() async {
    try {
      print('=== DEBUG: AuthService.handleInvalidToken ===');
      print('Clearing invalid tokens from storage...');
      
      // Clear from SessionManager
      await SessionManager.clearSession();
      
      // Also clear old SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userKey);
      
      print('Invalid tokens cleared successfully');
    } catch (e) {
      print('Error clearing invalid tokens: $e');
    }
  }

  /// Check if an API response indicates an invalid token
  static bool isInvalidTokenResponse(http.Response response) {
    try {
      if (response.statusCode == 401) {
        final body = json.decode(response.body);
        final errorCode = body['code'];
        return errorCode == 'USER_NOT_FOUND' || errorCode == 'TOKEN_INVALID';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Make an authenticated API request with automatic token invalidation
  static Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final requestHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      final uri = Uri.parse('$baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders).timeout(
            const Duration(seconds: 15), // 15 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: body).timeout(
            const Duration(seconds: 15), // 15 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: body).timeout(
            const Duration(seconds: 15), // 15 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders).timeout(
            const Duration(seconds: 15), // 15 second timeout
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Check if response indicates invalid token
      if (isInvalidTokenResponse(response)) {
        print('Invalid token detected, clearing stored tokens...');
        await handleInvalidToken();
      }

      return response;
    } catch (e) {
      print('Authenticated request error: $e');
      rethrow;
    }
  }

  // Resend verification email method (alias for resendVerification)
  static Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    return await resendVerification(email: email);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await isLoggedIn();
  }

  // Update user profile picture
  static Future<void> updateUserProfilePicture(String imageUrl) async {
    try {
      final response = await authenticatedRequest(
        'PUT',
        '/auth/profile/picture',
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile picture');
      }

      // Update local user data with new image URL
      final sessionData = await SessionManager.getCurrentSession();
      if (sessionData != null && sessionData['user'] != null) {
        final updatedUser = Map<String, dynamic>.from(sessionData['user']);
        updatedUser['profilePicture'] = imageUrl;
        
        await SessionManager.storeSession(
          token: sessionData['token'],
          userData: updatedUser,
        );
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }

  // Debug method to check token storage
  static Future<Map<String, dynamic>> debugTokenStorage() async {
    try {
      print('=== DEBUG: AuthService.debugTokenStorage ===');
      
      // Check SessionManager
      final sessionData = await SessionManager.getCurrentSession();
      print('SessionManager session: ${sessionData != null ? 'found' : 'null'}');
      if (sessionData != null) {
        print('SessionManager token: ${sessionData['token'] != null ? 'found' : 'null'}');
        print('SessionManager user: ${sessionData['user'] != null ? 'found' : 'null'}');
      }
      
      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsToken = prefs.getString(tokenKey);
      final sharedPrefsUser = prefs.getString(userKey);
      print('SharedPreferences token: ${sharedPrefsToken != null ? 'found' : 'null'}');
      print('SharedPreferences user: ${sharedPrefsUser != null ? 'found' : 'null'}');
      
      return {
        'sessionManager': {
          'hasSession': sessionData != null,
          'hasToken': sessionData?['token'] != null,
          'hasUser': sessionData?['user'] != null,
        },
        'sharedPreferences': {
          'hasToken': sharedPrefsToken != null,
          'hasUser': sharedPrefsUser != null,
        }
      };
    } catch (e) {
      print('DebugTokenStorage error: $e');
      return {'error': e.toString()};
    }
  }

  /// Delete user account
  /// This will permanently delete the user's account and all associated data
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await authenticatedRequest(
        'DELETE',
        '/auth/delete-account',
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        // Clear all stored authentication data
        await SessionManager.clearSession();
        
        // Also clear old SharedPreferences for backward compatibility
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
        await prefs.remove(userKey);
        await prefs.remove('premium_status');
        await prefs.remove('premium_expiry');
        
        return {
          'success': true,
          'message': body['message'] ?? 'Account deleted successfully',
          'code': body['code'],
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  /// Request password reset
  /// Sends a password reset email to the provided email address
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Password reset email sent successfully!',
          'emailSent': body['emailSent'] ?? false,
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }

  /// Reset password with token
  /// Resets the user's password using a reset token from email
  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Password reset successfully!',
          'code': body['code'],
        };
      } else {
        String errorMessage = _handleApiError(response);
        
        // Try to get more specific error message from response
        if (body['code'] != null) {
          errorMessage = _getUserFriendlyError(body['code'], errorMessage);
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'code': body['code'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection and try again.',
        'code': 'NETWORK_ERROR',
      };
    }
  }
} 