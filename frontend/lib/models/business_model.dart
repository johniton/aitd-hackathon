enum BusinessSector { tourism, cashew, farmer, bakery, other }

class BusinessModel {
  final String id;
  final String name;
  final BusinessSector sector;
  final double emissionsKg;
  final double peerAvgKg;
  final List<String> suggestions;
  final List<String> earnedBadges;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.sector,
    required this.emissionsKg,
    required this.peerAvgKg,
    required this.suggestions,
    required this.earnedBadges,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sector: BusinessSector.values.firstWhere(
        (e) => e.name == json['sector'],
        orElse: () => BusinessSector.tourism,
      ),
      emissionsKg: (json['emissions_kg'] as num).toDouble(),
      peerAvgKg: (json['peer_avg_kg'] as num).toDouble(),
      suggestions: (json['suggestions'] as List).cast<String>(),
      earnedBadges: (json['badges'] as List).cast<String>(),
    );
  }

  String get sectorIcon {
    switch (sector) {
      case BusinessSector.tourism: return '🏖️';
      case BusinessSector.cashew: return '🌰';
      case BusinessSector.farmer: return '🌾';
      case BusinessSector.bakery: return '🍞';
      case BusinessSector.other: return '⚙️';
    }
  }

  String get sectorLabel {
    switch (sector) {
      case BusinessSector.tourism: return 'Tourism';
      case BusinessSector.cashew: return 'Cashew';
      case BusinessSector.farmer: return 'Farmer';
      case BusinessSector.bakery: return 'Bakery';
      case BusinessSector.other: return 'Custom';
    }
  }
}

class SubsidyModel {
  final String title;
  final String description;
  final String amount;
  final String deadline;
  final bool isEligible;

  const SubsidyModel({
    required this.title,
    required this.description,
    required this.amount,
    required this.deadline,
    required this.isEligible,
  });

  factory SubsidyModel.fromJson(Map<String, dynamic> json) {
    return SubsidyModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      deadline: json['deadline'] as String? ?? '',
      isEligible: json['is_eligible'] as bool? ?? false,
    );
  }
}

class ExchangeItem {
  final String id;
  final String title;
  final String offeredBy;
  final String sector;
  final String description;

  const ExchangeItem({
    required this.id,
    required this.title,
    required this.offeredBy,
    required this.sector,
    required this.description,
  });

  factory ExchangeItem.fromJson(Map<String, dynamic> json) {
    return ExchangeItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      offeredBy: json['offered_by'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
