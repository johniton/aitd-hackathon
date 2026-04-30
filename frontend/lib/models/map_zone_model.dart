class MapZoneModel {
  final String name;
  final String label;
  final double co2PerCap;
  final double positionX;
  final double positionY;
  final String colorHex;

  const MapZoneModel({
    required this.name,
    required this.label,
    required this.co2PerCap,
    required this.positionX,
    required this.positionY,
    required this.colorHex,
  });

  factory MapZoneModel.fromJson(Map<String, dynamic> json) {
    return MapZoneModel(
      name: json['name'] as String,
      label: json['label'] as String,
      co2PerCap: (json['co2_per_cap'] as num).toDouble(),
      positionX: (json['position_x'] as num).toDouble(),
      positionY: (json['position_y'] as num).toDouble(),
      colorHex: json['color_hex'] as String,
    );
  }
}
