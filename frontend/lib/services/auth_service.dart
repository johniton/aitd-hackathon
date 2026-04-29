import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Current session access token (JWT) — null if not logged in.
  static String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Current user UUID from Supabase Auth.
  static String? get userId => _client.auth.currentUser?.id;

  /// Returns true if a user is currently signed in.
  static bool get isLoggedIn => _client.auth.currentUser != null;

  /// Sign in with email + password.
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Stream that fires whenever auth state changes.
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
