import 'dart:async';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

/// Detected movement mode reported by the OS motion subsystem.
enum TransportMode { stationary, walking, cycling, automotive, unknown }

/// A single snapshot from the motion subsystem.
class MotionActivity {
  final TransportMode mode;
  final DateTime timestamp;

  /// Confidence 0–100 as returned by the OS.
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

  /// Distance driven/cycled in km
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
  Position? _previousPosition;
  double _accumulatedDistanceKm = 0.0;

  StreamSubscription<Activity>? _subscription;

  /// Start listening to OS activity updates.
  Future<void> start() async {
    // Request permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _subscription = FlutterActivityRecognition.instance.activityStream.listen((activity) {
      final motionActivity = _mapToMotionActivity(activity);
      _handleActivity(motionActivity);
    });
  }

  /// Stop all monitoring and release resources.
  void stop() {
    _subscription?.cancel();
  }

  void _handleActivity(MotionActivity activity) async {
    if (activity.confidence < minimumConfidence) return;

    final previous = _previousActivity;

    // State transition detected — close out previous segment.
    if (previous != null && previous.mode != activity.mode) {
      await _closeSegment(previous.mode, activity.timestamp);
    }

    // Start tracking a new segment if we entered a carbon-relevant mode.
    if (_shouldTrack(activity.mode)) {
      _segmentStart ??= activity.timestamp;
      
      // Update distance
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      
      if (_previousPosition != null) {
        final distance = Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        _accumulatedDistanceKm += distance / 1000.0;
      }
      _previousPosition = currentPosition;
    } else {
      _previousPosition = null; // Reset position when stationary/walking
    }

    _previousActivity = activity;
  }

  Future<void> _closeSegment(TransportMode mode, DateTime endTime) async {
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
    _previousPosition = null;
  }

  MotionActivity _mapToMotionActivity(Activity activity) {
    TransportMode mode = switch (activity.type) {
      ActivityType.STILL => TransportMode.stationary,
      ActivityType.WALKING || ActivityType.RUNNING => TransportMode.walking,
      ActivityType.ON_BICYCLE => TransportMode.cycling,
      ActivityType.IN_VEHICLE => TransportMode.automotive,
      _ => TransportMode.unknown,
    };

    int confidence = switch (activity.confidence) {
      ActivityConfidence.HIGH => 100,
      ActivityConfidence.MEDIUM => 50,
      ActivityConfidence.LOW => 25,
    };

    return MotionActivity(
      mode: mode,
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }
}

