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

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ActivityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ActivityCategory.transport,
      ),
      co2Kg: (json['co2_kg'] as num).toDouble(),
      isSaving: json['is_saving'] as bool,
      timestamp: DateTime.parse(json['logged_at'] as String),
      analogy: json['analogy'] as String? ?? '',
    );
  }

  String get categoryIcon {
    switch (category) {
      case ActivityCategory.transport: return '🚲';
      case ActivityCategory.food: return '🥗';
      case ActivityCategory.energy: return '⚡';
      case ActivityCategory.waste: return '♻️';
    }
  }
}
