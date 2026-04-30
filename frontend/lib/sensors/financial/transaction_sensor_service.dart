import 'dart:async';
import 'dart:math';

// Financial Automation — Transaction-Based (Scope 3, India-specific)
// Receives UPI / card transaction payloads and automatically maps
// Merchant Category Codes (MCCs) to CO₂ factors calibrated for India.
//
// Currency: INR (₹). Factors sourced from:
//   - MoEFCC / CEEW India emission intensity reports (2024)
//   - Ministry of Railways carbon intensity (IR: ~12 gCO₂/pkm, mostly electric)
//   - IPCC AR6 spend-based factors scaled to INR at ₹83/USD parity.

/// A raw transaction delivered by a UPI / card webhook to your backend,
/// then forwarded to this service via a silent push notification.
class PlaidTransaction {
  final String transactionId;
  final int merchantCategoryCode; // 4-digit ISO 18245 MCC
  final String merchantName;

  /// Transaction amount in Indian Rupees (₹).
  final double amountInr;

  final DateTime authorizedAt;

  const PlaidTransaction({
    required this.transactionId,
    required this.merchantCategoryCode,
    required this.merchantName,
    required this.amountInr,
    required this.authorizedAt,
  });
}

/// Carbon intensity of a spend category.
class SpendCarbonFactor {
  final String label;

  /// kg CO₂e per ₹ spent (spend-based method, India-calibrated factors).
  final double kgCo2ePerInr;
  final MccCategory category;

  const SpendCarbonFactor({
    required this.label,
    required this.kgCo2ePerInr,
    required this.category,
  });
}

/// Broad MCC groupings relevant to India.
enum MccCategory {
  petrolPump, // IOCL / BPCL / HPCL / Reliance pumps
  lpgCng, // Indane LPG, HP Gas, IGL CNG
  twoWheelerFuel, // Petrol for bikes / scooters
  cabRideHail, // Ola, Uber, Rapido Cab
  autoRickshaw, // Ola Auto, Rapido Auto, Namma Yatri (CNG)
  domesticFlight, // IndiGo, Air India, SpiceJet, GoFirst
  indianRailways, // IRCTC / IR ticket purchase
  metro, // Delhi Metro, Mumbai Metro, Namma Metro, etc.
  cityBus, // BEST, DTC, KSRTC, BMTC, TSRTC city buses
  restaurant, // Dine-in restaurants, dhabas
  foodDelivery, // Swiggy, Zomato (includes delivery vehicle)
  grocery, // BigBasket, Blinkit, D-Mart, More, local kirana
  ecommerce, // Flipkart, Amazon India, Meesho, Myntra
  utilities, // MSEDCL, BESCOM, Tata Power, CESC electricity bills
  other,
}

/// ISO 18245 MCC → Indian carbon category mapping.
/// Focused on merchants dominant in the Indian market.
const Map<int, MccCategory> _mccToCategory = {
  // ── Petrol Pumps ──────────────────────────────────────────────────────────
  5541: MccCategory.petrolPump, // Service Stations (IOCL, BPCL, HPCL)
  5542: MccCategory.petrolPump, // Automated Fuel Dispensers
  5172: MccCategory.lpgCng, // Petroleum products (LPG / CNG refills)
  // ── Two-Wheeler Fuel ──────────────────────────────────────────────────────
  // (Often charged at 5541 too; separate if your POS differentiates)
  5571: MccCategory.twoWheelerFuel, // Motorcycle Shops / fuel tagged to 2W
  // ── Cab / Ride-Hail ───────────────────────────────────────────────────────
  4121: MccCategory.cabRideHail, // Taxicabs / Limousines (Ola, Uber)
  4722: MccCategory.cabRideHail, // Travel Agencies (sometimes Ola biz)
  // ── Auto Rickshaw ─────────────────────────────────────────────────────────
  // Namma Yatri, Ola Auto, Rapido Auto show up under 4121 too;
  // some aggregators use 7299 for misc transport services.
  7299: MccCategory.autoRickshaw, // Misc Services — map to auto category
  // ── Domestic Airlines ─────────────────────────────────────────────────────
  4511: MccCategory.domesticFlight, // Airlines, Air Carriers
  3000: MccCategory
      .domesticFlight, // United (ignore; catches IndiGo via 3000–3299 range)
  3066: MccCategory.domesticFlight, // IndiGo
  3096: MccCategory.domesticFlight, // Air India
  // ── Indian Railways ───────────────────────────────────────────────────────
  4112: MccCategory.indianRailways, // Passenger Railways (IRCTC)
  4111: MccCategory.metro, // Local & Suburban Commuter (Metro tagged here)
  4131: MccCategory.cityBus, // Bus Lines (BEST, DTC, KSRTC, BMTC)
  // ── Food & Restaurants ────────────────────────────────────────────────────
  5812: MccCategory.restaurant, // Eating Places, Restaurants, Dhabas
  5811: MccCategory.restaurant, // Caterers
  5814:
      MccCategory.foodDelivery, // Fast Food (often used by Swiggy / Zomato POS)
  5499: MccCategory.foodDelivery, // Miscellaneous Food Stores (Swiggy, Zomato)
  // ── Grocery ───────────────────────────────────────────────────────────────
  5411: MccCategory.grocery, // Grocery Stores (D-Mart, More, Reliance Fresh)
  5422: MccCategory.grocery, // Meat Provisioners
  5441: MccCategory.grocery, // Confectionery / mithai shops
  5912: MccCategory.grocery, // Drug Stores (sometimes BigBasket pharma)
  // ── E-commerce ────────────────────────────────────────────────────────────
  5999: MccCategory.ecommerce, // Misc Retail (Flipkart, Meesho, Amazon)
  5734: MccCategory.ecommerce, // Computer / Electronics Stores (Croma, Vi)
  5045: MccCategory.ecommerce, // Computers & Peripherals
  // ── Utilities ─────────────────────────────────────────────────────────────
  4900: MccCategory.utilities, // Utilities — Electricity, Gas, Water
  4911:
      MccCategory.utilities, // Electric Companies (MSEDCL, BESCOM, TATA Power)
  4924: MccCategory.utilities, // Natural Gas
};

/// kg CO₂e per ₹ spent, India-calibrated.
///
/// Methodology:
///   - Petrol pump: ₹100 buys ~1 L petrol → ~2.31 kg CO₂ → 0.0231 kg/₹
///   - CNG/LPG: ₹100 buys ~2.5 kg CNG → ~6.7 kg CO₂ → 0.0067 kg/₹  (lower per km, clean)
///   - 2W petrol: ~40 km/L, 0.05 kg CO₂/km → 0.002 kg CO₂/₹ (cheap fuel, small engine)
///   - Ola/Uber cab: petrol sedan, ~10 km/L, shorter trips, ~0.008 kg/₹
///   - CNG auto: ~25 km/kg CNG, 0.05 kg CO₂/km, ₹15/km → 0.003 kg/₹
///   - Domestic flight: IndiGo ~0.09 kg CO₂/pkm, avg ₹7/km fare → 0.013 kg/₹
///   - Indian Railways: 12 gCO₂/pkm, ₹1.2/km → 0.010 kg/₹ (but IR is cheap & green)
///   - Delhi/Blr Metro: ~35 gCO₂/pkm (India grid), ₹2/km → 0.018 kg/₹
///   - City Bus: ~35 gCO₂/pkm, ₹1/km → 0.035 kg/₹ (cheap ticket, older bus fleet)
///   - Restaurant: India food system ~0.004 kg CO₂e/₹ spend
///   - Food delivery: adds ~20% for last-mile vehicle → 0.005 kg/₹
///   - Grocery: ~0.003 kg/₹ (India farm-to-store, lower cold chain)
///   - E-commerce: ~0.004 kg/₹ (warehousing + last-mile delivery)
///   - Utilities (electricity): India grid ~700 gCO₂/kWh; ₹8/kWh → 0.088 kg/₹
const Map<MccCategory, SpendCarbonFactor> _categoryFactors = {
  MccCategory.petrolPump: SpendCarbonFactor(
    label: 'Petrol Pump',
    kgCo2ePerInr: 0.0231, // ~2.31 kg CO₂ per litre, ₹100/L
    category: MccCategory.petrolPump,
  ),
  MccCategory.lpgCng: SpendCarbonFactor(
    label: 'LPG / CNG',
    kgCo2ePerInr: 0.0067, // CNG cleaner than petrol; LPG for cooking is low-use
    category: MccCategory.lpgCng,
  ),
  MccCategory.twoWheelerFuel: SpendCarbonFactor(
    label: 'Two-Wheeler Fuel',
    kgCo2ePerInr:
        0.0200, // 2W ~100cc, 60 km/L, lower per km but accounted per ₹
    category: MccCategory.twoWheelerFuel,
  ),
  MccCategory.cabRideHail: SpendCarbonFactor(
    label: 'Ola / Uber Cab',
    kgCo2ePerInr: 0.0080, // petrol sedan, ₹12–15/km, ~0.12 kg CO₂/km
    category: MccCategory.cabRideHail,
  ),
  MccCategory.autoRickshaw: SpendCarbonFactor(
    label: 'Auto Rickshaw (CNG)',
    kgCo2ePerInr: 0.0030, // CNG 3-wheeler, low emissions, cheap fares
    category: MccCategory.autoRickshaw,
  ),
  MccCategory.domesticFlight: SpendCarbonFactor(
    label: 'Domestic Flight',
    kgCo2ePerInr: 0.0130, // IndiGo/Air India: ~90 gCO₂/pkm, avg ₹7/km
    category: MccCategory.domesticFlight,
  ),
  MccCategory.indianRailways: SpendCarbonFactor(
    label: 'Indian Railways (IRCTC)',
    kgCo2ePerInr: 0.0100, // 12 gCO₂/pkm (mostly electric), ₹1.2/pkm
    category: MccCategory.indianRailways,
  ),
  MccCategory.metro: SpendCarbonFactor(
    label: 'Metro Rail',
    kgCo2ePerInr: 0.0180, // ~35 gCO₂/pkm (India grid), ₹2/km fare
    category: MccCategory.metro,
  ),
  MccCategory.cityBus: SpendCarbonFactor(
    label: 'City Bus (BEST / DTC / KSRTC)',
    kgCo2ePerInr:
        0.0350, // older diesel fleet, very cheap tickets → higher per ₹
    category: MccCategory.cityBus,
  ),
  MccCategory.restaurant: SpendCarbonFactor(
    label: 'Restaurant / Dhaba',
    kgCo2ePerInr: 0.0040, // Indian diet lower carbon than Western; LPG cooking
    category: MccCategory.restaurant,
  ),
  MccCategory.foodDelivery: SpendCarbonFactor(
    label: 'Swiggy / Zomato',
    kgCo2ePerInr: 0.0050, // restaurant + last-mile 2W delivery
    category: MccCategory.foodDelivery,
  ),
  MccCategory.grocery: SpendCarbonFactor(
    label: 'Grocery / Kirana',
    kgCo2ePerInr:
        0.0030, // local supply chains, lower cold chain loss than West
    category: MccCategory.grocery,
  ),
  MccCategory.ecommerce: SpendCarbonFactor(
    label: 'Flipkart / Amazon India',
    kgCo2ePerInr: 0.0040, // warehousing + last-mile delivery van/bike
    category: MccCategory.ecommerce,
  ),
  MccCategory.utilities: SpendCarbonFactor(
    label: 'Electricity Bill',
    kgCo2ePerInr: 0.0875, // India grid: ~700 gCO₂/kWh, ₹8/kWh → 0.088 kg/₹
    category: MccCategory.utilities,
  ),
  MccCategory.other: SpendCarbonFactor(
    label: 'Other',
    kgCo2ePerInr: 0.0030, // conservative catch-all
    category: MccCategory.other,
  ),
};

/// Automatic output produced for every transaction received.
class TransactionCarbonLog {
  final PlaidTransaction transaction;
  final MccCategory category;
  final String categoryLabel;

  /// kg CO₂e attributed to this purchase.
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

/// Receives UPI / card webhook payloads (forwarded by your backend on every
/// transaction) and converts them to [TransactionCarbonLog] entries
/// with zero user interaction.
///
/// Integration:
///   1. Your server receives the webhook → decodes MCC → pushes a silent
///      APNs/FCM notification containing [PlaidTransaction] JSON (in ₹).
///   2. Your app's background push handler calls [ingestWebhookPayload].
///   3. [onCarbonLogged] fires; persist the result in local SQLite / Drift.
class TransactionSensorService {
  TransactionSensorService({
    required this.onCarbonLogged,
    this.isDemoMode = false,
  });

  /// Called synchronously for every transaction with a non-zero CO₂ factor.
  final void Function(TransactionCarbonLog log) onCarbonLogged;
  final bool isDemoMode;
  Timer? _simulationTimer;
  final Random _rng = Random();

  /// Process a single UPI / card transaction.
  TransactionCarbonLog ingestWebhookPayload(PlaidTransaction tx) {
    final category =
        _mccToCategory[tx.merchantCategoryCode] ?? MccCategory.other;
    final factor = _categoryFactors[category]!;
    final kgCo2e = factor.kgCo2ePerInr * tx.amountInr;

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

  /// Batch-process a list of historic transactions (e.g. on first UPI link).
  List<TransactionCarbonLog> ingestBatch(List<PlaidTransaction> transactions) =>
      transactions.map(ingestWebhookPayload).toList();

  /// Look up what category and factor an MCC maps to without logging it.
  SpendCarbonFactor factorForMcc(int mcc) {
    final category = _mccToCategory[mcc] ?? MccCategory.other;
    return _categoryFactors[category]!;
  }

  void startSimulation({int intervalSeconds = 10}) {
    if (!isDemoMode) return;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      final tx = _buildDemoTransaction();
      ingestWebhookPayload(tx);
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  PlaidTransaction _buildDemoTransaction() {
    const templates = <(int, String, double, double)>[
      (5499, 'Zomato', 220, 640),
      (5541, 'Shell Petrol Pump', 900, 2400),
      (4121, 'Ola Cab', 120, 480),
      (5411, 'BigBasket', 350, 1600),
      (4112, 'IRCTC', 220, 1200),
      (4900, 'Tata Power', 600, 2200),
      (5999, 'Flipkart', 500, 3000),
      (5812, 'Cafe Coffee Day', 150, 700),
    ];
    final t = templates[_rng.nextInt(templates.length)];
    final amount = t.$3 + _rng.nextDouble() * (t.$4 - t.$3);
    return PlaidTransaction(
      transactionId: 'demo_${DateTime.now().microsecondsSinceEpoch}',
      merchantCategoryCode: t.$1,
      merchantName: t.$2,
      amountInr: double.parse(amount.toStringAsFixed(2)),
      authorizedAt: DateTime.now(),
    );
  }
}
