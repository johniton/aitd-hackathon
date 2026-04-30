import 'dart:async';
import 'dart:math';
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
const double _walkMaxKmh = 7.0; // 0–7 km/h → walking
const double _cycleMaxKmh = 30.0; // 7–30 km/h → cycling / e-scooter
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
    this.emitIntervalSeconds = 5,
    this.isDemoMode = false,
  });

  final void Function(TransportCarbonEstimate estimate) onCarbonEstimate;
  final void Function(TransportMode mode, double speedKmh)? onModeChanged;
  final double minimumDistanceKm;
  final int emitIntervalSeconds;
  final bool isDemoMode;

  TransportMode _currentMode = TransportMode.unknown;
  double _speedKmh = 0.0;
  double _accumulatedDistanceKm = 0.0;
  Position? _previousPosition;
  DateTime? _previousTimestamp;
  int _stationaryTicks = 0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _emitTimer;
  Timer? _demoTimer;
  final Random _rng = Random();

  double get currentSpeedKmh => _speedKmh;
  TransportMode get currentMode => _currentMode;

  Future<void> start() async {
    if (isDemoMode || kIsWeb) {
      _startDemoSimulation();
      return;
    }

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

  void _startDemoSimulation() {
    _demoTimer?.cancel();
    _currentMode = TransportMode.stationary;
    _speedKmh = 0.0;
    _demoTimer = Timer.periodic(Duration(seconds: emitIntervalSeconds), (_) {
      final roll = _rng.nextInt(100);
      if (roll < 20) {
        _currentMode = TransportMode.walking;
        _speedKmh = 3 + _rng.nextDouble() * 3;
      } else if (roll < 35) {
        _currentMode = TransportMode.cycling;
        _speedKmh = 12 + _rng.nextDouble() * 12;
      } else if (roll < 90) {
        _currentMode = TransportMode.automotive;
        _speedKmh = 15 + _rng.nextDouble() * 45;
      } else {
        _currentMode = TransportMode.stationary;
        _speedKmh = 0;
      }

      final distanceKm = (_speedKmh / 3600.0) * emitIntervalSeconds;
      _accumulatedDistanceKm = distanceKm;
      onModeChanged?.call(_currentMode, _speedKmh);
      _emitCurrentSegment();
    });
  }

  void _onPosition(Position position) {
    double inferredSpeedKmh = 0;
    if (_previousPosition != null && _previousTimestamp != null) {
      final distanceM = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final dtS =
          position.timestamp.difference(_previousTimestamp!).inMilliseconds /
          1000.0;
      if (dtS > 0) {
        inferredSpeedKmh = (distanceM / dtS) * 3.6;
      }
      // If GPS jitter is tiny movement, treat as stationary.
      if (distanceM < 3) {
        _stationaryTicks += 1;
      } else {
        _stationaryTicks = 0;
      }
      _accumulatedDistanceKm += distanceM / 1000.0;
    }
    final reportedSpeedKmh =
        position.speed.clamp(0.0, double.infinity).toDouble() * 3.6;
    _speedKmh = inferredSpeedKmh > 0 ? inferredSpeedKmh : reportedSpeedKmh;
    if (_stationaryTicks >= 2 || _speedKmh < 1.5) {
      _speedKmh = 0;
    }
    final newMode = _inferMode(_speedKmh);

    _previousPosition = position;
    _previousTimestamp = position.timestamp;

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
    if (dist < minimumDistanceKm && _currentMode == TransportMode.stationary) {
      return;
    }
    final factor = _kgCo2ePerKm[_currentMode] ?? 0.0;
    onCarbonEstimate(
      TransportCarbonEstimate(
        kgCo2e: factor * dist,
        distanceKm: dist,
        mode: _currentMode,
        speedKmh: _speedKmh,
        calculatedAt: DateTime.now(),
      ),
    );
    _accumulatedDistanceKm = 0.0;
  }

  void stop() {
    _positionSubscription?.cancel();
    _emitTimer?.cancel();
    _demoTimer?.cancel();
    if (_accumulatedDistanceKm >= minimumDistanceKm) {
      _emitCurrentSegment();
    }
    _currentMode = TransportMode.unknown;
    _speedKmh = 0.0;
    _previousPosition = null;
    _previousTimestamp = null;
    _stationaryTicks = 0;
    _accumulatedDistanceKm = 0.0;
  }
}
