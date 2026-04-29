// Sensors module — barrel export
// Three fully-automated pipelines; import this single file in the app.

// 1. Transport: CMMotionActivityManager / Activity Recognition Client
export 'transport/motion_activity_service.dart';

// 2. Financial: Plaid / Mastercard MCC webhook bridge
export 'financial/transaction_sensor_service.dart';

// 3. Digital: BatteryManager + NetworkStatsManager → kWh → kg CO₂e
export 'digital/device_footprint_service.dart';
export 'digital/grid_intensity_service.dart';


// Privacy: local-vs-cloud boundary policy table
export 'privacy/privacy_config.dart';
