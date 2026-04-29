// Financial Automation — Transaction-Based (Scope 3)
// Receives Plaid / Mastercard Carbon Calculator webhook payloads and
// automatically maps Merchant Category Codes (MCCs) to CO₂ factors.
// No user input required; your backend calls [ingestWebhookPayload] on
// every card-swipe notification it receives.

/// A raw transaction as delivered by the Plaid / Mastercard webhook to
/// your backend, then forwarded to this service via a push notification
/// or silent background fetch.
class PlaidTransaction {
  final String transactionId;
  final int merchantCategoryCode; // 4-digit ISO 18245 MCC
  final String merchantName;
  final double amountUsd;
  final DateTime authorizedAt;

  const PlaidTransaction({
    required this.transactionId,
    required this.merchantCategoryCode,
    required this.merchantName,
    required this.amountUsd,
    required this.authorizedAt,
  });
}

/// Carbon intensity of a spend category.
class SpendCarbonFactor {
  final String label; // human-readable category label
  /// kg CO₂e per USD spent (spend-based method, Climatiq 2026 factors)
  final double kgCo2ePerUsd;
  final MccCategory category;

  const SpendCarbonFactor({
    required this.label,
    required this.kgCo2ePerUsd,
    required this.category,
  });
}

/// Broad MCC groupings used for carbon factor lookup and dashboard bucketing.
enum MccCategory {
  fuel,        // gas stations, diesel, LPG
  automotive,  // auto repair, car rental, ride-hail
  airTravel,   // airlines, airports
  transit,     // rail, bus, ferry, taxi
  food,        // restaurants, fast food
  grocery,     // supermarkets
  ecommerce,   // online retail / general merchandise
  utilities,   // electricity, gas, water
  other,
}

/// ISO 18245 MCC → carbon category mapping.
/// Only the highest-impact codes are enumerated; all others fall to [MccCategory.other].
/// Source: EPA + Climatiq MCC emission factor tables (2026).
const Map<int, MccCategory> _mccToCategory = {
  // ── Fuel ──────────────────────────────────────────────────────────
  5541: MccCategory.fuel,   // Service Stations (with or without ancillary services)
  5542: MccCategory.fuel,   // Automated Fuel Dispensers
  5172: MccCategory.fuel,   // Petroleum and Petroleum Products
  // ── Automotive ────────────────────────────────────────────────────
  7011: MccCategory.automotive, // Lodging – Hotels, Motels (sometimes misused; keep here)
  7512: MccCategory.automotive, // Car Rental Agencies
  4111: MccCategory.transit,    // Local & Suburban Commuter Rail
  4121: MccCategory.automotive, // Taxicabs / Limousines
  // ── Air Travel ────────────────────────────────────────────────────
  3000: MccCategory.airTravel,  // United Airlines
  3001: MccCategory.airTravel,  // American Airlines
  4511: MccCategory.airTravel,  // Airlines, Air Carriers
  // ── Transit ───────────────────────────────────────────────────────
  4112: MccCategory.transit, // Passenger Railways
  4131: MccCategory.transit, // Bus Lines
  4789: MccCategory.transit, // Transportation Services (NEC)
  // ── Food ──────────────────────────────────────────────────────────
  5812: MccCategory.food,    // Eating Places, Restaurants
  5814: MccCategory.food,    // Fast Food Restaurants
  5811: MccCategory.food,    // Caterers
  // ── Grocery ───────────────────────────────────────────────────────
  5411: MccCategory.grocery, // Grocery Stores, Supermarkets
  5422: MccCategory.grocery, // Freezer and Locker Meat Provisioners
  5441: MccCategory.grocery, // Candy, Nut, and Confectionery Shops
  // ── E-commerce / Retail ───────────────────────────────────────────
  5999: MccCategory.ecommerce, // Miscellaneous and Specialty Retail Stores
  5734: MccCategory.ecommerce, // Computer Software Stores
  // ── Utilities ─────────────────────────────────────────────────────
  4900: MccCategory.utilities, // Utilities – Electric, Gas, Water
  4911: MccCategory.utilities, // Electric Companies, Inc.
};

/// kg CO₂e per USD spent by category (spend-based method).
/// Derived from Climatiq Autopilot / EPA EEIO 2026 factors.
const Map<MccCategory, SpendCarbonFactor> _categoryFactors = {
  MccCategory.fuel: SpendCarbonFactor(
    label: 'Fuel Purchase',
    kgCo2ePerUsd: 2.32,
    category: MccCategory.fuel,
  ),
  MccCategory.automotive: SpendCarbonFactor(
    label: 'Automotive',
    kgCo2ePerUsd: 0.58,
    category: MccCategory.automotive,
  ),
  MccCategory.airTravel: SpendCarbonFactor(
    label: 'Air Travel',
    kgCo2ePerUsd: 1.07,
    category: MccCategory.airTravel,
  ),
  MccCategory.transit: SpendCarbonFactor(
    label: 'Public Transit',
    kgCo2ePerUsd: 0.18,
    category: MccCategory.transit,
  ),
  MccCategory.food: SpendCarbonFactor(
    label: 'Restaurant / Food',
    kgCo2ePerUsd: 0.43,
    category: MccCategory.food,
  ),
  MccCategory.grocery: SpendCarbonFactor(
    label: 'Grocery',
    kgCo2ePerUsd: 0.29,
    category: MccCategory.grocery,
  ),
  MccCategory.ecommerce: SpendCarbonFactor(
    label: 'Online Shopping',
    kgCo2ePerUsd: 0.37,
    category: MccCategory.ecommerce,
  ),
  MccCategory.utilities: SpendCarbonFactor(
    label: 'Utilities',
    kgCo2ePerUsd: 0.52,
    category: MccCategory.utilities,
  ),
  MccCategory.other: SpendCarbonFactor(
    label: 'Other',
    kgCo2ePerUsd: 0.24,
    category: MccCategory.other,
  ),
};

/// Automatic output produced for every card swipe received.
class TransactionCarbonLog {
  final PlaidTransaction transaction;
  final MccCategory category;
  final String categoryLabel;

  /// kg CO₂e attributed to this purchase
  final double kgCo2e;
  final DateTime loggedAt;

  const TransactionCarbonLog({
    required this.transaction,
    required this.category,
    required this.categoryLabel,
    required this.kgCo2e,
    required this.loggedAt,
  });
}

/// Receives Plaid webhook payloads (forwarded by your backend after every
/// card-swipe event) and converts them to [TransactionCarbonLog] entries
/// with zero user interaction.
///
/// Integration:
///   1. Your server receives the Plaid webhook → decodes MCC → pushes a
///      silent APNs/FCM notification containing [PlaidTransaction] JSON.
///   2. Your app's background push handler calls [ingestWebhookPayload].
///   3. [onCarbonLogged] fires; persist the result in local SQLite/Room.
class TransactionSensorService {
  TransactionSensorService({required this.onCarbonLogged});

  /// Called synchronously for every transaction that has a non-zero CO₂ factor.
  final void Function(TransactionCarbonLog log) onCarbonLogged;

  /// Process a single Plaid/Mastercard webhook transaction.
  TransactionCarbonLog ingestWebhookPayload(PlaidTransaction tx) {
    final category = _mccToCategory[tx.merchantCategoryCode] ?? MccCategory.other;
    final factor = _categoryFactors[category]!;
    final kgCo2e = factor.kgCo2ePerUsd * tx.amountUsd;

    final log = TransactionCarbonLog(
      transaction: tx,
      category: category,
      categoryLabel: factor.label,
      kgCo2e: kgCo2e,
      loggedAt: DateTime.now(),
    );
    onCarbonLogged(log);
    return log;
  }

  /// Batch-process a list of historic transactions (e.g. on first Plaid link).
  List<TransactionCarbonLog> ingestBatch(List<PlaidTransaction> transactions) =>
      transactions.map(ingestWebhookPayload).toList();

  /// Look up what category and factor an MCC maps to without logging it.
  SpendCarbonFactor factorForMcc(int mcc) {
    final category = _mccToCategory[mcc] ?? MccCategory.other;
    return _categoryFactors[category]!;
  }
}
