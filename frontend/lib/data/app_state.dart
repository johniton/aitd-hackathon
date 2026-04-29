import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../models/house_item_model.dart';
import 'static_data.dart';
import 'emission_factors.dart';

class AppState extends ChangeNotifier {
  late UserModel _user;
  final List<ActivityModel> _activities = List.from(recentActivities);
  final List<HouseItemModel> _shopItems = List.from(shopItems);
  final List<double> _weekly = List.from(weeklyData);
  String? _smartTip;

  AppState() {
    _user = currentUser;
    _refreshSmartTip();
  }

  UserModel get user => _user;
  List<ActivityModel> get activities => List.unmodifiable(_activities);
  List<HouseItemModel> get shop => List.unmodifiable(_shopItems);
  List<double> get weekly => List.unmodifiable(_weekly);
  String? get smartTip => _smartTip;

  List<HouseItemModel> get purchased =>
      _shopItems.where((i) => i.purchased).toList();

  void logActivity({
    required String title,
    required ActivityCategory category,
    required double co2Kg,
    required bool isSaving,
  }) {
    final analogy = EmissionFactors.analogy(co2Kg);
    final coins = co2Kg == 0 ? 20 : 5;
    final activity = ActivityModel(
      id: 'a${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      co2Kg: co2Kg,
      isSaving: isSaving,
      timestamp: DateTime.now(),
      analogy: analogy,
    );
    _activities.insert(0, activity);

    // Update today's weekly bar
    final weekday = DateTime.now().weekday - 1; // 0=Mon
    _weekly[weekday] = _weekly[weekday] + (isSaving ? co2Kg : 0);

    // Update user coins + saved
    final newCoins = _user.greenCoins + coins;
    final newSaved = isSaving ? _user.totalCo2Saved + co2Kg : _user.totalCo2Saved;
    _user = UserModel(
      id: _user.id,
      name: _user.name,
      avatarInitials: _user.avatarInitials,
      greenCoins: newCoins,
      totalCo2Saved: newSaved,
      streakDays: _user.streakDays,
      rank: _user.rank,
      city: _user.city,
    );

    _refreshSmartTip();
    notifyListeners();
  }

  bool buyItem(String itemId) {
    final idx = _shopItems.indexWhere((i) => i.id == itemId);
    if (idx == -1) return false;
    final item = _shopItems[idx];
    if (item.purchased) return false;
    if (_user.greenCoins < item.cost) return false;

    _shopItems[idx] = HouseItemModel(
      id: item.id,
      name: item.name,
      icon: item.icon,
      cost: item.cost,
      description: item.description,
      purchased: true,
    );
    _user = UserModel(
      id: _user.id,
      name: _user.name,
      avatarInitials: _user.avatarInitials,
      greenCoins: _user.greenCoins - item.cost,
      totalCo2Saved: _user.totalCo2Saved,
      streakDays: _user.streakDays,
      rank: _user.rank,
      city: _user.city,
    );
    notifyListeners();
    return true;
  }

  void updateProfile({String? name, String? city}) {
    _user = UserModel(
      id: _user.id,
      name: name ?? _user.name,
      avatarInitials: name != null
          ? name.trim().split(' ').where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase()).take(2).join()
          : _user.avatarInitials,
      greenCoins: _user.greenCoins,
      totalCo2Saved: _user.totalCo2Saved,
      streakDays: _user.streakDays,
      rank: _user.rank,
      city: city ?? _user.city,
    );
    notifyListeners();
  }

  List<BadgeInfo> get earnedBadges {
    final badges = <BadgeInfo>[];
    if (_activities.isNotEmpty) badges.add(const BadgeInfo('🌱', 'Green Starter'));
    if (_activities.any((a) => a.category == ActivityCategory.transport && a.co2Kg == 0)) {
      badges.add(const BadgeInfo('🚲', 'Cyclist'));
    }
    if (_activities.any((a) => a.category == ActivityCategory.waste)) {
      badges.add(const BadgeInfo('♻️', 'Recycler'));
    }
    if (_user.streakDays >= 7) badges.add(BadgeInfo('🔥', '${_user.streakDays} Day Streak'));
    if (_activities.any((a) => a.category == ActivityCategory.food && a.co2Kg <= 0.5)) {
      badges.add(const BadgeInfo('🥗', 'Plant-based'));
    }
    if (_activities.length >= 10) badges.add(const BadgeInfo('⭐', 'Logger Pro'));
    if (purchased.length >= 3) badges.add(const BadgeInfo('🏡', 'Home Builder'));
    return badges;
  }

  Map<String, dynamic> get wrappedStats {
    final saved = _user.totalCo2Saved;
    final trees = (saved / 7.3).round();
    final cats = <ActivityCategory, int>{};
    for (final a in _activities) {
      cats[a.category] = (cats[a.category] ?? 0) + 1;
    }
    final topCat = cats.isEmpty
        ? 'Transport'
        : cats.entries.reduce((a, b) => a.value >= b.value ? a : b).key.name;
    return {
      'co2Saved': saved,
      'treesEquivalent': trees,
      'topCategory': topCat[0].toUpperCase() + topCat.substring(1),
      'bestWeek': 'March 3–9',
      'percentile': 82,
      'activitiesLogged': _activities.length,
      'greenCoinsEarned': _user.greenCoins.toInt(),
    };
  }

  void _refreshSmartTip() {
    final cats = <ActivityCategory, double>{};
    for (final a in _activities.take(10)) {
      cats[a.category] = (cats[a.category] ?? 0) + a.co2Kg;
    }
    if (cats.isEmpty) {
      _smartTip = '🌱 Start logging activities to get personalised eco-tips!';
      return;
    }
    final worst = cats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    _smartTip = _tips[worst];
  }

  static const _tips = {
    ActivityCategory.transport: '🚌 Swap one car trip for the bus this week — saves ~1.2 kg CO₂ per 6 km.',
    ActivityCategory.food: '🥗 Try one meat-free day — a veg meal emits 5× less than a meat meal.',
    ActivityCategory.energy: '☀️ Run heavy appliances before noon when Goa\'s solar feed is highest.',
    ActivityCategory.waste: '🍂 Compost kitchen scraps — composting emits 7× less than landfill.',
  };
}

class BadgeInfo {
  final String emoji;
  final String label;
  const BadgeInfo(this.emoji, this.label);
}
