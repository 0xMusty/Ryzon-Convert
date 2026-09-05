import 'dart:math';
import '../../app/env.dart';

class BreetConfig {
  static const String baseUrl = 'https://api.breet.io/v1';

  static Map<String, String> get headers => {
        'x-app-id': Env.breetAppId,
        'x-app-secret': Env.breetAppSecret,
        'X-Breet-Env': Env.breetEnv,
        'Content-Type': 'application/json',
      };

  /// Calculates Ryzon revenue markup: 1% capped at ₦50.
  static double calculateMarkup(double rawNgnAmount) {
    if (rawNgnAmount <= 0) return 0.0;
    final markupRate = Env.breetMarkupPercent / 100.0;
    final calculatedMarkup = rawNgnAmount * markupRate;
    return min(calculatedMarkup, Env.breetMarkupCapNgn);
  }

  /// Calculates net payout amount credited to user after 1% (max ₦50) markup.
  static double calculateNetPayout(double rawNgnAmount) {
    final markup = calculateMarkup(rawNgnAmount);
    return max(0.0, rawNgnAmount - markup);
  }
}
