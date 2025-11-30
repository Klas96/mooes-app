// BACKUP - Production config for 158.174.210.28
class ApiConfig {
  // Backend URL - Bahnhof VPS (nginx proxies port 80 to backend on 8080)
  static const String baseUrl = 'http://158.174.210.28';
  
  // API endpoints - Include /api prefix for backend routes
  static const String apiBaseUrl = '$baseUrl/api';
  
  // WebSocket URL for real-time features
  static const String webSocketUrl = 'ws://158.174.210.28';
  
  // Image uploads URL
  static const String uploadsUrl = '$baseUrl/uploads';
  
  // Environment configuration
  static const bool isProduction = true;
  static const bool enableLogging = false; // Disable logging in production for better performance
  
  // Optimized timeout configurations
  static const int connectionTimeout = 15000; // Reduced from 30 seconds
  static const int receiveTimeout = 15000; // Reduced from 30 seconds
  
  // Rate limiting
  static const int maxRetries = 2; // Reduced from 3
  static const int retryDelay = 500; // Reduced from 1000ms
  
  // Stripe configuration
  static const String stripePublishableKey = 'pk_live_51Ri0VmDX8VApD7AKld7sIAOmzvSIV2RwpP95WhGZiovgJ7PjZrwQ5zC4U8AO2EUg7RNLoqLFPKw4esKQbwqfkYa200N7USCiCE';
} 

