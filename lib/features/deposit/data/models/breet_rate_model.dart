import '../../../../core/config/breet_config.dart';

class BreetRateModel {
  final String assetId;
  final String currency;
  final double cryptoAmount;
  final double breetRate;
  final double rawNgnPayout;
  final double ryzonFeeNgn;
  final double netNgnPayout;

  BreetRateModel({
    required this.assetId,
    required this.currency,
    required this.cryptoAmount,
    required this.breetRate,
    required this.rawNgnPayout,
    required this.ryzonFeeNgn,
    required this.netNgnPayout,
  });

  factory BreetRateModel.fromJson(Map<String, dynamic> json, {required double amount}) {
    final rate = (json['rate'] ?? json['exchangeRate'] ?? 0).toDouble();
    final rawPayout = (json['estimatedPayout'] ?? json['payoutAmount'] ?? (amount * rate)).toDouble();
    final fee = BreetConfig.calculateMarkup(rawPayout);
    final netPayout = BreetConfig.calculateNetPayout(rawPayout);

    return BreetRateModel(
      assetId: json['assetId'] ?? '',
      currency: json['currency'] ?? 'NGN',
      cryptoAmount: amount,
      breetRate: rate,
      rawNgnPayout: rawPayout,
      ryzonFeeNgn: fee,
      netNgnPayout: netPayout,
    );
  }
}
