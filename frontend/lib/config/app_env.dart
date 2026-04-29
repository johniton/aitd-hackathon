import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get backendBaseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get openWeatherMapApiKey =>
      dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '';
  static String get mapboxApiKey => dotenv.env['MAPBOX_API_KEY'] ?? '';
}
