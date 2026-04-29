import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiSuggestion {
  final String alternative;
  final String message;
  final double estimatedSavingsKg;

  const ApiSuggestion({
    required this.alternative,
    required this.message,
    required this.estimatedSavingsKg,
  });

  factory ApiSuggestion.fromJson(Map<String, dynamic> j) => ApiSuggestion(
        alternative: j['alternative'] as String,
        message: j['message'] as String,
        estimatedSavingsKg: (j['estimated_savings_kg'] as num).toDouble(),
      );
}

class ActivityResult {
  final double carbonKg;
  final List<ApiSuggestion> suggestions;
  final double simulatedSavings;

  const ActivityResult({
    required this.carbonKg,
    required this.suggestions,
    required this.simulatedSavings,
  });
}

class DashboardResult {
  final double totalCarbon;
  final Map<String, double> breakdown;

  const DashboardResult({required this.totalCarbon, required this.breakdown});
}

class CarbonApi {
  static String get _base => '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/v1';

  static Future<ActivityResult?> logActivity({
    required String userId,
    required String category,
    required String type,
    required double value,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/activity/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'category': category,
              'type': type,
              'value': value,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return ActivityResult(
          carbonKg: (j['carbon'] as num).toDouble(),
          suggestions: (j['suggestions'] as List)
              .map((s) => ApiSuggestion.fromJson(s as Map<String, dynamic>))
              .toList(),
          simulatedSavings: (j['simulation'] as num).toDouble(),
        );
      }
    } catch (_) {
      // Backend unreachable — caller falls back to local calculation
    }
    return null;
  }

  static Future<DashboardResult?> getDashboard(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/activity/dashboard/$userId'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final breakdown = <String, double>{};
        for (final item in j['breakdown'] as List) {
          breakdown[item['category'] as String] =
              (item['total_carbon'] as num).toDouble();
        }
        return DashboardResult(
          totalCarbon: (j['total_carbon'] as num).toDouble(),
          breakdown: breakdown,
        );
      }
    } catch (_) {}
    return null;
  }

  // Map frontend category index + option to backend (category, type, value)
  static ({String category, String type, double value}) mapActivity({
    required int categoryIndex,
    required int optionIndex,
    double distanceKm = 1.0,
  }) {
    switch (categoryIndex) {
      case 0: // Transport
        const types = ['bike', 'bus', 'bus', 'car', 'bus'];
        return (category: 'transport', type: types[optionIndex], value: distanceKm);
      case 1: // Food
        const types = ['veg', 'meat', 'meat'];
        return (category: 'food', type: types[optionIndex], value: 1.0);
      case 2: // Energy
        const types = ['electricity', 'electricity', 'electricity', 'electricity'];
        const values = [1.0, 1.0, 0.1, 0.01];
        return (
          category: 'energy',
          type: types[optionIndex],
          value: values[optionIndex]
        );
      default: // Waste
        const types = ['plastic', 'plastic', 'plastic'];
        const values = [0.1, 0.5, 1.0];
        return (
          category: 'waste',
          type: types[optionIndex],
          value: values[optionIndex]
        );
    }
  }

  static String mapTransport(String mode) {
    switch (mode) {
      case 'car': return 'car';
      case 'bike': return 'bike';
      default: return 'bus';
    }
  }
}
