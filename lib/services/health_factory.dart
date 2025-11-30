// Factory function for creating HealthFactory
// This file will be conditionally replaced on Android/iOS

import 'package:mooves/services/health_connect_service_stub.dart' as health_stub;

/// Create HealthFactory - stub implementation
dynamic createHealthFactory() {
  return health_stub.HealthFactory();
}

