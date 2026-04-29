import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:battery_plus/battery_plus.dart';

class RealSensorsService {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _stepSub;
  StreamSubscription? _pedestrianSub;
  StreamSubscription? _batterySub;

  final void Function(UserAccelerometerEvent) onAccelEvent;
  final void Function(GyroscopeEvent) onGyroEvent;
  final void Function(StepCount) onStepCount;
  final void Function(PedestrianStatus) onPedestrianStatus;
  final void Function(BatteryState) onBatteryState;
  final void Function(int) onBatteryLevel;

  RealSensorsService({
    required this.onAccelEvent,
    required this.onGyroEvent,
    required this.onStepCount,
    required this.onPedestrianStatus,
    required this.onBatteryState,
    required this.onBatteryLevel,
  });

  Future<void> start() async {
    _accelSub = userAccelerometerEventStream().listen(onAccelEvent);
    _gyroSub = gyroscopeEventStream().listen(onGyroEvent);
    
    try {
      _stepSub = Pedometer.stepCountStream.listen(onStepCount, onError: (e) => print("Step Error: $e"));
      _pedestrianSub = Pedometer.pedestrianStatusStream.listen(onPedestrianStatus, onError: (e) => print("Pedestrian Error: $e"));
    } catch(e) {
      print("Pedometer error: $e");
    }

    final battery = Battery();
    battery.batteryLevel.then(onBatteryLevel);
    _batterySub = battery.onBatteryStateChanged.listen((state) async {
      onBatteryState(state);
      final level = await battery.batteryLevel;
      onBatteryLevel(level);
    });
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _stepSub?.cancel();
    _pedestrianSub?.cancel();
    _batterySub?.cancel();
  }
}
