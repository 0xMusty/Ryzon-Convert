import 'package:flutter_test/flutter_test.dart';
import 'package:ryzon/core/config/breet_config.dart';

void main() {
  group('BreetConfig Markup Tests', () {
    test('Calculates 1% markup below cap correctly', () {
      const rawNgn = 2000.0; // 1% = ₦20 (< ₦50 cap)
      final markup = BreetConfig.calculateMarkup(rawNgn);
      final netPayout = BreetConfig.calculateNetPayout(rawNgn);

      expect(markup, equals(20.0));
      expect(netPayout, equals(1980.0));
    });

    test('Caps markup at ₦50 for large deposits', () {
      const rawNgn = 100000.0; // 1% = ₦1000, capped at ₦50
      final markup = BreetConfig.calculateMarkup(rawNgn);
      final netPayout = BreetConfig.calculateNetPayout(rawNgn);

      expect(markup, equals(50.0));
      expect(netPayout, equals(99950.0));
    });

    test('Returns 0 markup for zero or negative deposits', () {
      expect(BreetConfig.calculateMarkup(0.0), equals(0.0));
      expect(BreetConfig.calculateNetPayout(0.0), equals(0.0));
    });
  });
}
