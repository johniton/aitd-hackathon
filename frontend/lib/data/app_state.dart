import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../models/house_item_model.dart';
import '../services/api_service.dart';
import '../services/carbon_api.dart';
import 'emission_factors.dart';

const _shopTemplate = [
  HouseItemModel(id: 'h1', name: 'Solar Roof',     icon: '☀️', cost: 200, description: '-30% energy emissions'),
  HouseItemModel(id: 'h2', name: 'Rain Garden',    icon: '🌿', cost: 150, description: 'Absorbs 5kg CO₂/month'),
  HouseItemModel(id: 'h3', name: 'EV Charger',     icon: '⚡', cost: 300, description: 'Unlock EV transport logging'),
  HouseItemModel(id: 'h4', name: 'Rainwater Tank', icon: '💧', cost: 180, description: 'Save 500L water/month'),
  HouseItemModel(id: 'h5', name: 'Compost Bin',    icon: '♻️', cost: 80,  description: 'Double waste points'),
  HouseItemModel(id: 'h6', name: 'Terrace Farm',   icon: '🥦', cost: 220, description: 'Grow your own food'),
];

class AppState extends ChangeNotifier {
  UserModel? _user;
  final List<ActivityModel> _activities = [];
  final List<HouseItemModel> _shopItems = List.from(_shopTemplate);
  final List<double> _weekly = List.filled(7, 0.0);
  String? _smartTip;
  List<ApiSuggestion> _lastSuggestions = [];
  bool _backendOnline = false;
  bool _initialized = false;

  AppState({String? userId}) {
    if (userId != null) ApiService.setUserId(userId);
    _init();
  }

  UserModel get user => _user ?? const UserModel(
    id: '', name: 'Loading…', avatarInitials: '…',
    greenCoins: 0, totalCo2Saved: 0, streakDays: 0, rank: 0, city: '',
  );
  List<ActivityModel> get activities => List.unmodifiable(_activities);
  List<HouseItemModel> get shop => List.unmodifiable(_shopItems);
  List<double> get weekly => List.unmodifiable(_weekly);
  String? get smartTip => _smartTip;
  List<ApiSuggestion> get lastSuggestions => List.unmodifiable(_lastSuggestions);
  bool get backendOnline => _backendOnline;
  bool get initialized => _initialized;

  List<HouseItemModel> get purchased =>
      _shopItems.where((i) => i.purchased).toList();

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getActivities(limit: 50),
        ApiService.getWeekly(),
        ApiService.getHouse(),
      ]);
      _user = results[0] as UserModel;
      final acts = results[1] as List<ActivityModel>;
      _activities
        ..clear()
        ..addAll(acts);
      final weeklyList = results[2] as List<double>;
      for (int i = 0; i < weeklyList.length && i < 7; i++) {
        _weekly[i] = weeklyList[i];
      }
      _backendOnline = true;
      _syncHousePurchases(results[3] as Map<String, dynamic>);
    } catch (_) {
      // silently fall back to empty state — screens handle errors themselves
    }
    _refreshSmartTip();
    _initialized = true;
    notifyListeners();
  }

  /// Marks shop items as purchased based on backend house data.
  void _syncHousePurchases(Map<String, dynamic> houseData) {
    final items = houseData['items'] as List<dynamic>? ?? [];
    final purchasedKeys = items.map((e) => e['item_key'] as String).toSet();
    for (int i = 0; i < _shopItems.length; i++) {
      if (purchasedKeys.contains(_shopItems[i].id)) {
        _shopItems[i] = _shopItems[i].copyWith(purchased: true);
      }
    }
    // Also update coins from backend
    final coins = (houseData['coins'] as num?)?.toDouble();
    if (coins != null && _user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        avatarInitials: _user!.avatarInitials,
        greenCoins: coins,
        totalCo2Saved: _user!.totalCo2Saved,
        streakDays: _user!.streakDays,
        rank: _user!.rank,
        city: _user!.city,
      );
    }
  }

  void logActivity({
    required String title,
    required ActivityCategory category,
    required double co2Kg,
    required bool isSaving,
    String? apiCategory,
    String? apiType,
    double? apiValue,
  }) {
    final analogy = EmissionFactors.analogy(co2Kg);
    final coins = co2Kg == 0 ? 20 : 5;
    final tempId = 'a${DateTime.now().millisecondsSinceEpoch}';
    final activity = ActivityModel(
      id: tempId,
      title: title,
      category: category,
      co2Kg: co2Kg,
      isSaving: isSaving,
      timestamp: DateTime.now(),
      analogy: analogy,
    );
    _activities.insert(0, activity);

    final weekday = DateTime.now().weekday - 1;
    _weekly[weekday] = _weekly[weekday] + (isSaving ? co2Kg : 0);

    if (_user != null) {
      final newCoins = _user!.greenCoins + coins;
      final newSaved = isSaving ? _user!.totalCo2Saved + co2Kg : _user!.totalCo2Saved;
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        avatarInitials: _user!.avatarInitials,
        greenCoins: newCoins,
        totalCo2Saved: newSaved,
        streakDays: _user!.streakDays,
        rank: _user!.rank,
        city: _user!.city,
      );
    }

    _refreshSmartTip();
    notifyListeners();

    // Sync to backend and refresh user from server response
    ApiService.logActivity(title, category.name, co2Kg, isSaving).then((saved) {
      final idx = _activities.indexWhere((a) => a.id == tempId);
      if (idx != -1) {
        _activities[idx] = saved;
      }
      // Re-fetch the user so coins/streak/total reflect backend computation
      ApiService.getMe().then((updatedUser) {
        _user = updatedUser;
        notifyListeners();
      }).catchError((_) {});
    }).catchError((_) {});

    if (apiCategory != null && apiType != null) {
      CarbonApi.logActivity(
        userId: _user?.id ?? '',
        category: apiCategory,
        type: apiType,
        value: apiValue ?? co2Kg,
      ).then((result) {
        if (result != null) {
          _backendOnline = true;
          _lastSuggestions = result.suggestions;
          final idx = _activities.indexWhere((a) => a.id == tempId);
          if (idx != -1 && (result.carbonKg - co2Kg).abs() > 0.001) {
            _activities[idx] = ActivityModel(
              id: activity.id,
              title: activity.title,
              category: activity.category,
              co2Kg: result.carbonKg,
              isSaving: result.carbonKg == 0,
              timestamp: activity.timestamp,
              analogy: EmissionFactors.analogy(result.carbonKg),
            );
          }
          notifyListeners();
        }
      });
    }
  }

  Future<bool> buyItem(String itemId) async {
    final idx = _shopItems.indexWhere((i) => i.id == itemId);
    if (idx == -1) return false;
    final item = _shopItems[idx];
    if (item.purchased) return false;
    if ((_user?.greenCoins ?? 0) < item.cost) return false;

    try {
      await ApiService.buyHouseItem(itemId);
    } catch (_) {
      return false;
    }

    _shopItems[idx] = _shopItems[idx].copyWith(purchased: true);
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        avatarInitials: _user!.avatarInitials,
        greenCoins: _user!.greenCoins - item.cost,
        totalCo2Saved: _user!.totalCo2Saved,
        streakDays: _user!.streakDays,
        rank: _user!.rank,
        city: _user!.city,
      );
    }
    notifyListeners();
    return true;
  }

  void updateProfile({String? name, String? city}) {
    if (_user == null) return;
    _user = UserModel(
      id: _user!.id,
      name: name ?? _user!.name,
      avatarInitials: name != null
          ? name.trim().split(' ').where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase()).take(2).join()
          : _user!.avatarInitials,
      greenCoins: _user!.greenCoins,
      totalCo2Saved: _user!.totalCo2Saved,
      streakDays: _user!.streakDays,
      rank: _user!.rank,
      city: city ?? _user!.city,
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
    if ((_user?.streakDays ?? 0) >= 7) badges.add(BadgeInfo('🔥', '${_user!.streakDays} Day Streak'));
    if (_activities.any((a) => a.category == ActivityCategory.food && a.co2Kg <= 0.5)) {
      badges.add(const BadgeInfo('🥗', 'Plant-based'));
    }
    if (_activities.length >= 10) badges.add(const BadgeInfo('⭐', 'Logger Pro'));
    if (purchased.length >= 3) badges.add(const BadgeInfo('🏡', 'Home Builder'));
    return badges;
  }

  Map<String, dynamic> get wrappedStats {
    final saved = _user?.totalCo2Saved ?? 0.0;
    final trees = (saved / 7.3).round();
    final cats = <ActivityCategory, int>{};
    for (final a in _activities) {
      cats[a.category] = (cats[a.category] ?? 0) + 1;
    }
    final topCat = cats.isEmpty
        ? 'Transport'
        : cats.entries.reduce((a, b) => a.value >= b.value ? a : b).key.name;

    // Best week: find the week index with highest total from _weekly
    final bestWeekTotal = _weekly.isEmpty ? 0.0 : _weekly.reduce((a, b) => a > b ? a : b);

    return {
      'co2_saved': saved,
      'trees_equivalent': trees,
      'top_category': topCat[0].toUpperCase() + topCat.substring(1),
      'best_week': '${bestWeekTotal.toStringAsFixed(1)} kg',
      'percentile': 82,
      'activities_logged': _activities.length,
      'green_coins_earned': (_user?.greenCoins ?? 0).toInt(),
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
