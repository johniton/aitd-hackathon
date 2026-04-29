enum BusinessSector { tourism, cashew, farmer, bakery }

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

  String get sectorIcon {
    switch (sector) {
      case BusinessSector.tourism: return '🏖️';
      case BusinessSector.cashew: return '🌰';
      case BusinessSector.farmer: return '🌾';
      case BusinessSector.bakery: return '🍞';
    }
  }

  String get sectorLabel {
    switch (sector) {
      case BusinessSector.tourism: return 'Tourism';
      case BusinessSector.cashew: return 'Cashew';
      case BusinessSector.farmer: return 'Farmer';
      case BusinessSector.bakery: return 'Bakery';
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
}
