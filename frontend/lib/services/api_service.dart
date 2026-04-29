import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/business_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String devUserId = 'u1'; // Priya Naik

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Dev-User-Id': devUserId,
      };

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------
  static Future<UserModel> getMe() async {
    final res = await http.get(Uri.parse('$baseUrl/users/me'), headers: _headers);
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load user profile: ${res.body}');
  }

  static Future<List<UserModel>> getLeaderboard({int limit = 20}) async {
    final res = await http.get(Uri.parse('$baseUrl/leaderboard?limit=$limit'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load leaderboard: ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // ACTIVITIES
  // ---------------------------------------------------------------------------
  static Future<List<ActivityModel>> getActivities({int limit = 20, int offset = 0}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/activities?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((json) => ActivityModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load activities: ${res.body}');
  }

  static Future<ActivityModel> logActivity(String title, String category, double co2Kg, bool isSaving) async {
    final res = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'category': category,
        'co2_kg': co2Kg,
        'is_saving': isSaving,
      }),
    );
    if (res.statusCode == 200) {
      return ActivityModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to log activity: ${res.body}');
  }

  static Future<List<double>> getWeekly() async {
    final res = await http.get(Uri.parse('$baseUrl/activities/weekly'), headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<double>.from(data['days'].map((x) => (x as num).toDouble()));
    }
    throw Exception('Failed to load weekly stats: ${res.body}');
  }

  static Future<Map<String, dynamic>> getWrapped() async {
    final res = await http.get(Uri.parse('$baseUrl/activities/wrapped'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to load wrapped stats: ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // HOUSE GAME
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getHouse() async {
    final res = await http.get(Uri.parse('$baseUrl/house'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to load house: ${res.body}');
  }

  static Future<void> buyHouseItem(String itemKey) async {
    final res = await http.post(
      Uri.parse('$baseUrl/house/buy'),
      headers: _headers,
      body: jsonEncode({'item_key': itemKey}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to buy item: ${res.body}');
    }
  }

  // ---------------------------------------------------------------------------
  // BUSINESS
  // ---------------------------------------------------------------------------
  static Future<BusinessModel> getMyBusiness() async {
    final res = await http.get(Uri.parse('$baseUrl/business/my'), headers: _headers);
    if (res.statusCode == 200) {
      return BusinessModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load business profile: ${res.body}');
  }

  static Future<Map<String, dynamic>> getBenchmark() async {
    final res = await http.get(Uri.parse('$baseUrl/business/benchmark'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to load benchmarks: ${res.body}');
  }

  // ---------------------------------------------------------------------------
  // SUBSIDIES & EXCHANGE
  // ---------------------------------------------------------------------------
  static Future<List<SubsidyModel>> getSubsidies({String? sector}) async {
    final query = sector != null ? '?sector=$sector' : '';
    final res = await http.get(Uri.parse('$baseUrl/subsidies$query'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((json) => SubsidyModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load subsidies: ${res.body}');
  }

  static Future<List<ExchangeItem>> getExchangeListings() async {
    final res = await http.get(Uri.parse('$baseUrl/exchange'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((json) => ExchangeItem.fromJson(json)).toList();
    }
    throw Exception('Failed to load exchange listings: ${res.body}');
  }
}
