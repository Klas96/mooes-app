// Android/iOS-specific factory - uses real health package
// This file will only be used on Android/iOS builds
// Note: This file will fail to compile on Linux, but that's OK - it's only used on Android/iOS
import 'package:health/health.dart' as health_package;
import 'package:flutter/foundation.dart' show debugPrint;

/// Create HealthFactory - real implementation for Android/iOS
/// This will only compile on Android/iOS builds, not on Linux
/// Note: The health package uses Health() not HealthFactory(), so we return a Health instance
dynamic createHealthFactory() {
  try {
    debugPrint('🔧 health_factory_android: Creating Health instance...');
    // On Android/iOS, this will work. On Linux, this file won't be used.
    // The health package uses Health() not HealthFactory()
    final health = health_package.Health();
    debugPrint('✅ health_factory_android: Health instance created successfully');
    debugPrint('   Health type: ${health.runtimeType}');
    return health;
  } catch (e, stackTrace) {
    debugPrint('❌ health_factory_android: Failed to create Health instance: $e');
    debugPrint('   Error type: ${e.runtimeType}');
    debugPrint('Stack trace: $stackTrace');
    // If this fails, return null (shouldn't happen on Android/iOS)
    return null;
  }
}

