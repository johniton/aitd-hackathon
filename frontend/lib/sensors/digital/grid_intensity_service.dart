import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Real-time grid carbon intensity from Electricity Maps.
class GridIntensityService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.electricitymap.org/v3';

  GridIntensityService({String apiKey = ''}) : _apiKey = apiKey;

  /// Fetches real-time carbon intensity (gCO₂e/kWh) for the current location.
  /// Falls back to 436 (global average) on failure.
  Future<double> fetchIntensity() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest,
      );

      if (_apiKey.isEmpty) {
        return _getFallbackIntensity();
      }

      final url = Uri.parse('$_baseUrl/carbon-intensity/latest?lat=${position.latitude}&lon=${position.longitude}');
      final response = await http.get(url, headers: {'auth-token': _apiKey});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['carbonIntensity'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error fetching grid intensity: $e');
    }
    return _getFallbackIntensity();
  }

  double _getFallbackIntensity() {
    // Global average carbon intensity of electricity (IEA 2023 approx).
    return 436.0;
  }
}
