class UserModel {
  final String id;
  final String name;
  final String avatarInitials;
  final double greenCoins;
  final double totalCo2Saved;
  final int streakDays;
  final int rank;
  final String city;

  const UserModel({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.greenCoins,
    required this.totalCo2Saved,
    required this.streakDays,
    required this.rank,
    required this.city,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarInitials: json['avatar_initials'] as String,
      greenCoins: (json['green_coins'] as num).toDouble(),
      totalCo2Saved: (json['total_co2_saved'] as num).toDouble(),
      streakDays: json['streak_days'] as int,
      rank: json['rank'] as int? ?? 0,
      city: json['city'] as String? ?? '',
    );
  }
}
