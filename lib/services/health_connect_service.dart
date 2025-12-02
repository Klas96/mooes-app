import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:mooves/models/training_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditionally import health package
// On web: use stub
// On Android/iOS: use real package
// On Linux: use stub (for compilation only, won't be used at runtime)
import 'package:health/health.dart' 
    if (dart.library.html) 'package:mooves/services/health_connect_service_stub.dart'
    as health_package;



class HealthConnectService {
  static const String _permissionKey = 'health_connect_permissions_granted';
  static dynamic _health;

  /// Check if Health Connect is available on this platform
  static bool get isAvailable {
    if (kIsWeb) {
      return false;
    }
    // Check if we're on Android or iOS
    if (defaultTargetPlatform == TargetPlatform.android || 
        defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
    // Fallback to Platform check if available
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      // Platform check failed (likely web or unsupported)
      return false;
    }
  }

  /// Initialize Health Connect
  static Future<bool> initialize() async {
    if (!isAvailable) {
      debugPrint('❌ Health Connect is only available on Android/iOS');
      return false;
    }
    try {
      debugPrint('🔧 Initializing Health Connect...');
      debugPrint('   Platform: ${Platform.operatingSystem}');
      debugPrint('   isAndroid: ${Platform.isAndroid}, isIOS: ${Platform.isIOS}');
      
      // Create Health instance
      _health = _createHealthFactoryInstance();
      
      if (_health == null) {
        debugPrint('❌ Health instance creation returned null');
        return false;
      }
      
      debugPrint('✅ Health instance created successfully');
      debugPrint('   Type: ${_health.runtimeType}');
      
      // Configure Health instance - required before use
      // This sets up the device ID and prepares the plugin
      try {
        debugPrint('🔧 Configuring Health instance...');
        await _health!.configure();
        debugPrint('✅ Health instance configured successfully');
      } catch (e) {
        debugPrint('⚠️ Health configure failed: $e');
        // Continue anyway - might work on some platforms
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Health Connect initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Create HealthFactory instance - Android/iOS only
  static dynamic _createHealthFactoryInstance() {
    // Only create HealthFactory on supported platforms
    if (!isAvailable) {
      debugPrint('❌ Health Connect not available on this platform');
      return null;
    }
    
    try {
      // Check if we're on Android/iOS
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('❌ Not on Android/iOS platform');
        return null;
      }
      
      debugPrint('🔧 Creating Health instance for ${Platform.operatingSystem}...');
      
      // Create Health instance directly - Android/iOS only
      // The health package uses Health() not HealthFactory()
      final health = health_package.Health();
      
      debugPrint('✅ Health instance created successfully');
      debugPrint('   Health type: ${health.runtimeType}');
      
      return health;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to create HealthFactory: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get list of HealthDataTypes for permissions
  static List<health_package.HealthDataType> _getHealthDataTypes() {
    return [
      health_package.HealthDataType.DISTANCE_DELTA,
      health_package.HealthDataType.ACTIVE_ENERGY_BURNED,
      health_package.HealthDataType.WORKOUT,
    ];
  }

  /// Extract numeric value from health data point
  static double? _getNumericValue(dynamic value) {
    try {
      if (value is health_package.NumericHealthValue) {
        return value.numericValue.toDouble();
      }
    } catch (e) {
      // Not a numeric value
    }
    return null;
  }

  /// Request Health Connect permissions
  static Future<Map<String, dynamic>> requestPermissions() async {
    if (!isAvailable) {
      return {
        'success': false,
        'message': 'Health Connect is only available on Android/iOS',
      };
    }
    try {
      if (_health == null) {
        final initialized = await initialize();
        if (!initialized) {
          return {
            'success': false,
            'message': 'Failed to initialize Health Connect. Make sure Health Connect app is installed.',
          };
        }
      }

      // Don't check if it's stub - just try to use it
      // On Android/iOS, it will be the real package and work
      // On other platforms, it will be stub but we check Platform.isAndroid/iOS first

      // Check if Health Connect is available before requesting permissions
      // Note: On Android 14+ (especially Android 16), Health Connect is system-integrated
      // so isHealthConnectAvailable() might not work correctly
      if (Platform.isAndroid) {
        try {
          final isAvailable = await _health!.isHealthConnectAvailable();
          debugPrint('🔍 Health Connect available check: $isAvailable');
          
          if (!isAvailable) {
            debugPrint('⚠️ isHealthConnectAvailable() returned false');
            debugPrint('   On Android 14+, Health Connect is system-integrated');
            debugPrint('   This check might be unreliable - continuing anyway');
            // On Android 14+, Health Connect is integrated into the system
            // so we should continue and try to request permissions anyway
            // The permission request will fail gracefully if Health Connect isn't available
          } else {
            debugPrint('✅ Health Connect is available');
          }
        } catch (e) {
          debugPrint('⚠️ Error checking Health Connect availability: $e');
          debugPrint('   On Android 14+, Health Connect is system-integrated');
          debugPrint('   Continuing to try permission request anyway');
          // Continue anyway - on Android 14+, Health Connect is system-integrated
          // so the availability check might fail, but permissions might still work
        }
      }

      // Request permissions for running data
      final types = _getHealthDataTypes();
      debugPrint('🔧 Requesting Health Connect permissions for types: $types');
      debugPrint('   Build version: 134.10.14+231 (Health Connect enabled)');
      debugPrint('   Number of types: ${types.length}');

      // On Android, requestAuthorization should open Health Connect's permission screen
      // The dialog might not appear if:
      // 1. Health Connect isn't installed
      // 2. Permissions were previously denied
      // 3. Health Connect needs to be opened first
      try {
        debugPrint('📱 Calling requestAuthorization...');
        debugPrint('   This should open Health Connect permission screen on Android');
        
        // Check permissions first to see current status
        try {
          final hasPermsBefore = await _health!.hasPermissions(types);
          debugPrint('   Current permission status before request: $hasPermsBefore');
        } catch (e) {
          debugPrint('   Could not check permission status: $e');
        }
        
        // Request authorization - this should open Health Connect's permission screen on Android
        // On Android 14+, this opens Health Connect directly
        // On older versions, this should still open Health Connect if installed
        debugPrint('📱 Calling requestAuthorization() - this should open Health Connect app');
        final granted = await _health!.requestAuthorization(types);
        debugPrint('✅ Health Connect permission request returned: $granted');
        debugPrint('   Note: On Android, this should have opened Health Connect app');
        debugPrint('   If you see this message, Health Connect might not have opened');
        
        // Wait a moment for user to interact with Health Connect
        if (!granted) {
          debugPrint('⚠️ Permission request returned false');
          // Check permission status after request
          try {
            // Wait a bit in case user is still granting permissions
            await Future.delayed(const Duration(seconds: 1));
            final hasPermsAfter = await _health!.hasPermissions(types);
            debugPrint('   Current permission status after request: $hasPermsAfter');
            
            if (hasPermsAfter) {
              debugPrint('✅ Permissions are actually granted!');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_permissionKey, true);
              return {
                'success': true,
                'message': 'Health Connect permissions granted',
              };
            }
          } catch (e) {
            debugPrint('   Could not check permission status: $e');
          }
        }

        if (granted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_permissionKey, true);
          return {
            'success': true,
            'message': 'Health Connect permissions granted',
          };
        } else {
          // Permission dialog didn't appear or was denied
          // Try to check if permissions are already granted (user might have granted manually)
          try {
            final hasPerms = await _health!.hasPermissions(types);
            if (hasPerms) {
              debugPrint('✅ Permissions are actually granted (user may have granted manually)');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_permissionKey, true);
              return {
                'success': true,
                'message': 'Health Connect permissions are already granted',
              };
            }
          } catch (e) {
            debugPrint('⚠️ Could not verify permissions: $e');
          }
          
          // On Android, if requestAuthorization returns false without opening Health Connect,
          // it could mean:
          // 1. App is side-loaded (APK) - Health Connect has restrictions for non-Play Store apps
          // 2. Permissions were previously denied
          // 3. Health Connect needs to be opened manually
          // 4. On Android 14+ (especially Android 16), Health Connect is system-integrated
          debugPrint('⚠️ Health Connect did not open automatically');
          debugPrint('   On Android 14+, Health Connect is system-integrated');
          debugPrint('   You may need to grant permissions manually');
          
          return {
            'success': false,
            'message': 'Health Connect permission screen did not open automatically.\n\nOn Android 14+, Health Connect is integrated into the system. To grant permissions manually:\n\n1. Open Settings on your device\n2. Go to Security & Privacy > Privacy > Health Connect\n   (Or search for "Health Connect" in Settings)\n3. Tap "Apps and services"\n4. Find "Mooves" and tap it\n5. Grant permissions for:\n   - Distance\n   - Active Energy\n   - Workouts\n6. Return to Mooves and try connecting again\n\nIf you installed the app from the Play Store alpha test, permissions should work automatically. If not, please grant them manually as described above.',
            'needsSettings': true,
            'sideLoaded': false,
          };
        }
      } catch (e) {
        debugPrint('❌ Exception during requestAuthorization: $e');
        // Check if permissions might already be granted
        try {
          final types = _getHealthDataTypes();
          final hasPerms = await _health!.hasPermissions(types);
          if (hasPerms) {
            debugPrint('✅ Permissions are actually granted');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_permissionKey, true);
            return {
              'success': true,
              'message': 'Health Connect permissions are already granted',
            };
          }
        } catch (e2) {
          debugPrint('⚠️ Could not check permissions: $e2');
        }
        
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e, stackTrace) {
      debugPrint('Error requesting Health Connect permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error requesting permissions: $e. Make sure Health Connect app is installed and up to date.',
      };
    }
  }

  /// Check if permissions are granted
  static Future<bool> hasPermissions() async {
    if (!isAvailable) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_permissionKey);
      if (stored == true) {
        // Verify permissions are still valid
        if (_health == null) {
          final initialized = await initialize();
          if (!initialized) {
            return false;
          }
        }
        final types = _getHealthDataTypes();
        return await _health!.hasPermissions(types);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking Health Connect permissions: $e');
      return false;
    }
  }

  /// Get Health Connect connection status
  static Future<Map<String, dynamic>> getStatus() async {
    if (!isAvailable) {
      return {
        'connected': false,
        'message': 'Health Connect is only available on Android/iOS',
      };
    }
    try {
      final hasPerms = await hasPermissions();
      return {
        'connected': hasPerms,
        'message': hasPerms 
            ? 'Health Connect is connected' 
            : 'Health Connect is not connected',
      };
    } catch (e) {
      debugPrint('Error getting Health Connect status: $e');
      return {
        'connected': false,
        'message': 'Error checking Health Connect status: $e',
      };
    }
  }

  /// Sync activities from Health Connect
  static Future<Map<String, dynamic>> syncActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAvailable) {
      return {
        'success': false,
        'message': 'Health Connect is only available on Android/iOS',
        'activities': [],
      };
    }
    try {
      if (_health == null) {
        final initialized = await initialize();
        if (!initialized) {
          return {
            'success': false,
            'message': 'Failed to initialize Health Connect',
            'activities': [],
          };
        }
      }

      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        return {
          'success': false,
          'message': 'Health Connect permissions not granted',
          'activities': [],
        };
      }

      final types = _getHealthDataTypes();
      debugPrint('Syncing Health Connect activities from $startDate to $endDate');

      final healthData = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        types,
      );

      debugPrint('Retrieved ${healthData.length} health data points');

      // Convert health data to training entries
      final activities = <Map<String, dynamic>>[];
      final prefs = await SharedPreferences.getInstance();
      final existingEntriesJson = prefs.getString('training_entries') ?? '[]';
      final existingEntries = (jsonDecode(existingEntriesJson) as List)
          .map((e) => TrainingEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final dataPoint in healthData) {
        try {
          final dateFrom = dataPoint.dateFrom;
          final dateTo = dataPoint.dateTo;
          final typeString = dataPoint.typeString;
          final value = dataPoint.value;

          if (dateFrom == null || dateTo == null) continue;

          // Process distance data
          if (typeString == 'DISTANCE_DELTA' || typeString?.contains('distance') == true) {
            final distance = _getNumericValue(value);
            if (distance != null && distance > 0) {
              final duration = dateTo.difference(dateFrom).inSeconds;
              if (duration > 0) {
                // Check if this entry already exists
                final distanceKm = distance / 1000; // Convert meters to km
                final exists = existingEntries.any((e) =>
                    e.date.isAtSameMomentAs(dateFrom) &&
                    e.distanceKm != null &&
                    (e.distanceKm! - distanceKm).abs() < 0.1);
                
                if (!exists) {
                  activities.add({
                    'date': dateFrom.toIso8601String(),
                    'distance': distanceKm,
                    'duration': duration,
                    'source': 'health_connect',
                  });
                }
              }
            }
          }

          // Process workout data
          if (typeString == 'WORKOUT' || typeString?.contains('workout') == true) {
            // Workout data might contain distance and duration
            // This is handled by the distance processing above
          }
        } catch (e) {
          debugPrint('Error processing health data point: $e');
        }
      }

      // Save new activities to SharedPreferences
      if (activities.isNotEmpty) {
        for (final activity in activities) {
          final entry = TrainingEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Health Connect Activity',
            date: DateTime.parse(activity['date']),
            distanceKm: activity['distance'] as double,
            durationMinutes: (activity['duration'] as int) ~/ 60, // Convert seconds to minutes
          );
          existingEntries.add(entry);
        }

        // Sort by date (newest first)
        existingEntries.sort((a, b) => b.date.compareTo(a.date));

        // Save to SharedPreferences
        final entriesJson = jsonEncode(
          existingEntries.map((e) => e.toJson()).toList(),
        );
        await prefs.setString('training_entries', entriesJson);
      }

      return {
        'success': true,
        'message': 'Synced ${activities.length} activities from Health Connect',
        'activities': activities,
      };
    } catch (e, stackTrace) {
      debugPrint('Error syncing Health Connect activities: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error syncing activities: $e',
        'activities': [],
      };
    }
  }

  /// Disconnect Health Connect
  static Future<Map<String, dynamic>> disconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_permissionKey);
      _health = null;
      return {
        'success': true,
        'message': 'Health Connect disconnected',
      };
    } catch (e) {
      debugPrint('Error disconnecting Health Connect: $e');
      return {
        'success': false,
        'message': 'Error disconnecting: $e',
      };
    }
  }
}

