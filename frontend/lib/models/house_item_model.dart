class HouseItemModel {
  final String id;
  final String name;
  final String icon;
  final int cost;
  final String description;
  final bool purchased;

  const HouseItemModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.description,
    this.purchased = false,
  });

  factory HouseItemModel.fromJson(Map<String, dynamic> json) {
    return HouseItemModel(
      id: json['item_key'] as String? ?? '',
      name: json['item_name'] as String? ?? '',
      icon: '', // Backend doesn't store icon
      cost: json['cost'] as int? ?? 0,
      description: '', // Backend doesn't store description
      purchased: true, // If it's returned by getHouse(), it's purchased
    );
  }

  HouseItemModel copyWith({bool? purchased}) {
    return HouseItemModel(
      id: id,
      name: name,
      icon: icon,
      cost: cost,
      description: description,
      purchased: purchased ?? this.purchased,
    );
  }
}
