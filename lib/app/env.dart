import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Env {
  static String _getEnv(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    return dotenv.env[key] ?? fallback;
  }

  static String get apiBaseUrl => _getEnv('API_BASE_URL', 'https://api.ryzon.app/v1');
  static String get environment => _getEnv('ENVIRONMENT', 'development');
  static bool get isDev => environment == 'development';

  static String get supabaseUrl =>
      _getEnv('SUPABASE_URL', 'https://esghqmyyofjylgzveggj.supabase.co');
  static String get supabaseAnonKey =>
      _getEnv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzZ2hxbXl5b2ZqeWxnenZlZ2dqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMjU4NDYsImV4cCI6MjEwMjkwMTg0Nn0.89IV1jtXikjp4WebbbO-5o4ur7QBVp1qr28jgxPnTkQ');

  static String get breetAppId => _getEnv('BREET_APP_ID', '');
  static String get breetAppSecret => _getEnv('BREET_APP_SECRET', '');
  static String get breetEnv => _getEnv('BREET_ENV', 'sandbox');
  static double get breetMarkupPercent => double.tryParse(_getEnv('BREET_MARKUP_PERCENT', '1.0')) ?? 1.0;
  static double get breetMarkupCapNgn => double.tryParse(_getEnv('BREET_MARKUP_CAP_NGN', '50.0')) ?? 50.0;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback defaults if .env file is missing
    }

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        );
      } catch (e) {
        // Log or handle duplicate initialization gracefully
      }
    }
  }
}
