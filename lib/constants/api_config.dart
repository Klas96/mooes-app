class ApiConfig {
  // Backend URL - Vercel deployment
  static const String baseUrl = 'https://mooves-backend.vercel.app';
  
  // API endpoints - Include /api prefix for backend routes
  static const String apiBaseUrl = '$baseUrl/api';
  
  // WebSocket URL for real-time features (disabled on Vercel - use polling if needed)
  static const String webSocketUrl = 'wss://mooves-backend.vercel.app';
  
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