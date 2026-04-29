enum ActivityCategory { transport, food, energy, waste }

class ActivityModel {
  final String id;
  final String title;
  final ActivityCategory category;
  final double co2Kg;
  final bool isSaving;
  final DateTime timestamp;
  final String analogy;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.category,
    required this.co2Kg,
    required this.isSaving,
    required this.timestamp,
    required this.analogy,
  });

  String get categoryIcon {
    switch (category) {
      case ActivityCategory.transport: return '🚲';
      case ActivityCategory.food: return '🥗';
      case ActivityCategory.energy: return '⚡';
      case ActivityCategory.waste: return '♻️';
    }
  }
}
