class BreetAssetModel {
  final String id;
  final String name;
  final String symbol;
  final String network;
  final double minimumDeposit;
  final bool isDepositEnabled;

  BreetAssetModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.network,
    required this.minimumDeposit,
    required this.isDepositEnabled,
  });

  factory BreetAssetModel.fromJson(Map<String, dynamic> json) {
    return BreetAssetModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? json['coin'] ?? '',
      network: json['network'] ?? json['chain'] ?? '',
      minimumDeposit: (json['minDeposit'] ?? json['minimumAmount'] ?? 0).toDouble(),
      isDepositEnabled: json['isDepositEnabled'] ?? json['status'] == 'active',
    );
  }
}
