// Digital Automation — System-Based (Device Footprint)
// Queries Android BatteryManager + NetworkStatsManager (or iOS
// UIDevice + NetworkExtension) to calculate the phone's own carbon
// footprint from data transfer and battery consumption.
//
// All math runs locally on-device. No raw data leaves the phone.
// Only the final kgCO₂e figure is sent to the backend.

/// Network interface type — determines the energy intensity factor applied.
enum NetworkInterface {
  wifi,
  cellular4g,
  cellular5g,
}

/// A snapshot of the device's energy and data consumption over a measurement
/// window (typically one WorkManager / BGTask interval, e.g. 4 hours).
class DeviceUsageSnapshot {
  /// Data transferred over each interface during the window (bytes).
  final Map<NetworkInterface, double> bytesTransferred;

  /// Battery charge consumed during the window (0.0–1.0, e.g. 0.12 = 12%).
  final double batteryDelta;

  /// Battery capacity in Wh (read once from BatteryManager.EXTRA_SCALE on Android
  /// or IOKit on iOS; hardcode typical 4500 mAh / 3.7 V = 16.65 Wh if not available).
  final double batteryCapacityWh;

  /// Real-time grid carbon intensity at the device's coarse location (gCO₂/kWh).
  /// Provide 436 gCO₂/kWh as the global average fallback if Electricity Maps is
  /// unavailable (e.g. no network).
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

/// Breakdown of device CO₂e for one measurement window.
class DeviceFootprintResult {
  /// kWh used by the battery during the window
  final double batteryEnergyKwh;

  /// kWh attributed to data transfer (all interfaces combined)
  final double networkEnergyKwh;

  /// Total kWh (battery + network)
  final double totalEnergyKwh;

  /// Total kg CO₂e
  final double kgCo2e;

  final DateTime calculatedAt;

  const DeviceFootprintResult({
    required this.batteryEnergyKwh,
    required this.networkEnergyKwh,
    required this.totalEnergyKwh,
    required this.kgCo2e,
    required this.calculatedAt,
  });
}

// ── Energy intensity constants ────────────────────────────────────────────────
// Source: Cloud Carbon Footprint methodology (2026 update).
// All values are kWh per GB transferred on that interface.
const double _kwhPerGbWifi = 0.06;
const double _kwhPerGb4g = 0.11;
const double _kwhPerGb5g = 0.08; // 5G is more efficient per bit at scale

const double _bytesPerGb = 1024 * 1024 * 1024;

// ── Service ───────────────────────────────────────────────────────────────────

/// Calculates a device's own digital carbon footprint from OS-provided energy
/// and network statistics.
///
/// iOS integration:
///   - batteryDelta: [UIDevice.current.batteryLevel] diff between two readings.
///   - bytesTransferred: [NWPathMonitor] or [NetworkExtension] byte counters.
///   - batteryCapacityWh: read from IOKit (requires entitlement) or use 16.65 Wh.
///
/// Android integration:
///   - batteryDelta: [BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER] diff.
///   - bytesTransferred: [NetworkStatsManager.querySummaryForDevice].
///   - batteryCapacityWh: parse /sys/class/power_supply/battery/charge_full_design.
///
/// Grid intensity:
///   - Call Electricity Maps API with coarse GPS (cell-tower accuracy is enough).
///   - Cache the result for 1 hour; fall back to 436 gCO₂/kWh if offline.
class DeviceFootprintService {
  DeviceFootprintService({required this.onFootprintCalculated});

  /// Fired after each [calculate] call with the computed result.
  final void Function(DeviceFootprintResult result) onFootprintCalculated;

  /// Calculate carbon footprint for the provided usage snapshot.
  /// All computation is local — no network call is made here.
  DeviceFootprintResult calculate(DeviceUsageSnapshot snapshot) {
    final batteryEnergyKwh = _batteryToKwh(
      snapshot.batteryDelta,
      snapshot.batteryCapacityWh,
    );
    final networkEnergyKwh = _networkToKwh(snapshot.bytesTransferred);
    final totalKwh = batteryEnergyKwh + networkEnergyKwh;

    // Convert kWh to kg CO₂e using real-time grid intensity.
    final kgCo2e =
        totalKwh * (snapshot.gridIntensityGramsPerKwh / 1000);

    final result = DeviceFootprintResult(
      batteryEnergyKwh: batteryEnergyKwh,
      networkEnergyKwh: networkEnergyKwh,
      totalEnergyKwh: totalKwh,
      kgCo2e: kgCo2e,
      calculatedAt: DateTime.now(),
    );
    onFootprintCalculated(result);
    return result;
  }

  double _batteryToKwh(double batteryDelta, double capacityWh) {
    // batteryDelta is a fraction (0.0–1.0), capacityWh is total battery in Wh.
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

  // ── Simulation helper ──────────────────────────────────────────────────────
  // Generates a realistic 4-hour snapshot for local development.
  // Wire real platform channel values in production.
  DeviceUsageSnapshot simulateSnapshot({double gridIntensityGramsPerKwh = 400}) {
    final now = DateTime.now();
    return DeviceUsageSnapshot(
      bytesTransferred: {
        NetworkInterface.wifi: 1.8 * _bytesPerGb,      // ~1.8 GB via Wi-Fi
        NetworkInterface.cellular4g: 0.25 * _bytesPerGb, // ~250 MB on LTE
        NetworkInterface.cellular5g: 0.0,
      },
      batteryDelta: 0.12,      // 12% drain over 4-hour window
      batteryCapacityWh: 16.65, // typical flagship phone
      gridIntensityGramsPerKwh: gridIntensityGramsPerKwh,
      windowStart: now.subtract(const Duration(hours: 4)),
      windowEnd: now,
    );
  }
}
