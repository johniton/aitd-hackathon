# Sensor Tracking Module — `feature/sensor-tracker`

This branch adds fully-automated, background CO₂ tracking using three OS-level sensor pipelines. No manual input required from the user. All raw data stays on-device; only derived `kg CO₂e` figures are transmitted to the backend.

---

## Branch commits on top of `main`

| Hash | Message |
|---|---|
| `034b106` | fix: resolve all flutter analyze errors and warnings |
| `3a9d48f` | feat: add live SensorTrackerScreen with full nav integration |
| `eb8959e` | feat: add sensors module with transport, financial, digital pipelines |

---

## Files added / changed

```
frontend/lib/
├── sensors/                                  ← NEW — entire module
│   ├── sensors.dart                          barrel export
│   ├── transport/
│   │   └── motion_activity_service.dart      Pipeline 1
│   ├── financial/
│   │   └── transaction_sensor_service.dart   Pipeline 2
│   ├── digital/
│   │   └── device_footprint_service.dart     Pipeline 3
│   └── privacy/
│       └── privacy_config.dart               Privacy boundary policy
├── screens/personal/
│   ├── sensor_tracker_screen.dart            ← NEW — full UI screen
│   └── personal_shell.dart                   ← CHANGED — 6th nav tab added
```

---

## Pipeline 1 — Transport (Motion-Based)

**File:** `sensors/transport/motion_activity_service.dart`

**How it works:**
- On iOS, wraps `CMMotionActivityManager.startActivityUpdates` (Core Motion).
- On Android, wraps the `ActivityRecognitionClient` PendingIntent delivered via a BroadcastReceiver.
- Detects mode transitions: `stationary → automotive → cycling → walking`.
- When the mode changes, it closes the previous trip segment, calculates distance from coarse cell-tower / geofence location (no continuous GPS drain), and applies a per-mode CO₂ factor.

**Emission factors (Climatiq 2026):**

| Mode | kg CO₂e / km |
|---|---|
| Automotive (avg petrol) | 0.171 |
| Cycling | 0.0 |
| Walking | 0.0 |

**Key design decisions:**
- Only spins up high-accuracy GPS on a high-velocity accelerometer "Start" event; otherwise uses coarse cell-tower triangulation.
- Minimum confidence threshold (default 75%) filters out low-confidence OS readings.
- Minimum distance threshold (default 0.1 km) prevents API spam on micro-trips.
- Simulation shim (`_startSimulatedPlatformFeed`) fires every 30 s for local development — replace with real `MethodChannel` / `EventChannel` in production.

**Output type:** `TransportCarbonEstimate { kgCo2e, distanceKm, mode, calculatedAt }`

---

## Pipeline 2 — Financial (Transaction-Based)

**File:** `sensors/financial/transaction_sensor_service.dart`

**How it works:**
- Your backend receives a Plaid or Mastercard Carbon Calculator webhook on every card swipe.
- The backend forwards a silent push notification (APNs / FCM) containing `PlaidTransaction` JSON.
- `TransactionSensorService.ingestWebhookPayload()` maps the 4-digit ISO 18245 **MCC** to a spend-based CO₂ factor (kg CO₂e per USD) and fires `onCarbonLogged`.

**MCC coverage (partial list):**

| MCC | Merchant type | Category | kg CO₂e / USD |
|---|---|---|---|
| 5541 | Gas station | Fuel | 2.32 |
| 4511 | Airlines | Air travel | 1.07 |
| 5812 | Restaurant | Food | 0.43 |
| 5411 | Grocery store | Grocery | 0.29 |
| 4900 | Utilities | Utilities | 0.52 |
| 5999 | Online retail | E-commerce | 0.37 |

Full MCC table is in `_mccToCategory` and `_categoryFactors` — add codes as needed.

**Output type:** `TransactionCarbonLog { transaction, category, categoryLabel, kgCo2e, loggedAt }`

---

## Pipeline 3 — Digital / Device Footprint

**File:** `sensors/digital/device_footprint_service.dart`

**How it works:**
- Scheduled every few hours by `WorkManager` (Android) or `BGTaskScheduler` (iOS).
- Reads battery charge delta from `BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER` (Android) or `UIDevice.current.batteryLevel` diff (iOS).
- Reads per-interface byte counters from `NetworkStatsManager.querySummaryForDevice` (Android) or `NWPathMonitor` / `NetworkExtension` (iOS).
- Multiplies energy by the **Electricity Maps** real-time grid intensity at the device's coarse GPS location.

**Energy intensity factors (Cloud Carbon Footprint methodology, 2026):**

| Interface | kWh per GB |
|---|---|
| Wi-Fi | 0.06 |
| 4G LTE | 0.11 |
| 5G | 0.08 |

**Formula:**
```
battery_kWh  = batteryDelta × batteryCapacityWh / 1000
network_kWh  = Σ (GB_per_interface × kWh_per_GB)
total_kWh    = battery_kWh + network_kWh
kg_CO₂e      = total_kWh × (gridIntensity_gCO₂/kWh / 1000)
```

**Output type:** `DeviceFootprintResult { batteryEnergyKwh, networkEnergyKwh, totalEnergyKwh, kgCo2e, calculatedAt }`

---

## Privacy Architecture

**File:** `sensors/privacy/privacy_config.dart`

**Answer to "local or cloud?"** — **Local-first. Always.**

| Pipeline | Raw data (on-device only) | What goes to cloud |
|---|---|---|
| Transport | Accelerometer, GPS coords, activity state buffer | Mode (enum), distance_km (1dp), kg_co2e, date (day only) |
| Financial | Transaction amount, merchant name, MCC | MCC category (enum), kg_co2e, date (day only) |
| Digital | Battery %, byte counters | Total kg_co2e, kWh split, window_hours |

Raw GPS coordinates, transaction amounts, merchant names, and per-app network stats are **never transmitted**.

`isCloudTransmissionPermitted(pipelineName, fieldName)` is a runtime guard callable before any upload — returns `true` only if the field is explicitly listed in the policy table.

---

## UI — SensorTrackerScreen

**File:** `screens/personal/sensor_tracker_screen.dart`

Reached via the **Sensors** tab (6th item, `Icons.sensors`) in the bottom nav. The nav border highlights in emerald when this tab is active.

### What's on screen

| Component | Description |
|---|---|
| Pulsing `LIVE` dot | Green dot in header animates continuously to show data is flowing |
| Total CO₂ ring | Animated arc ring, fills against an 8 kg/day budget; turns red above 80% |
| Pipeline bars | Transport / Financial / Digital progress bars with live `kg CO₂e` values |
| Privacy Shield banner | Toggle switch; shows count of raw events blocked; states exactly what leaves the device |
| 01 — Transport card | Mode icon (car / bike / walk), distance km, CO₂ total, emission factor label, live sparkline |
| 02 — Financial card | Last merchant name, MCC code, category, cumulative CO₂, live sparkline |
| 03 — Digital card | Network GB consumed, battery Wh used, CO₂ total, live sparkline |
| Grid intensity card | Live gCO₂/kWh figure with CLEAN / MODERATE / DIRTY badge, colour-coded |
| Source badges | Each card has a small badge labelling the exact OS API feeding it |

### Update cadence (demo simulation)

| Pipeline | Interval |
|---|---|
| Transport | Every 6 s |
| Financial | Every 9 s (simulated Plaid webhook) |
| Digital | Every 8 s |
| Grid intensity | Drifts every 15 s |

In production: transport fires on OS activity state changes, financial fires on card-swipe push notifications, digital fires on WorkManager / BGTask schedule.

---

## How to use in production

1. **Transport** — replace `_startSimulatedPlatformFeed()` with a real `MethodChannel` / `EventChannel` receiving `CMMotionActivityManager` or `ActivityRecognitionClient` events.
2. **Financial** — your backend webhook handler calls `ingestWebhookPayload()` via a push notification payload parsed in `AppDelegate` / `FirebaseMessagingService`.
3. **Digital** — call `deviceService.calculate(snap)` from your `BGTaskScheduler` (iOS) or `WorkManager` (Android) periodic task, feeding real battery and network byte counters.
4. **Grid intensity** — replace the simulated drift with a single `GET /v1/carbon-intensity/latest` call to [Electricity Maps API](https://api.electricitymap.org) using coarse device GPS.

---

## Analyzer status

```
flutter analyze lib/sensors/ lib/screens/personal/sensor_tracker_screen.dart lib/screens/personal/personal_shell.dart
No issues found.
```
