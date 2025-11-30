class ApiConfig {
  // Backend URL - Bahnhof VPS (nginx proxies port 443 to backend on 8080)
  // For web, we use the IP address directly. For native apps, same IP.
  static const String baseUrl = 'https://backend.klasholmgren.se';
  
  // API endpoints - Include /api prefix for backend routes
  static const String apiBaseUrl = '$baseUrl/api';
  
  // WebSocket URL for real-time features
  static const String webSocketUrl = 'wss://backend.klasholmgren.se';
  
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
  
} 