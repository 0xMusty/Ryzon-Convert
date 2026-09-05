class AppConstants {
  AppConstants._();

  static const String appName = 'RYZON';
  static const String appTagline = 'Crypto to Naira, Instantly.';

  // Financial & Operational Limits
  static const double dailyWithdrawalLimit = 500000.0; // ₦500,000 daily limit
  static const double flatWithdrawalFee = 20.0; // ₦20 flat fee
  static const double minWithdrawalAmount = 100.0; // ₦100 minimum withdrawal

  // Timeouts & Durations
  static const int apiTimeoutSeconds = 30;
  static const int depositPollIntervalSeconds = 10;

  // Contact & Support
  static const String supportEmail = 'support@ryzon.app';
  static const String supportPhone = '+2348000000000';
}
