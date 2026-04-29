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
}
