class BreetAddressModel {
  final String addressId;
  final String walletAddress;
  final String assetId;
  final String assetSymbol;
  final String network;
  final String label;
  final bool autoSettlement;
  final String? bankId;
  final String? accountNumber;
  final String? qrCodeUrl;

  BreetAddressModel({
    required this.addressId,
    required this.walletAddress,
    required this.assetId,
    required this.assetSymbol,
    required this.network,
    required this.label,
    required this.autoSettlement,
    this.bankId,
    this.accountNumber,
    this.qrCodeUrl,
  });

  String get address => walletAddress;

  factory BreetAddressModel.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] ?? json;
    return BreetAddressModel(
      addressId: wallet['id'] ?? wallet['_id'] ?? '',
      walletAddress: wallet['address'] ?? wallet['walletAddress'] ?? '',
      assetId: wallet['assetId'] ?? wallet['asset_id'] ?? '',
      assetSymbol: wallet['coin'] ?? wallet['symbol'] ?? '',
      network: wallet['network'] ?? wallet['chain'] ?? '',
      label: wallet['label'] ?? '',
      autoSettlement: wallet['autoSettlement'] ?? wallet['auto_settlement'] ?? false,
      bankId: wallet['bankId'],
      accountNumber: wallet['accountNumber'],
      qrCodeUrl: wallet['qrCodeUrl'] ?? wallet['qr_code'],
    );
  }
}
