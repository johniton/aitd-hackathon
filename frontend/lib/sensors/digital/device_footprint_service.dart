import 'dart:async';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'grid_intensity_service.dart';

/// Network interface type — determines the energy intensity factor applied.
enum NetworkInterface { wifi, cellular4g, cellular5g }

/// A snapshot of the device's energy and data consumption.
class DeviceUsageSnapshot {
  final Map<NetworkInterface, double> bytesTransferred;
  final double batteryDelta;
  final double batteryCapacityWh;
  final double gridIntensityGramsPerKwh;
  final DateTime windowStart;
  final DateTime windowEnd;

  const DeviceUsageSnapshot({
    required this.bytesTransferred,
    required this.batteryDelta,
    required this.batteryCapacityWh,
    required this.gridIntensityGramsPerKwh,
    required this.windowStart,
    required this.windowEnd,
  });
}

/// Breakdown of device CO₂e.
class DeviceFootprintResult {
  final double batteryEnergyKwh;
  final double networkEnergyKwh;
  final double networkBytes;
  final double totalEnergyKwh;
  final double kgCo2e;
  final DateTime calculatedAt;

  const DeviceFootprintResult({
    required this.batteryEnergyKwh,
    required this.networkEnergyKwh,
    required this.networkBytes,
    required this.totalEnergyKwh,
    required this.kgCo2e,
    required this.calculatedAt,
  });
}

const double _kwhPerGbWifi = 0.06;
const double _kwhPerGb4g = 0.11;
const double _kwhPerGb5g = 0.08;
const double _bytesPerGb = 1024 * 1024 * 1024;

enum _DemoNet { wifi, mobile }

class DeviceFootprintService {
  DeviceFootprintService({
    required this.onFootprintCalculated,
    this.intervalSeconds = 10,
    this.isDemoMode = false,
  });

  final void Function(DeviceFootprintResult result) onFootprintCalculated;
  final int intervalSeconds;
  final bool isDemoMode;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final GridIntensityService _gridService = GridIntensityService();
  final Random _rng = Random();

  int? _lastBatteryLevel;
  DateTime? _lastCheck;
  Timer? _monitorTimer;

  /// Start periodic monitoring of device stats.
  void start() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
      timer,
    ) async {
      final snapshot = await captureSnapshot();
      if (snapshot != null) {
        calculate(snapshot);
      }
    });
  }

  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Captures a real usage snapshot from the system.
  Future<DeviceUsageSnapshot?> captureSnapshot() async {
    final now = DateTime.now();
    final level = isDemoMode
        ? ((_lastBatteryLevel ?? 100) - _rng.nextInt(2)).clamp(5, 100)
        : await _battery.batteryLevel;
    final connectivity = isDemoMode
        ? ([_DemoNet.wifi, _DemoNet.mobile][_rng.nextInt(2)])
        : await _connectivity.checkConnectivity();
    final intensity = await _gridService.fetchIntensity();

    if (_lastBatteryLevel == null || _lastCheck == null) {
      _lastBatteryLevel = level;
      _lastCheck = now;
      return null;
    }

    final delta = (_lastBatteryLevel! - level).clamp(0, 100) / 100.0;

    // Note: connectivity_plus doesn't provide raw byte counters.
    // In a production app, you would use a MethodChannel to query
    // NetworkStatsManager (Android) or NWPathMonitor (iOS).
    // For this implementation, we estimate based on active interface.
    final bytes = <NetworkInterface, double>{};
    final isWifi =
        connectivity == ConnectivityResult.wifi ||
        connectivity == _DemoNet.wifi;
    final isMobile =
        connectivity == ConnectivityResult.mobile ||
        connectivity == _DemoNet.mobile;
    if (isWifi) {
      final gb = isDemoMode ? 0.01 + _rng.nextDouble() * 0.03 : 0.5;
      bytes[NetworkInterface.wifi] = gb * _bytesPerGb;
    } else if (isMobile) {
      final gb = isDemoMode ? 0.005 + _rng.nextDouble() * 0.015 : 0.1;
      bytes[NetworkInterface.cellular4g] = gb * _bytesPerGb;
    }

    final snapshot = DeviceUsageSnapshot(
      bytesTransferred: bytes,
      batteryDelta: delta,
      batteryCapacityWh: 16.65, // Default for modern flagships
      gridIntensityGramsPerKwh: intensity,
      windowStart: _lastCheck!,
      windowEnd: now,
    );

    _lastBatteryLevel = level;
    _lastCheck = now;
    return snapshot;
  }

  /// Calculate carbon footprint for the provided usage snapshot.
  DeviceFootprintResult calculate(DeviceUsageSnapshot snapshot) {
    final batteryEnergyKwh = _batteryToKwh(
      snapshot.batteryDelta,
      snapshot.batteryCapacityWh,
    );
    final networkEnergyKwh = _networkToKwh(snapshot.bytesTransferred);
    final networkBytes = snapshot.bytesTransferred.values.fold(
      0.0,
      (a, b) => a + b,
    );
    final totalKwh = batteryEnergyKwh + networkEnergyKwh;

    final kgCo2e = totalKwh * (snapshot.gridIntensityGramsPerKwh / 1000);

    final result = DeviceFootprintResult(
      batteryEnergyKwh: batteryEnergyKwh,
      networkEnergyKwh: networkEnergyKwh,
      networkBytes: networkBytes,
      totalEnergyKwh: totalKwh,
      kgCo2e: kgCo2e,
      calculatedAt: DateTime.now(),
    );

    onFootprintCalculated(result);
    return result;
  }

  double _batteryToKwh(double batteryDelta, double capacityWh) {
    return (batteryDelta * capacityWh) / 1000.0;
  }

  double _networkToKwh(Map<NetworkInterface, double> bytesTransferred) {
    double total = 0.0;
    for (final entry in bytesTransferred.entries) {
      final gb = entry.value / _bytesPerGb;
      total += switch (entry.key) {
        NetworkInterface.wifi => gb * _kwhPerGbWifi,
        NetworkInterface.cellular4g => gb * _kwhPerGb4g,
        NetworkInterface.cellular5g => gb * _kwhPerGb5g,
      };
    }
    return total;
  }
}
