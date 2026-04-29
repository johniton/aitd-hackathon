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
