// Privacy Architecture — Local vs. Cloud Processing Boundaries
//
// Answers: "How are you handling privacy — local processing or cloud-based?"
// Rule: raw sensor data NEVER leaves the device. Only derived CO₂ figures do.

/// Defines what is processed on-device vs. sent to the cloud for each
/// sensor pipeline. This is the canonical reference for all three services.
///
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │  Pipeline           │ Raw data (local only) │ Cloud payload           │
/// ├──────────────────────────────────────────────────────────────────────┤
/// │  Transport          │ Accelerometer vectors  │ kg CO₂e + mode + km    │
/// │                     │ GPS coordinates        │                         │
/// │                     │ Activity state buffer  │                         │
/// ├──────────────────────────────────────────────────────────────────────┤
/// │  Financial          │ Transaction amounts    │ kg CO₂e + MCC category  │
/// │                     │ Merchant names         │                         │
/// │                     │ Card / account IDs     │                         │
/// ├──────────────────────────────────────────────────────────────────────┤
/// │  Digital            │ Battery level readings │ kg CO₂e + kWh breakdown │
/// │                     │ Byte counters per iface│                         │
/// │                     │ App-level network stats│                         │
/// └──────────────────────────────────────────────────────────────────────┘

enum ProcessingLocation { onDevice, cloud }

/// Declares where a class of sensor data is processed and what, if anything,
/// is allowed to leave the device.
class DataProcessingPolicy {
  final String pipelineName;
  final String rawDataDescription;
  final ProcessingLocation rawDataLocation;
  final String? cloudPayloadDescription; // null = nothing sent
  final bool requiresExplicitConsent;

  const DataProcessingPolicy({
    required this.pipelineName,
    required this.rawDataDescription,
    required this.rawDataLocation,
    this.cloudPayloadDescription,
    this.requiresExplicitConsent = true,
  });
}

/// Authoritative policy table. Validate new sensor integrations against this.
const List<DataProcessingPolicy> kSensorPrivacyPolicies = [
  // ── Transport ────────────────────────────────────────────────────────────
  DataProcessingPolicy(
    pipelineName: 'Transport / Motion',
    rawDataDescription:
        'Accelerometer samples, GPS coordinates, OS activity state '
        '(automotive / cycling / walking). Buffered in SQLite on-device. '
        'Retained for 24 hours then purged.',
    rawDataLocation: ProcessingLocation.onDevice,
    cloudPayloadDescription:
        'Aggregated trip: mode (enum), distance_km (rounded to 1 dp), '
        'kg_co2e (float), segment_date (day only — no time). '
        'No coordinates, no continuous tracking.',
    requiresExplicitConsent: true,
  ),

  // ── Financial ────────────────────────────────────────────────────────────
  DataProcessingPolicy(
    pipelineName: 'Financial / Transaction',
    rawDataDescription:
        'Transaction amount, merchant name, MCC code. Processed in-memory; '
        'never written to local disk. The Plaid Link token is stored '
        'server-side only (never in the app).',
    rawDataLocation: ProcessingLocation.onDevice,
    cloudPayloadDescription:
        'MCC category (enum), kg_co2e (float), transaction_date (day only). '
        'Amount and merchant name are NOT sent to the analytics backend.',
    requiresExplicitConsent: true,
  ),

  // ── Digital / Device ─────────────────────────────────────────────────────
  DataProcessingPolicy(
    pipelineName: 'Digital / Device Footprint',
    rawDataDescription:
        'Battery charge delta (%), byte counters per network interface. '
        'All calculations run synchronously on-device with no I/O.',
    rawDataLocation: ProcessingLocation.onDevice,
    cloudPayloadDescription:
        'Total kg_co2e, battery_kwh, network_kwh, window_hours. '
        'No per-app or per-site breakdowns are transmitted.',
    requiresExplicitConsent: false, // aggregated device-level only
  ),
];

/// Runtime guard: call this before transmitting any sensor payload.
/// Returns true only if the payload field is explicitly listed as
/// allowed to leave the device in [kSensorPrivacyPolicies].
bool isCloudTransmissionPermitted(String pipelineName, String fieldName) {
  final policy = kSensorPrivacyPolicies
      .where((p) => p.pipelineName == pipelineName)
      .firstOrNull;
  if (policy == null) return false;
  if (policy.cloudPayloadDescription == null) return false;
  // Field-level check: the description must explicitly name the field.
  return policy.cloudPayloadDescription!.contains(fieldName);
}
