import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

enum TransportMode { stationary, walking, cycling, automotive, unknown }

class MotionActivity {
  final TransportMode mode;
  final DateTime timestamp;
  final int confidence;
  const MotionActivity({
    required this.mode,
    required this.timestamp,
    required this.confidence,
  });
}

class TransportCarbonEstimate {
  final double kgCo2e;
  final double distanceKm;
  final TransportMode mode;
  final double speedKmh;
  final DateTime calculatedAt;
  const TransportCarbonEstimate({
    required this.kgCo2e,
    required this.distanceKm,
    required this.mode,
    required this.speedKmh,
    required this.calculatedAt,
  });
}

const Map<TransportMode, double> _kgCo2ePerKm = {
  TransportMode.automotive: 0.171,
  TransportMode.cycling: 0.0,
  TransportMode.walking: 0.0,
  TransportMode.stationary: 0.0,
  TransportMode.unknown: 0.0,
};

// Speed thresholds inferred from GPS
const double _walkMaxKmh = 7.0;    // 0–7 km/h → walking
const double _cycleMaxKmh = 30.0;  // 7–30 km/h → cycling / e-scooter
// > 30 km/h → automotive

TransportMode _inferMode(double speedKmh) {
  if (speedKmh < 0.5) return TransportMode.stationary;
  if (speedKmh <= _walkMaxKmh) return TransportMode.walking;
  if (speedKmh <= _cycleMaxKmh) return TransportMode.cycling;
  return TransportMode.automotive;
}

class MotionActivityService {
  MotionActivityService({
    required this.onCarbonEstimate,
    this.onModeChanged,
    this.minimumDistanceKm = 0.05,
    this.emitIntervalSeconds = 30,
  });

  final void Function(TransportCarbonEstimate estimate) onCarbonEstimate;
  final void Function(TransportMode mode, double speedKmh)? onModeChanged;
  final double minimumDistanceKm;
  final int emitIntervalSeconds;

  TransportMode _currentMode = TransportMode.unknown;
  double _speedKmh = 0.0;
  double _accumulatedDistanceKm = 0.0;
  Position? _previousPosition;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _emitTimer;

  double get currentSpeedKmh => _speedKmh;
  TransportMode get currentMode => _currentMode;

  Future<void> start() async {
    if (kIsWeb) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    _emitTimer = Timer.periodic(Duration(seconds: emitIntervalSeconds), (_) {
      _emitCurrentSegment();
    });
  }

  void _onPosition(Position position) {
    final speedMs = position.speed.clamp(0.0, double.infinity).toDouble();
    _speedKmh = speedMs * 3.6;

    final newMode = _inferMode(_speedKmh);

    if (_previousPosition != null) {
      final distanceM = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _accumulatedDistanceKm += distanceM / 1000.0;
    }
    _previousPosition = position;

    if (newMode != _currentMode) {
      if (_accumulatedDistanceKm >= minimumDistanceKm) {
        _emitCurrentSegment();
      }
      _currentMode = newMode;
      onModeChanged?.call(newMode, _speedKmh);
    }
  }

  void _emitCurrentSegment() {
    final dist = _accumulatedDistanceKm;
    if (dist < minimumDistanceKm && _currentMode == TransportMode.stationary) return;
    final factor = _kgCo2ePerKm[_currentMode] ?? 0.0;
    onCarbonEstimate(TransportCarbonEstimate(
      kgCo2e: factor * dist,
      distanceKm: dist,
      mode: _currentMode,
      speedKmh: _speedKmh,
      calculatedAt: DateTime.now(),
    ));
    _accumulatedDistanceKm = 0.0;
  }

  void stop() {
    _positionSubscription?.cancel();
    _emitTimer?.cancel();
    if (_accumulatedDistanceKm >= minimumDistanceKm) {
      _emitCurrentSegment();
    }
    _currentMode = TransportMode.unknown;
    _speedKmh = 0.0;
    _previousPosition = null;
    _accumulatedDistanceKm = 0.0;
  }
}
