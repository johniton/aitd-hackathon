import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';
import '../models/business_model.dart';
import '../models/tourism_engine_models.dart';
import '../data/emission_factors.dart';

class TourismEngineController extends ChangeNotifier {
  static const Map<TransportMode, double> _transportFactors = {
    TransportMode.car: 0.12,
    TransportMode.bike: 0.08,
    TransportMode.bus: 0.05,
    TransportMode.walking: 0,
  };

  final BusinessSector sector;

  final List<TripLog> _trips = [];
  final List<double> _weeklyTotals = [21, 19, 18, 20, 17, 16, 18];
  final Random _random = Random();

  // ── Shared inputs ──
  TransportMode selectedMode = TransportMode.car;
  double selectedDistance = 25;
  double electricityKwh = 34;
  double lpgKg = 5;
  double organicWasteKg = 7;
  double oilWasteKg = 2;
  double simulationPercent = 40;

  // ── Sector-specific inputs ──
  // Cashew
  double roastingHours = 6;
  double shellWasteKg = 15;
  double cnslOilLitres = 3;
  String fuelType = 'firewood';

  // Farmer
  double landAcres = 2;
  double fertilizerKg = 10;
  double pesticideL = 2;
  double waterUsageL = 500;
  String cropType = 'paddy';
  String irrigationType = 'flood';

  // Bakery
  double ovenHours = 8;
  double flourKg = 25;
  double butterKg = 5;
  double breadWasteKg = 3;
  String ovenFuel = 'electric';

  // Other (Custom)
  String otherBusinessType = 'Retail';
  double otherWaterUsageL = 500;
  String otherWasteType = 'mixed';
  String otherEnergySource = 'grid';

  TripLog? _activeTrip;
  GeminiInsight? latestInsight;
  TourismPlanComparison? latestPlanComparison;
  SustainabilityPlan? latestSustainabilityPlan;
  bool isLoadingPlan = false;
  // ── Carbon Credit Analysis ──
  bool isLoadingCarbonCredit = false;
  Map<String, dynamic>? carbonCreditAnalysis;

  Timer? _debounceTimer;
  int _requestId = 0;

  TourismEngineController({this.sector = BusinessSector.tourism});

  List<TripLog> get trips => List.unmodifiable(_trips);
  List<double> get weeklyTotals => List.unmodifiable(_weeklyTotals);
  TripLog? get activeTrip => _activeTrip;

  double get tripEmissions => _trips.fold(
    0,
    (sum, t) => sum + (t.distanceKm * (_transportFactors[t.mode] ?? 0)),
  );
  double get energyEmissions =>
      electricityKwh * EmissionFactors.gridElectricityIndia;
  double get lpgEmissions => lpgKg * EmissionFactors.lpgCombustion;
  double get dailyTotal {
    switch (sector) {
      case BusinessSector.tourism:
        return tripEmissions + energyEmissions + lpgEmissions;
      case BusinessSector.cashew:
        return (roastingHours *
                (fuelType == 'firewood'
                    ? EmissionFactors.firewoodCombustion * 1.5
                    : EmissionFactors.dieselCombustion * 1.0)) +
            (electricityKwh * EmissionFactors.gridElectricityIndia) +
            (shellWasteKg * EmissionFactors.landfillOrganicWaste);
      case BusinessSector.farmer:
        return (fertilizerKg *
                EmissionFactors.chemicalFertilizerN2O *
                298) + // GWP of N2O is 298
            (pesticideL * 2.1) +
            (waterUsageL * 0.001) +
            (electricityKwh * EmissionFactors.gridElectricityIndia) +
            (irrigationType == 'flood'
                ? EmissionFactors.floodIrrigationMethane * landAcres * 25
                : 0); // Methane GWP 25
      case BusinessSector.bakery:
        return (ovenHours *
                (ovenFuel == 'electric'
                    ? EmissionFactors.gridElectricityIndia * 4
                    : EmissionFactors.firewoodCombustion * 2.5)) +
            (flourKg * 0.04) +
            (butterKg * 0.12) +
            (breadWasteKg * EmissionFactors.landfillOrganicWaste);
      case BusinessSector.other:
        return (electricityKwh *
                (otherEnergySource == 'grid'
                    ? EmissionFactors.gridElectricityIndia
                    : 0.1)) +
            (otherWaterUsageL * 0.001) +
            (organicWasteKg * EmissionFactors.landfillOrganicWaste) +
            (oilWasteKg * 2.0);
    }
  }

  double get lastWeekAverage =>
      _weeklyTotals.take(_weeklyTotals.length - 1).fold(0.0, (a, b) => a + b) /
      6;
  double get weeklyDeltaPercent =>
      ((dailyTotal - lastWeekAverage) / lastWeekAverage) * 100;
  double get simulatedCarbonSaved => dailyTotal * (simulationPercent / 100);
  double get simulatedMoneySaved => simulatedCarbonSaved * 2;

  double _actionPlanBonus = 0.0;
  void updateActionPlanBonus(double rate) {
    if (rate == 1.0)
      _actionPlanBonus = 20.0;
    else if (rate >= 0.66)
      _actionPlanBonus = 10.0;
    else if (rate >= 0.33)
      _actionPlanBonus = 5.0;
    else
      _actionPlanBonus = 0.0;
    notifyListeners();
  }

  double get ecoScore =>
      ((100 - (dailyTotal * 1.2)).clamp(15, 98) + _actionPlanBonus)
          .clamp(15, 100)
          .toDouble();

  String get badge {
    if (ecoScore > 80) return 'Gold Pathfinder';
    if (ecoScore > 60) return 'Silver Steward';
    return 'Bronze Explorer';
  }

  double get peerAverage => 22.0;
  double get peerAdvantagePercent =>
      ((peerAverage - dailyTotal) / peerAverage * 100);

  // ── Input changed ──
  void onInputChanged({
    TransportMode? mode,
    double? distance,
    double? electricity,
    double? lpg,
    double? organic,
    double? oil,
    // Cashew
    double? roasting,
    double? shellWaste,
    double? cnsl,
    String? fuel,
    // Farmer
    double? land,
    double? fertilizer,
    double? pesticide,
    double? water,
    String? crop,
    String? irrigation,
    // Bakery
    double? oven,
    double? flour,
    double? butter,
    double? breadWaste,
    String? ovenFuelType,
    // Other
    String? otherBusiness,
    double? otherWater,
    String? otherWaste,
    String? otherEnergy,
  }) {
    bool changed = false;

    // Shared
    if (mode != null && mode != selectedMode) {
      selectedMode = mode;
      changed = true;
    }
    if (distance != null && distance != selectedDistance) {
      selectedDistance = distance;
      changed = true;
    }
    if (electricity != null && electricity != electricityKwh) {
      electricityKwh = electricity;
      changed = true;
    }
    if (lpg != null && lpg != lpgKg) {
      lpgKg = lpg;
      changed = true;
    }
    if (organic != null && organic != organicWasteKg) {
      organicWasteKg = organic;
      changed = true;
    }
    if (oil != null && oil != oilWasteKg) {
      oilWasteKg = oil;
      changed = true;
    }

    // Cashew
    if (roasting != null && roasting != roastingHours) {
      roastingHours = roasting;
      changed = true;
    }
    if (shellWaste != null && shellWaste != shellWasteKg) {
      shellWasteKg = shellWaste;
      changed = true;
    }
    if (cnsl != null && cnsl != cnslOilLitres) {
      cnslOilLitres = cnsl;
      changed = true;
    }
    if (fuel != null && fuel != fuelType) {
      fuelType = fuel;
      changed = true;
    }

    // Farmer
    if (land != null && land != landAcres) {
      landAcres = land;
      changed = true;
    }
    if (fertilizer != null && fertilizer != fertilizerKg) {
      fertilizerKg = fertilizer;
      changed = true;
    }
    if (pesticide != null && pesticide != pesticideL) {
      pesticideL = pesticide;
      changed = true;
    }
    if (water != null && water != waterUsageL) {
      waterUsageL = water;
      changed = true;
    }
    if (crop != null && crop != cropType) {
      cropType = crop;
      changed = true;
    }
    if (irrigation != null && irrigation != irrigationType) {
      irrigationType = irrigation;
      changed = true;
    }

    // Bakery
    if (oven != null && oven != ovenHours) {
      ovenHours = oven;
      changed = true;
    }
    if (flour != null && flour != flourKg) {
      flourKg = flour;
      changed = true;
    }
    if (butter != null && butter != butterKg) {
      butterKg = butter;
      changed = true;
    }
    if (breadWaste != null && breadWaste != breadWasteKg) {
      breadWasteKg = breadWaste;
      changed = true;
    }
    if (ovenFuelType != null && ovenFuelType != ovenFuel) {
      ovenFuel = ovenFuelType;
      changed = true;
    }

    // Other
    if (otherBusiness != null && otherBusiness != otherBusinessType) {
      otherBusinessType = otherBusiness;
      changed = true;
    }
    if (otherWater != null && otherWater != otherWaterUsageL) {
      otherWaterUsageL = otherWater;
      changed = true;
    }
    if (otherWaste != null && otherWaste != otherWasteType) {
      otherWasteType = otherWaste;
      changed = true;
    }
    if (otherEnergy != null && otherEnergy != otherEnergySource) {
      otherEnergySource = otherEnergy;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      _debouncedFetch();
    }
  }

  void _debouncedFetch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      fetchSustainabilityPlan();
    });
  }

  Future<void> startTrip({
    required TransportMode mode,
    required double mockDistanceKm,
  }) async {
    _activeTrip = TripLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      endedAt: null,
      distanceKm: mockDistanceKm,
      mode: mode,
    );
    notifyListeners();
  }

  Future<void> endTrip() async {
    if (_activeTrip == null) return;
    final ended = TripLog(
      id: _activeTrip!.id,
      startedAt: _activeTrip!.startedAt,
      endedAt: DateTime.now(),
      distanceKm: _activeTrip!.distanceKm,
      mode: _activeTrip!.mode,
    );
    _trips.insert(0, ended);
    _activeTrip = null;
    _weeklyTotals.removeAt(0);
    _weeklyTotals.add(dailyTotal);
    await fetchSustainabilityPlan();
    notifyListeners();
  }

  void updateSimulation(double value) {
    simulationPercent = value;
    notifyListeners();
  }

  List<SubsidyMatch> subsidyMatches() {
    final matches = <SubsidyMatch>[];
    if (latestSustainabilityPlan != null &&
        latestSustainabilityPlan!.subsidy.name.isNotEmpty) {
      matches.add(
        SubsidyMatch(
          title: latestSustainabilityPlan!.subsidy.name,
          amount: latestSustainabilityPlan!.subsidy.amount,
          description: latestSustainabilityPlan!.subsidy.reason,
          isEligible: true,
        ),
      );
    }
    return matches;
  }

  List<ExchangeMatch> exchangeMatches() {
    return [
      ExchangeMatch(
        title: 'Used cooking oil to biofuel buyers',
        description: 'Oil waste: ${oilWasteKg.toStringAsFixed(1)} kg/day',
        nearbyBusinesses: 2 + _random.nextInt(2),
      ),
      ExchangeMatch(
        title: 'Food waste to farms / biogas',
        description:
            'Organic waste: ${organicWasteKg.toStringAsFixed(1)} kg/day',
        nearbyBusinesses: 2 + _random.nextInt(2),
      ),
    ];
  }

  // ════════════════════════════════════════════════
  //  SECTOR-SPECIFIC PROMPTS
  // ════════════════════════════════════════════════

  String _buildPrompt() {
    final sectorPrompt = switch (sector) {
      BusinessSector.tourism => _tourismPrompt(),
      BusinessSector.cashew => _cashewPrompt(),
      BusinessSector.farmer => _farmerPrompt(),
      BusinessSector.bakery => _bakeryPrompt(),
      BusinessSector.other => _otherPrompt(),
    };
    return '''
$sectorPrompt

Global output quality rules:
- Avoid generic advice like "go green", "optimize resources", "improve sustainability".
- Every plan step must include: action + expected carbon effect + rough timeline.
- Use Indian rupees and realistic ranges.
- Mention one Goa-local implementation detail in at least 2 plan steps.
- Keep output practical for small and medium businesses, not only large enterprises.
''';
  }

  String _tourismPrompt() {
    final modeStr = selectedMode.name;
    return '''
You are a sustainability AI for Goa TOURISM businesses (beach shacks, hotels, tour operators).
Return STRICT JSON only. No text outside JSON.

Analyze this tourism operation:
- Guest transport: $modeStr, $selectedDistance km
- Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
- LPG cooking: ${lpgKg.toStringAsFixed(1)} kg/day
- Organic waste: ${organicWasteKg.toStringAsFixed(1)} kg/day
- Oil waste: ${oilWasteKg.toStringAsFixed(1)} kg/day
- Location: Goa

Emission factors: car=0.12 kg/km, bike=0.08, bus=0.05, walking=0

Return JSON:
{
  "insight": "2-3 sentence sustainability analysis specific to this Goa tourism business with EXACT numbers",
  "current": {"carbon": "X.X kg CO2", "cost": "Rs XXXX"},
  "optimized": {
    "plan": ["Step 1: specific action", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2", "cost": "Rs XXXX"
  },
  "savings": {"carbon_reduction": "XX%", "money_saved": "Rs XXX"},
  "subsidy": {"name": "Real Indian govt scheme", "amount": "Rs XX,XXX", "reason": "Why it fits"},
  "analysis": [
    "Equivalent to planting X coconut trees along Goa beaches",
    "Like removing X auto-rickshaws from Panaji roads for a day",
    "Saves enough energy to run X beach shack fans for a month"
  ]
}
''';
  }

  String _cashewPrompt() {
    return '''
You are a sustainability AI for Goa CASHEW PROCESSING factories.
Return STRICT JSON only. No text outside JSON.

Analyze this cashew factory operation:
- Roasting hours/day: ${roastingHours.toStringAsFixed(1)}
- Fuel type: $fuelType (firewood/biomass/electric/LPG)
- Shell waste: ${shellWasteKg.toStringAsFixed(1)} kg/day
- CNSL oil collected: ${cnslOilLitres.toStringAsFixed(1)} litres/day
- Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
- LPG: ${lpgKg.toStringAsFixed(1)} kg/day
- Location: Goa (India's largest cashew processor)

Key sustainability issues for Goa cashew:
- Shell burning produces toxic fumes and PM2.5 pollution
- CNSL (cashew nut shell liquid) is valuable but often wasted
- Firewood use drives deforestation in Western Ghats
- Water use in processing

Return JSON:
{
  "insight": "2-3 sentence sustainability analysis of THIS cashew factory with exact numbers. Mention Goa-specific context.",
  "current": {"carbon": "X.X kg CO2", "cost": "Rs XXXX"},
  "optimized": {
    "plan": ["Step 1: specific action for cashew processing", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2", "cost": "Rs XXXX"
  },
  "savings": {"carbon_reduction": "XX%", "money_saved": "Rs XXX"},
  "subsidy": {"name": "Real Indian govt scheme for food processing/MSMEs", "amount": "Rs XX,XXX", "reason": "Why it fits this cashew factory"},
  "analysis": [
    "Equivalent to saving X cashew trees from being cut for firewood",
    "CNSL recovery could generate Rs X extra revenue per month",
    "Like reducing smoke exposure for X factory workers daily",
    "Shell waste can produce X kg of biochar for Goan farms"
  ]
}
''';
  }

  String _farmerPrompt() {
    return '''
You are a sustainability AI for Goa FARMERS (paddy, spice, horticulture, coconut).
Return STRICT JSON only. No text outside JSON.

Analyze this Goan farm operation:
- Land: ${landAcres.toStringAsFixed(1)} acres
- Crop type: $cropType
- Chemical fertilizer: ${fertilizerKg.toStringAsFixed(1)} kg/day
- Pesticide: ${pesticideL.toStringAsFixed(1)} litres/day
- Water usage: ${waterUsageL.toStringAsFixed(0)} litres/day
- Irrigation: $irrigationType (flood/drip/sprinkler/rainfed)
- Electricity (pump): ${electricityKwh.toStringAsFixed(1)} kWh/day
- Location: Goa

Key sustainability issues for Goa farming:
- Excessive chemical use pollutes Goa's rivers (Mandovi, Zuari)
- Flood irrigation wastes 60% water
- Paddy stubble burning causes air pollution
- Goa's laterite soil needs organic matter replenishment

Return JSON:
{
  "insight": "2-3 sentence sustainability analysis of THIS farm with exact numbers. Reference Goa rivers/soil.",
  "current": {"carbon": "X.X kg CO2", "cost": "Rs XXXX"},
  "optimized": {
    "plan": ["Step 1: specific sustainable farming action", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2", "cost": "Rs XXXX"
  },
  "savings": {"carbon_reduction": "XX%", "money_saved": "Rs XXX"},
  "subsidy": {"name": "Real Indian govt scheme for farmers (PM-KISAN, PKVY, etc.)", "amount": "Rs XX,XXX", "reason": "Why it fits this farm"},
  "analysis": [
    "Prevents X kg of chemicals from entering Goa's Mandovi river",
    "Saves X litres of water — enough for X Goan families for a day",
    "Like planting X mango trees in the Western Ghats",
    "Organic switch could earn Rs X premium per quintal at Mapusa market"
  ]
}
''';
  }

  String _bakeryPrompt() {
    return '''
You are a sustainability AI for Goa BAKERIES (Pao, Poee bread, confectionery).
Return STRICT JSON only. No text outside JSON.

Analyze this Goan bakery operation:
- Oven hours/day: ${ovenHours.toStringAsFixed(1)}
- Oven fuel: $ovenFuel (electric/gas/wood-fired)
- Flour used: ${flourKg.toStringAsFixed(1)} kg/day
- Butter/fat: ${butterKg.toStringAsFixed(1)} kg/day
- Bread waste/surplus: ${breadWasteKg.toStringAsFixed(1)} kg/day
- Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
- Location: Goa

Key sustainability issues for Goa bakeries:
- Traditional Goan "poder" bakeries use wood-fired ovens (deforestation)
- Bread surplus waste is a major issue (day-old pao)
- High energy consumption from continuous oven operation
- Packaging waste from plastic bags

Return JSON:
{
  "insight": "2-3 sentence sustainability analysis of THIS bakery with exact numbers. Mention Goan bread culture.",
  "current": {"carbon": "X.X kg CO2", "cost": "Rs XXXX"},
  "optimized": {
    "plan": ["Step 1: specific action for Goan bakery", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2", "cost": "Rs XXXX"
  },
  "savings": {"carbon_reduction": "XX%", "money_saved": "Rs XXX"},
  "subsidy": {"name": "Real Indian govt scheme for food processing/MSME", "amount": "Rs XX,XXX", "reason": "Why it fits this bakery"},
  "analysis": [
    "Bread waste of X kg could feed X families through food banks daily",
    "Like saving X trees from being cut for wood-fired ovens annually",
    "Energy savings equal to powering X Goan homes for a day",
    "Switching packaging saves X plastic bags from Goa's beaches monthly"
  ]
}
''';
  }

  String _otherPrompt() {
    return '''
You are a sustainability AI for Goa businesses. The user has a custom business profile.
Return STRICT JSON only. No text outside JSON.

Analyze this Custom Business operation:
- Business Type/Description: $otherBusinessType
- Energy Source: $otherEnergySource (grid/solar/diesel)
- Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
- Water usage: ${otherWaterUsageL.toStringAsFixed(0)} litres/day
- Primary Waste Type: $otherWasteType
- Organic Waste: ${organicWasteKg.toStringAsFixed(1)} kg/day
- Oil/Mixed Waste: ${oilWasteKg.toStringAsFixed(1)} kg/day
- Location: Goa

Return JSON:
{
  "insight": "2-3 sentence sustainability analysis for this specific '$otherBusinessType' business in Goa with exact numbers.",
  "current": {"carbon": "X.X kg CO2", "cost": "Rs XXXX"},
  "optimized": {
    "plan": ["Step 1: specific action", "Step 2: ...", "Step 3: ...", "Step 4: ..."],
    "carbon": "X.X kg CO2", "cost": "Rs XXXX"
  },
  "savings": {"carbon_reduction": "XX%", "money_saved": "Rs XXX"},
  "subsidy": {"name": "Real Indian govt scheme applicable to $otherBusinessType", "amount": "Rs XX,XXX", "reason": "Why it fits this business"},
  "analysis": [
    "Equivalent to planting X coconut trees",
    "Energy savings equal to powering X Goan homes for a day",
    "Saves X litres of water daily",
    "Diverts X kg of waste from Goa landfills"
  ]
}
''';
  }

  // ════════════════════════════════════════════════
  //  DIRECT GROQ CALL
  // ════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _callGroqDirect(String prompt) async {
    final apiKey = AppEnv.groqApiKey;
    if (apiKey.isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.5,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Return only valid JSON. No markdown. No text outside JSON.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final text = body['choices'][0]['message']['content'] as String;
        return _extractJson(text);
      }
      return null;
    } catch (e) {
      debugPrint('Groq error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {}
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {}
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      try {
        return jsonDecode(text.substring(start, end + 1))
            as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> fetchSustainabilityPlan() async {
    final thisRequestId = ++_requestId;
    isLoadingPlan = true;
    notifyListeners();

    final prompt = _buildPrompt();
    Map<String, dynamic>? result;
    String source = 'fallback';

    result = await _callGroqDirect(prompt);
    if (result != null) source = 'groq';

    if (thisRequestId != _requestId) return;

    if (result == null) {
      _useFallback();
      return;
    }

    latestSustainabilityPlan = SustainabilityPlan.fromJson({
      ...result,
      'source': source,
    });

    final currentData = result['current'] as Map<String, dynamic>? ?? {};
    final optimizedData = result['optimized'] as Map<String, dynamic>? ?? {};
    final savingsData = result['savings'] as Map<String, dynamic>? ?? {};

    latestPlanComparison = TourismPlanComparison(
      currentPlan: {
        'carbon': currentData['carbon'] ?? '',
        'cost': currentData['cost'] ?? '',
        'impact_summary': result['insight'] ?? '',
      },
      optimizedPlan: {
        'plan': optimizedData['plan'] ?? [],
        'carbon': optimizedData['carbon'] ?? '',
        'cost': optimizedData['cost'] ?? '',
      },
      comparison: {
        'carbon_reduction_percent': savingsData['carbon_reduction'] ?? '',
        'money_saved': savingsData['money_saved'] ?? '',
      },
      emotionalMessage: (result['emotional_message'] ?? '').toString(),
    );

    latestInsight = GeminiInsight(
      emissions: (currentData['carbon'] ?? '').toString(),
      insight: (result['insight'] ?? '').toString(),
      betterOption: '',
      ecoItinerary:
          (optimizedData['plan'] is List &&
              (optimizedData['plan'] as List).isNotEmpty)
          ? (optimizedData['plan'] as List).first.toString()
          : '',
      moneySaved: (savingsData['money_saved'] ?? '').toString(),
      carbonSaved: (savingsData['carbon_reduction'] ?? '').toString(),
      ecoScore: ecoScore.toStringAsFixed(0),
      localBusinessLinks: '',
    );

    isLoadingPlan = false;
    notifyListeners();
  }

  void _useFallback() {
    latestSustainabilityPlan = SustainabilityPlan.fallback(
      dailyTotal: dailyTotal,
    );
    latestInsight = GeminiInsight.fallback(
      emissions: '${dailyTotal.toStringAsFixed(1)} kg CO2 today',
      betterOption: 'Switch to sustainable alternatives',
      ecoItinerary: 'Eco-optimized plan generated',
    );
    latestPlanComparison = TourismPlanComparison.fallback(
      currentCarbon: '${dailyTotal.toStringAsFixed(1)} kg CO2',
      optimizedCarbon: '${(dailyTotal * 0.66).toStringAsFixed(1)} kg CO2',
    );
    isLoadingPlan = false;
    notifyListeners();
  }

  Future<void> generateGeminiInsight() async {
    await fetchSustainabilityPlan();
  }

  // ════════════════════════════════════════════════
  //  CARBON CREDIT ANALYSIS ENGINE
  // ════════════════════════════════════════════════

  Future<void> generateCarbonCreditAnalysis() async {
    isLoadingCarbonCredit = true;
    carbonCreditAnalysis = null;
    notifyListeners();

    final sectorContext = _buildCarbonCreditContext();

    final prompt =
        '''
You are a carbon credit market expert specializing in India's CCTS (Carbon Credit Trading Scheme) and the global Voluntary Carbon Market (VCM).

A Goa-based business needs a COMPLETE carbon credit analysis.

=== BUSINESS PROFILE ===
$sectorContext

=== YOUR KNOWLEDGE BASE ===
- 1 Carbon Credit = 1 tonne CO2e reduced/avoided/removed
- India CCTS: Under Energy Conservation Act 2022, managed by BEE
- Voluntary market size 2025: ~15.8B USD, projected 120B by 2030
- Compliance market (EU ETS): 65-80 EUR/tonne
- Voluntary market average: 4-24 USD/tonne
- Biochar credits: 100-200 USD/tonne (premium permanent removal)
- Soil carbon credits: 10-20 USD/tonne
- Methane capture credits: 8-15 USD/tonne
- Cookstove/energy efficiency credits: 5-12 USD/tonne
- REDD+ forest credits: 10-24 USD/tonne
- India is one of the largest VCM credit sellers globally
- Key registries: Verra (VCUs), Gold Standard (VERs)
- Small farms can earn 100-600 USD/yr, large farms 10K-100K USD/yr
- Credit generation takes 6 months to 2+ years, costs 50K-500K USD
- For small Goa businesses, cooperative/aggregator models reduce costs

Analyze this business and determine:
1. Is it a net carbon EMITTER (needs to buy/offset) or can it GENERATE credits (can sell)?
2. What specific carbon credit opportunities exist?
3. Realistic revenue or cost estimates in Indian Rupees

Return STRICT JSON only. No text outside JSON.
{
  "verdict": "BUYER" or "SELLER" or "BOTH",
  "verdict_reason": "1-2 sentence explanation of why this business is a buyer/seller/both",
  "annual_emissions_kg": 1234,
  "credit_opportunities": [
    {
      "type": "Name of credit opportunity",
      "mechanism": "How it works in 1 sentence",
      "potential_credits": 150, // MUST BE NUMBER, tonnes CO2e/year
      "estimated_revenue": "Rs 5,000 - Rs 15,000 per year", // Must be a range
      "registry": "Verra VCS",
      "difficulty": "Easy/Medium/Hard",
      "timeline": "X months",
      "is_creditable": true,
      "viable_for_market": true,
      "requires_capital_investment": false,
      "minimum_capex_inr": 0
    }
  ],
  "offset_cost": "Rs X,XXX per year to offset all emissions (if buyer)",
  "net_position": "Net annual carbon position: +X or -X tonnes CO2e",
  "action_plan": [
    "Step 1: Immediate action to take",
    "Step 2: Next step",
    "Step 3: Long-term strategy"
  ],
  "india_schemes": [
    {
      "scheme": "Name of Indian scheme",
      "relevance": "How it applies to this business",
      "potential_benefit": "Rs X,XXX",
      "official_url": "https://..."
    }
  ],
  "market_insight": "1-2 sentence insight about 2025-2030 trajectory",
  "analysis_confidence": {
    "score": 8, // 1-10
    "reason": "Explain confidence level",
    "is_standard_sector": true
  }
}

CRITICAL RULES — follow these exactly:
1. Never fabricate government portal URLs. If you are not 100% certain of an official URL, return null for that field.
2. Never state that a business will definitely earn a specific ₹ amount. Use ranges and always include the phrase 'before development costs' in revenue estimates.
3. Only consider Scope 1 and Scope 2 emissions and reductions when calculating carbon credit generation opportunities. Do not include Scope 3 items in credit opportunity calculations. Clearly flag if any opportunity you suggest relies on Scope 3 activity, and mark it as 'NOT CREDITABLE — Scope 3', and set 'is_creditable' to false and explain why.
4. If estimated annual tonnes CO₂e for any opportunity is below 50 tonnes, set 'viable_for_market' to false.
5. Do not recommend renewable energy credits as a primary credit generation strategy — flag ICVCM additionality concerns.
6. For biochar opportunities, always set 'requires_capital_investment' to true and include minimum_capex_inr field.
7. Confidence in your analysis must be explicitly self-rated 1-10 in the response JSON.
8. If 'is_standard_sector' is false, set score to maximum 5 regardless of other factors.
''';

    final result = await _callGroqDirect(prompt);

    if (result != null && _validateCarbonCreditResponse(result)) {
      carbonCreditAnalysis = result;
    } else {
      // Fallback
      final annualEmissions = (dailyTotal * 365).round();
      carbonCreditAnalysis = {
        'verdict': annualEmissions > 5000 ? 'BUYER' : 'BOTH',
        'verdict_reason':
            'Based on estimated annual emissions of ${annualEmissions}kg CO2e.',
        'annual_emissions_kg': annualEmissions,
        'credit_opportunities': [
          {
            'type': 'Energy Efficiency Upgrade',
            'mechanism':
                'Switching to solar/efficient equipment generates avoidance credits.',
            'potential_credits': (annualEmissions * 0.3 / 1000).round(),
            'estimated_revenue':
                'Rs ${(annualEmissions * 0.3 * 0.4).round()} - Rs ${(annualEmissions * 0.3 * 1.2).round()} per year',
            'registry': 'Verra VCS',
            'difficulty': 'Medium',
            'timeline': '12-18 months',
            'is_creditable': true,
            'viable_for_market': (annualEmissions * 0.3 / 1000) > 50,
            'requires_capital_investment': true,
            'minimum_capex_inr': 1500000,
          },
        ],
        'offset_cost':
            'Rs ${(annualEmissions / 1000 * 400).round()} per year at voluntary market rates',
        'net_position':
            'Net emitter: +${(annualEmissions / 1000).toStringAsFixed(1)} tonnes CO2e/year',
        'action_plan': [
          'Step 1: Calculate precise Scope 1, 2, 3 emissions',
          'Step 2: Identify reduction opportunities before buying offsets',
          'Step 3: Register with Verra or Gold Standard for credit generation',
        ],
        'india_schemes': [
          {
            'scheme': 'India CCTS',
            'relevance':
                'New national carbon trading scheme — monitor for SME inclusion',
            'potential_benefit': 'Market access when scheme expands',
            'official_url': 'https://beeindia.gov.in',
          },
        ],
        'market_insight':
            'The voluntary carbon market is projected to grow 8x by 2030. Early movers in credit generation will benefit from rising prices.',
        'analysis_confidence': {
          'score': 6,
          'reason':
              'Offline fallback calculation based on basic sector averages.',
          'is_standard_sector': true,
        },
      };
    }

    isLoadingCarbonCredit = false;
    notifyListeners();
  }

  bool _validateCarbonCreditResponse(Map<String, dynamic> result) {
    try {
      if (!result.containsKey('verdict') ||
          !result.containsKey('credit_opportunities'))
        return false;

      final opps = result['credit_opportunities'] as List?;
      if (opps != null) {
        for (var opp in opps) {
          if (opp['potential_credits'] == null ||
              opp['potential_credits'] is! num)
            return false;
          if (opp['estimated_revenue'] == null ||
              !opp['estimated_revenue'].toString().contains('-'))
            return false;
          if (opp['registry'] == null) return false;
        }
      }

      final schemes = result['india_schemes'] as List?;
      if (schemes != null) {
        for (var scheme in schemes) {
          final url = scheme['official_url'];
          if (url != null &&
              url.toString().isNotEmpty &&
              !url.toString().startsWith('http'))
            return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String _buildCarbonCreditContext() {
    final annualEmissions = (dailyTotal * 365).round();
    switch (sector) {
      case BusinessSector.tourism:
        return '''
Sector: TOURISM (Beach shack / Hotel / Tour operator in Goa)
Daily CO2: ${dailyTotal.toStringAsFixed(1)} kg | Annual est: ${annualEmissions} kg
Transport mode: ${selectedMode.name}, Distance: ${selectedDistance}km
Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
LPG: ${lpgKg.toStringAsFixed(1)} kg/day
Organic waste: ${organicWasteKg.toStringAsFixed(1)} kg/day
Oil waste: ${oilWasteKg.toStringAsFixed(1)} kg/day

Potential credit paths: Solar rooftop (avoidance), composting (methane avoidance), EV transport, mangrove restoration (blue carbon), eco-tourism certification.''';

      case BusinessSector.cashew:
        return '''
Sector: CASHEW PROCESSING FACTORY in Goa (India's largest cashew processor)
Daily CO2: ${dailyTotal.toStringAsFixed(1)} kg | Annual est: ${annualEmissions} kg
Roasting fuel: $fuelType, Hours: ${roastingHours.toStringAsFixed(1)}/day
Shell waste: ${shellWasteKg.toStringAsFixed(1)} kg/day
CNSL oil recovery: ${cnslOilLitres.toStringAsFixed(1)} litres/day
Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day

CRITICAL OPPORTUNITY: Cashew shells can be converted to BIOCHAR (100-200 USD/tonne premium credit). CNSL is a valuable industrial chemical. Shell burning creates toxic PM2.5. Switching from firewood to biomass/electric reduces Western Ghats deforestation.''';

      case BusinessSector.farmer:
        return '''
Sector: AGRICULTURE / FARMING in Goa
Daily CO2: ${dailyTotal.toStringAsFixed(1)} kg | Annual est: ${annualEmissions} kg
Crop: $cropType, Land: ${landAcres.toStringAsFixed(1)} acres
Irrigation: $irrigationType
Chemical fertilizer: ${fertilizerKg.toStringAsFixed(1)} kg/day
Pesticide: ${pesticideL.toStringAsFixed(1)} L/day
Water: ${waterUsageL.toStringAsFixed(0)} L/day

CRITICAL OPPORTUNITY: Farmers are natural credit SELLERS. Soil carbon sequestration (10-20 USD/tonne), agroforestry, organic conversion, cover crops, paddy water management (methane reduction). Small farms earn 100-600 USD/yr. Cooperative aggregator models make it viable for small Goan farms.''';

      case BusinessSector.bakery:
        return '''
Sector: BAKERY (Traditional Goan Poder / Confectionery)
Daily CO2: ${dailyTotal.toStringAsFixed(1)} kg | Annual est: ${annualEmissions} kg
Oven fuel: $ovenFuel, Hours: ${ovenHours.toStringAsFixed(1)}/day
Flour: ${flourKg.toStringAsFixed(1)} kg/day, Butter: ${butterKg.toStringAsFixed(1)} kg/day
Bread waste: ${breadWasteKg.toStringAsFixed(1)} kg/day

Potential credit paths: Fuel switching (wood to gas/electric = avoidance credits), bread waste to biogas (methane capture credits), energy efficiency upgrades, packaging switch credits.''';

      case BusinessSector.other:
        return '''
Sector: CUSTOM BUSINESS ($otherBusinessType) in Goa
Daily CO2: ${dailyTotal.toStringAsFixed(1)} kg | Annual est: ${annualEmissions} kg
Energy source: $otherEnergySource
Electricity: ${electricityKwh.toStringAsFixed(1)} kWh/day
Water: ${otherWaterUsageL.toStringAsFixed(0)} L/day
Waste type: $otherWasteType
Organic waste: ${organicWasteKg.toStringAsFixed(1)} kg/day

Analyze this specific business type and determine credit opportunities based on its industry.''';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
