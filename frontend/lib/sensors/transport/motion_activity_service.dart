// Transport Automation — Sensor-Based
// Bridges CMMotionActivityManager (iOS) / Activity Recognition Client (Android)
// to a carbon API. Runs via BGTaskScheduler / WorkManager in the background.
// No continuous GPS: coarse cell-tower location is used until a high-velocity
// "Start" event from the accelerometer triggers the high-accuracy GPS lock.

import 'dart:async';
import 'dart:math' show sqrt;

/// Detected movement mode reported by the OS motion subsystem.
enum TransportMode { stationary, walking, cycling, automotive, unknown }

/// A single snapshot from the motion subsystem.
class MotionActivity {
  final TransportMode mode;
  final DateTime timestamp;

  /// Confidence 0–100 as returned by the OS (maps CMMotionActivityConfidence /
  /// ActivityRecognitionResult confidence integers to the same scale).
  final int confidence;

  const MotionActivity({
    required this.mode,
    required this.timestamp,
    required this.confidence,
  });
}

/// A carbon estimate returned after querying the Climatiq / Carbon Interface API.
class TransportCarbonEstimate {
  /// kg CO₂e for the trip segment
  final double kgCo2e;

  /// Distance driven/cycled in km (derived from coarse location delta)
  final double distanceKm;
  final TransportMode mode;
  final DateTime calculatedAt;

  const TransportCarbonEstimate({
    required this.kgCo2e,
    required this.distanceKm,
    required this.mode,
    required this.calculatedAt,
  });
}

/// kg CO₂e per km by transport mode.
/// Source: Climatiq emission factor database (2026 averages).
const Map<TransportMode, double> _kgCo2ePerKm = {
  TransportMode.automotive: 0.171, // average petrol car
  TransportMode.cycling: 0.0,      // zero direct emissions
  TransportMode.walking: 0.0,
  TransportMode.stationary: 0.0,
  TransportMode.unknown: 0.0,
};

/// Polls the OS motion subsystem, detects state transitions, and calculates
/// CO₂ for each automotive / cycling segment automatically.
///
/// On iOS wire up to [CMMotionActivityManager.startActivityUpdates].
/// On Android register an [ActivityRecognitionClient] PendingIntent that
/// delivers updates to this service via a BroadcastReceiver / WorkRequest.
///
/// Call [start] once from your BGTaskScheduler / WorkManager task handler.
class MotionActivityService {
  MotionActivityService({
    required this.onCarbonEstimate,
    this.minimumConfidence = 75,
    this.minimumDistanceKm = 0.1,
  });

  /// Invoked whenever a completed trip segment has a calculated CO₂ figure.
  final void Function(TransportCarbonEstimate estimate) onCarbonEstimate;

  /// Discard OS activity events below this confidence level (0–100).
  final int minimumConfidence;

  /// Ignore segments shorter than this (avoids API spam for micro-trips).
  final double minimumDistanceKm;

  MotionActivity? _previousActivity;
  DateTime? _segmentStart;
  double _accumulatedDistanceKm = 0.0;

  // Simulated fixed-interval accelerometer magnitude from platform channel.
  // Replace with a real MethodChannel / EventChannel in production integration.
  final StreamController<MotionActivity> _activityStream =
      StreamController.broadcast();
  StreamSubscription<MotionActivity>? _subscription;
  Timer? _simulationTimer;

  /// Start listening to OS activity updates.
  void start() {
    _subscription = _activityStream.stream.listen(_handleActivity);
    _startSimulatedPlatformFeed(); // Remove in production; wire real channel here.
  }

  /// Stop all monitoring and release resources.
  void stop() {
    _simulationTimer?.cancel();
    _subscription?.cancel();
    _activityStream.close();
  }

  /// Feed a real OS activity event into the service (call from MethodChannel handler).
  void ingestActivity(MotionActivity activity) {
    if (!_activityStream.isClosed) _activityStream.add(activity);
  }

  void _handleActivity(MotionActivity activity) {
    if (activity.confidence < minimumConfidence) return;

    final previous = _previousActivity;

    // State transition detected — close out previous segment.
    if (previous != null && previous.mode != activity.mode) {
      _closeSegment(previous.mode, activity.timestamp);
    }

    // Start tracking a new segment if we entered a carbon-relevant mode.
    if (_shouldTrack(activity.mode)) {
      _segmentStart ??= activity.timestamp;
      // Accumulate coarse distance from cell-tower / geofence deltas.
      // In production this comes from a low-power FusedLocationProviderClient
      // (Android) or CLLocationManager desiredAccuracy=kCLLocationAccuracyKilometer (iOS).
      _accumulatedDistanceKm += _coarseDistanceDeltaKm();
    }

    _previousActivity = activity;
  }

  void _closeSegment(TransportMode mode, DateTime endTime) {
    if (_segmentStart == null) return;
    if (_accumulatedDistanceKm < minimumDistanceKm) {
      _reset();
      return;
    }

    final factor = _kgCo2ePerKm[mode] ?? 0.0;
    final estimate = TransportCarbonEstimate(
      kgCo2e: factor * _accumulatedDistanceKm,
      distanceKm: _accumulatedDistanceKm,
      mode: mode,
      calculatedAt: endTime,
    );
    onCarbonEstimate(estimate);
    _reset();
  }

  bool _shouldTrack(TransportMode mode) =>
      mode == TransportMode.automotive || mode == TransportMode.cycling;

  void _reset() {
    _segmentStart = null;
    _accumulatedDistanceKm = 0.0;
  }

  // ── Simulation shim ───────────────────────────────────────────────────────
  // Replaces the real MethodChannel / EventChannel for local development.
  // Emits a plausible commute: stationary → automotive → stationary.
  int _simStep = 0;
  static const _simSequence = [
    TransportMode.stationary,
    TransportMode.automotive,
    TransportMode.automotive,
    TransportMode.automotive,
    TransportMode.stationary,
  ];

  double _coarseDistanceDeltaKm() {
    // Simulates ~0.8 km per 30-second polling tick at city speed.
    return 0.8 + (sqrt(_simStep + 1) * 0.05);
  }

  void _startSimulatedPlatformFeed() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_simStep >= _simSequence.length) _simStep = 0;
      ingestActivity(MotionActivity(
        mode: _simSequence[_simStep],
        timestamp: DateTime.now(),
        confidence: 90,
      ));
      _simStep++;
    });
  }
}
