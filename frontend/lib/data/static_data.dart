import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/house_item_model.dart';

final currentUser = const UserModel(
  id: 'u1',
  name: 'Priya Naik',
  avatarInitials: 'PN',
  greenCoins: 840,
  totalCo2Saved: 124.5,
  streakDays: 12,
  rank: 4,
  city: 'Panaji',
);

final List<double> weeklyData = [2.1, 4.3, 1.8, 5.2, 3.6, 2.9, 4.1];

final List<ActivityModel> recentActivities = [
  ActivityModel(
    id: 'a1',
    title: 'Cycled to work',
    category: ActivityCategory.transport,
    co2Kg: 1.68,
    isSaving: true,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    analogy: '≈ 76 cashew trees absorbing for a day',
  ),
  ActivityModel(
    id: 'a2',
    title: 'Vegetarian lunch at Café Real',
    category: ActivityCategory.food,
    co2Kg: 0.5,
    isSaving: true,
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    analogy: '≈ 22 cashew trees absorbing for a day',
  ),
  ActivityModel(
    id: 'a3',
    title: 'Used AC for 4 hours',
    category: ActivityCategory.energy,
    co2Kg: 1.2,
    isSaving: false,
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    analogy: '≈ 12 hours of AC equivalent',
  ),
  ActivityModel(
    id: 'a4',
    title: 'Composted kitchen waste',
    category: ActivityCategory.waste,
    co2Kg: 0.3,
    isSaving: true,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    analogy: '≈ 14 cashew trees absorbing for a day',
  ),
  ActivityModel(
    id: 'a5',
    title: 'Auto rickshaw ride',
    category: ActivityCategory.transport,
    co2Kg: 0.95,
    isSaving: false,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    analogy: '≈ 0.1 trips by ferry Panaji–Betim',
  ),
];

final List<UserModel> leaderboard = [
  const UserModel(id: 'l1', name: 'Rahul Dessai', avatarInitials: 'RD', greenCoins: 1240, totalCo2Saved: 210.3, streakDays: 21, rank: 1, city: 'Margao'),
  const UserModel(id: 'l2', name: 'Sneha Kamat', avatarInitials: 'SK', greenCoins: 1105, totalCo2Saved: 188.7, streakDays: 18, rank: 2, city: 'Mapusa'),
  const UserModel(id: 'l3', name: 'Dev Borkar', avatarInitials: 'DB', greenCoins: 980, totalCo2Saved: 165.2, streakDays: 15, rank: 3, city: 'Vasco'),
  const UserModel(id: 'u1', name: 'Priya Naik', avatarInitials: 'PN', greenCoins: 840, totalCo2Saved: 124.5, streakDays: 12, rank: 4, city: 'Panaji'),
  const UserModel(id: 'l5', name: 'Amit Gaonkar', avatarInitials: 'AG', greenCoins: 720, totalCo2Saved: 98.1, streakDays: 9, rank: 5, city: 'Ponda'),
  const UserModel(id: 'l6', name: 'Meera Shirodkar', avatarInitials: 'MS', greenCoins: 610, totalCo2Saved: 87.4, streakDays: 7, rank: 6, city: 'Panaji'),
  const UserModel(id: 'l7', name: 'Kiran Naik', avatarInitials: 'KN', greenCoins: 540, totalCo2Saved: 72.0, streakDays: 5, rank: 7, city: 'Calangute'),
  const UserModel(id: 'l8', name: 'Tara Figueiredo', avatarInitials: 'TF', greenCoins: 420, totalCo2Saved: 60.3, streakDays: 4, rank: 8, city: 'Colva'),
];

final List<HouseItemModel> shopItems = [
  const HouseItemModel(id: 'h1', name: 'Solar Roof', icon: '☀️', cost: 200, description: '-30% energy emissions'),
  const HouseItemModel(id: 'h2', name: 'Rain Garden', icon: '🌿', cost: 150, description: 'Absorbs 5kg CO₂/month'),
  const HouseItemModel(id: 'h3', name: 'EV Charger', icon: '⚡', cost: 300, description: 'Unlock EV transport logging'),
  const HouseItemModel(id: 'h4', name: 'Rainwater Tank', icon: '💧', cost: 180, description: 'Save 500L water/month'),
  const HouseItemModel(id: 'h5', name: 'Compost Bin', icon: '♻️', cost: 80, description: 'Double waste points', purchased: true),
  const HouseItemModel(id: 'h6', name: 'Terrace Farm', icon: '🥦', cost: 220, description: 'Grow your own food'),
];

final List<BusinessModel> businessProfiles = [
  BusinessModel(
    id: 'b1',
    name: "Rodrigues Beach Shack",
    sector: BusinessSector.tourism,
    emissionsKg: 420,
    peerAvgKg: 580,
    suggestions: ['Switch to LED lighting', 'Install solar water heater', 'Use biodegradable packaging'],
    earnedBadges: ['Low Carbon Star', 'Green Vendor'],
  ),
  BusinessModel(
    id: 'b2',
    name: 'Naik Cashew Factory',
    sector: BusinessSector.cashew,
    emissionsKg: 1240,
    peerAvgKg: 980,
    suggestions: ['Optimise roasting schedule', 'Switch to biomass fuel', 'Install dust collectors'],
    earnedBadges: ['Quality Processor'],
  ),
];

final List<SubsidyModel> subsidies = [
  const SubsidyModel(
    title: 'Goa Solar Mission',
    description: '30% subsidy on rooftop solar for SMEs',
    amount: '₹1,20,000',
    deadline: 'June 2026',
    isEligible: true,
  ),
  const SubsidyModel(
    title: 'Green Tourism Grant',
    description: 'For beach shacks adopting zero-waste practices',
    amount: '₹50,000',
    deadline: 'March 2026',
    isEligible: true,
  ),
  const SubsidyModel(
    title: 'Biogas Plant Subsidy',
    description: 'MNRE scheme for organic waste processors',
    amount: '₹80,000',
    deadline: 'December 2025',
    isEligible: false,
  ),
];

final List<ExchangeItem> exchangeItems = [
  const ExchangeItem(id: 'e1', title: 'Surplus cashew husks', offeredBy: 'Naik Cashew', sector: 'Cashew', description: 'Available monthly — good fuel for biogas'),
  const ExchangeItem(id: 'e2', title: 'Used cooking oil', offeredBy: 'Rodrigues Shack', sector: 'Tourism', description: 'Biofuel feedstock — 50L/week'),
  const ExchangeItem(id: 'e3', title: 'Organic banana leaves', offeredBy: 'Sawant Farm', sector: 'Farmer', description: 'Replace plastic plating in restaurants'),
  const ExchangeItem(id: 'e4', title: 'Day-old bread surplus', offeredBy: 'Pinto Bakery', sector: 'Bakery', description: 'Animal feed or biogas input — daily'),
];

// Wrapped stats
final wrappedStats = {
  'co2Saved': 124.5,
  'treesEquivalent': 17,
  'topCategory': 'Transport',
  'bestWeek': 'March 3–9',
  'percentile': 82,
  'activitiesLogged': 147,
  'greenCoinsEarned': 840,
};
