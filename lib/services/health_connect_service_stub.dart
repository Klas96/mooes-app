// Stub file for non-mobile platforms (web, desktop, Linux)
// This file provides empty implementations to allow compilation on all platforms

class Health {
  Health({dynamic deviceInfo});
  
  Future<bool> requestAuthorization(List<dynamic> types) async => false;
  Future<bool> hasPermissions(List<dynamic> types) async => false;
  Future<List<HealthDataPoint>> getHealthDataFromTypes(
    DateTime start,
    DateTime end,
    List<dynamic> types,
  ) async => [];
}

class HealthDataType {
  static const HealthDataType DISTANCE_DELTA = HealthDataType._('DISTANCE_DELTA');
  static const HealthDataType ACTIVE_ENERGY_BURNED = HealthDataType._('ACTIVE_ENERGY_BURNED');
  static const HealthDataType WORKOUT = HealthDataType._('WORKOUT');
  
  final String value;
  const HealthDataType._(this.value);
}

class NumericHealthValue {
  final double numericValue;
  NumericHealthValue(this.numericValue);
}

class HealthDataPoint {
  final String? uuid;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? typeString;
  final dynamic value;
  
  HealthDataPoint({
    this.uuid,
    this.dateFrom,
    this.dateTo,
    this.typeString,
    this.value,
  });
}

class HealthFactory {
  HealthFactory();
  // Returns a Health instance (stub implementation)
  Health call() => Health();
}
