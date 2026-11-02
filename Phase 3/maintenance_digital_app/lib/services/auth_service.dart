import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Sign in and check if the user is active
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      // 1. Authenticate with Supabase
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // 2. Check the user's active status in the database
        final profile = await _client
            .from('profiles')
            .select('is_active')
            .eq('id', response.user!.id)
            .maybeSingle();

        // 3. If they are inactive, sign them out immediately and throw a custom error
        if (profile != null && profile['is_active'] == false) {
          await _client.auth.signOut();
          throw Exception('Account Deactivated. Please contact the Admin.');
        }
      }

      return response;
    } on AuthException catch (e) {
      // Catch Supabase auth errors (e.g., invalid login credentials)
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Incorrect email or password. Please try again.');
      }
      throw Exception(e.message);
    } catch (e) {
      // Catch our custom deactivation error or other generic errors
      throw Exception(e.toString());
    }
  }

  /// Sign out current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch role from profiles table.
  static Future<String?> getCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return data?['role'] as String?;
  }

  static String? get currentUserId => _client.auth.currentUser?.id;
}