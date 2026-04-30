class MapDensityPointModel {
  final double latitude;
  final double longitude;
  final int users;
  final double coinTotal;
  final String? city;

  const MapDensityPointModel({
    required this.latitude,
    required this.longitude,
    required this.users,
    required this.coinTotal,
    required this.city,
  });

  factory MapDensityPointModel.fromJson(Map<String, dynamic> json) {
    return MapDensityPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      users: json['users'] as int,
      coinTotal: (json['coin_total'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String?,
    );
  }
}
