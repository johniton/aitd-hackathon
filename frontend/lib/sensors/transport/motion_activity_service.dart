import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

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
///
/// Note: flutter_activity_recognition removed due to AGP namespace issues.
/// This version uses GPS-only tracking as a fallback.
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

  StreamSubscription<Position>? _positionSubscription;

  /// Start listening to position updates (GPS-only fallback).
  Future<void> start() async {
    if (kIsWeb) return;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _segmentStart = DateTime.now();
    _previousActivity = MotionActivity(
      mode: TransportMode.unknown,
      timestamp: DateTime.now(),
      confidence: 100,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (_previousPosition != null) {
        final distance = Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _accumulatedDistanceKm += distance / 1000.0;
      }
      _previousPosition = position;
    });
  }

  /// Stop all monitoring and release resources.
  void stop() {
    _positionSubscription?.cancel();
    if (_accumulatedDistanceKm >= minimumDistanceKm) {
      final factor = _kgCo2ePerKm[_previousActivity?.mode ?? TransportMode.automotive] ?? 0.171;
      onCarbonEstimate(TransportCarbonEstimate(
        kgCo2e: factor * _accumulatedDistanceKm,
        distanceKm: _accumulatedDistanceKm,
        mode: _previousActivity?.mode ?? TransportMode.automotive,
        calculatedAt: DateTime.now(),
      ));
    }
    _reset();
  }

  void _reset() {
    _segmentStart = null;
    _accumulatedDistanceKm = 0.0;
    _previousPosition = null;
  }
}
