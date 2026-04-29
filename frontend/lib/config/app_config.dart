import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-level configuration. Values are loaded from the `.env` file at startup.
/// See `main.dart` where `dotenv.load()` is called.
class AppConfig {
  AppConfig._();

  /// Electricity Maps API key — loaded from .env
  /// Get a free key at: https://api-portal.electricitymaps.com
  static String get electricityMapsApiKey =>
      dotenv.env['ELECTRICITY_MAPS_API_KEY'] ?? '';
}

