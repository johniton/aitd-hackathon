enum TransportMode { car, bike, bus, walking }

enum WasteType { organic, oil }

class TripLog {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final TransportMode mode;

  const TripLog({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.mode,
  });

  bool get isActive => endedAt == null;
}

class GeminiInsight {
  final String emissions;
  final String insight;
  final String betterOption;
  final String ecoItinerary;
  final String moneySaved;
  final String carbonSaved;
  final String ecoScore;
  final String localBusinessLinks;

  const GeminiInsight({
    required this.emissions,
    required this.insight,
    required this.betterOption,
    required this.ecoItinerary,
    required this.moneySaved,
    required this.carbonSaved,
    required this.ecoScore,
    required this.localBusinessLinks,
  });

  factory GeminiInsight.fallback({
    required String emissions,
    required String betterOption,
    required String ecoItinerary,
  }) {
    return GeminiInsight(
      emissions: emissions,
      insight:
          'You are getting closer to a low-carbon tourism journey. Small route and mode changes can compound into visible weekly gains.',
      betterOption: betterOption,
      ecoItinerary: ecoItinerary,
      moneySaved: '₹500/day',
      carbonSaved: '40%',
      ecoScore: '78',
      localBusinessLinks: '3 eco options nearby',
    );
  }
}

class SubsidyMatch {
  final String title;
  final String amount;
  final String description;
  final bool isEligible;

  const SubsidyMatch({
    required this.title,
    required this.amount,
    required this.description,
    required this.isEligible,
  });
}

class ExchangeMatch {
  final String title;
  final String description;
  final int nearbyBusinesses;

  const ExchangeMatch({
    required this.title,
    required this.description,
    required this.nearbyBusinesses,
  });
}

class TourismPlanComparison {
  final Map<String, dynamic> currentPlan;
  final Map<String, dynamic> optimizedPlan;
  final Map<String, dynamic> comparison;
  final String emotionalMessage;

  const TourismPlanComparison({
    required this.currentPlan,
    required this.optimizedPlan,
    required this.comparison,
    required this.emotionalMessage,
  });

  factory TourismPlanComparison.fallback({
    required String currentCarbon,
    required String optimizedCarbon,
  }) {
    return TourismPlanComparison(
      currentPlan: {
        'carbon': currentCarbon,
        'cost': '₹2,400',
        'impact_summary': 'Mixed mode with avoidable car-heavy segments',
      },
      optimizedPlan: {
        'itinerary': [
          {
            'activity': 'Morning beach cleanup + breakfast at local farm cafe',
            'transport': 'cycling',
            'distance': '4 km',
          },
          {
            'activity': 'Old Goa heritage walk with local guide',
            'transport': 'walking',
            'distance': '2 km',
          },
          {
            'activity': 'Shared electric shuttle to local market',
            'transport': 'shared transport',
            'distance': '6 km',
          },
        ],
        'carbon': optimizedCarbon,
        'cost': '₹1,850',
        'impact_summary': 'Lower emissions, shorter travel loops, richer local experiences',
      },
      comparison: {
        'carbon_reduction_percent': '34%',
        'money_saved': '₹550',
        'experience_improvement': 'More authentic local food/farm interactions',
      },
      emotionalMessage:
          'Your itinerary now supports Goa local communities while protecting beaches and reducing climate impact.',
    );
  }
}

// ---------- NEW: Sustainability Plan Models ----------

class SavingsData {
  final String carbonReduction;
  final String moneySaved;

  const SavingsData({
    required this.carbonReduction,
    required this.moneySaved,
  });

  factory SavingsData.fromJson(Map<String, dynamic> json) {
    return SavingsData(
      carbonReduction: (json['carbon_reduction'] ?? '0%').toString(),
      moneySaved: (json['money_saved'] ?? 'Rs 0').toString(),
    );
  }

  factory SavingsData.fallback() {
    return const SavingsData(carbonReduction: '38%', moneySaved: 'Rs 550');
  }
}

class SubsidyData {
  final String name;
  final String amount;
  final String reason;

  const SubsidyData({
    required this.name,
    required this.amount,
    required this.reason,
  });

  factory SubsidyData.fromJson(Map<String, dynamic> json) {
    return SubsidyData(
      name: (json['name'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  factory SubsidyData.fallback() {
    return const SubsidyData(
      name: 'Green Tourism Grant',
      amount: '₹50,000',
      reason: 'Your eco improvements qualify for zero-waste tourism incentive',
    );
  }
}

class SustainabilityPlan {
  final String insight;
  final Map<String, dynamic> current;
  final Map<String, dynamic> optimized;
  final SavingsData savings;
  final SubsidyData subsidy;
  final List<String> analysis;
  final String source;
  final String emotionalMessage;

  const SustainabilityPlan({
    required this.insight,
    required this.current,
    required this.optimized,
    required this.savings,
    required this.subsidy,
    required this.analysis,
    required this.source,
    required this.emotionalMessage,
  });

  List<String> get optimizedPlanSteps {
    final plan = optimized['plan'];
    if (plan is List) {
      return plan.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory SustainabilityPlan.fromJson(Map<String, dynamic> json) {
    final rawAnalysis = json['analysis'];
    final analysisList = (rawAnalysis is List)
        ? rawAnalysis.map((e) => e.toString()).toList()
        : <String>[];

    return SustainabilityPlan(
      insight: (json['insight'] ?? '').toString(),
      current: (json['current'] as Map<String, dynamic>?) ?? {},
      optimized: (json['optimized'] as Map<String, dynamic>?) ?? {},
      savings: SavingsData.fromJson(
          (json['savings'] as Map<String, dynamic>?) ?? {}),
      subsidy: SubsidyData.fromJson(
          (json['subsidy'] as Map<String, dynamic>?) ?? {}),
      analysis: analysisList,
      source: (json['source'] ?? 'unknown').toString(),
      emotionalMessage: (json['emotional_message'] ?? '').toString(),
    );
  }

  factory SustainabilityPlan.fallback({
    required double dailyTotal,
  }) {
    final optimizedCarbon = dailyTotal * 0.62;
    final reduction = ((1 - 0.62) * 100).round();
    final saved = dailyTotal * 0.38;
    return SustainabilityPlan(
      insight:
          'Your daily operations emit ${dailyTotal.toStringAsFixed(1)} kg CO2. Switching to eco modes can cut this by $reduction%.',
      current: {
        'carbon': '${dailyTotal.toStringAsFixed(1)} kg CO2',
        'cost': 'Rs ${(dailyTotal * 80).round()}',
      },
      optimized: {
        'plan': [
          'Step 1: Morning coastal cycling to eco-stop (4 km)',
          'Step 2: Farm-to-table lunch + spice farm walk (2 km)',
          'Step 3: Shared electric shuttle to heritage market (6 km)',
          'Step 4: Evening beach cleanup walk (3 km)',
        ],
        'carbon': '${optimizedCarbon.toStringAsFixed(1)} kg CO2',
        'cost': 'Rs ${(dailyTotal * 50).round()}',
      },
      savings: SavingsData.fallback(),
      subsidy: SubsidyData.fallback(),
      analysis: [
        'Equivalent to planting ${(saved / 0.022).round()} coconut trees in Goa',
        'Like removing ${(saved / 2.4).round()} auto-rickshaws from Panaji roads for a day',
        'Saves enough energy to power ${(saved / 0.82).round()} Goan households for a day',
      ],
      source: 'fallback',
      emotionalMessage:
          'Every green choice helps preserve Goa for generations.',
    );
  }
}

