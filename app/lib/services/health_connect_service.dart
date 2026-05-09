import 'package:health/health.dart';

/// Wraps the `health` package for reading weight data from Health Connect.
class HealthConnectService {
  final Health _health = Health();
  bool _configured = false;

  /// Initialize the Health instance and configure Health Connect.
  Future<void> configure() async {
    if (_configured) return;
    _health.configure();
    _configured = true;
  }

  /// Request read permission for weight data.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    await configure();
    final types = [HealthDataType.WEIGHT];
    final permissions = [HealthDataAccess.READ];
    final granted = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    return granted;
  }

  /// Check if we already have weight read permission.
  Future<bool> hasPermission() async {
    await configure();
    final result = await _health.hasPermissions(
      [HealthDataType.WEIGHT],
      permissions: [HealthDataAccess.READ],
    );
    return result ?? false;
  }

  /// Fetch weight data points from Health Connect in the given date range.
  /// Returns a list of maps with `weight` (double, kg) and `recordedAt` (DateTime).
  Future<List<HealthDataPoint>> fetchWeights(
    DateTime from,
    DateTime to,
  ) async {
    await configure();
    final data = await _health.getHealthDataFromTypes(
      startTime: from,
      endTime: to,
      types: [HealthDataType.WEIGHT],
    );
    // Remove duplicates from multiple sources
    return _health.removeDuplicates(data);
  }
}
