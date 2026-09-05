enum CryptoAsset {
  usdt('USDT', 'Tether USD', '₮'),
  usdc('USDC', 'USD Coin', '\$');

  final String symbol;
  final String fullName;
  final String sign;

  const CryptoAsset(this.symbol, this.fullName, this.sign);
}

enum NetworkChain {
  bsc('BSC', 'BNB Smart Chain (BEP20)', '0x...'),
  arbitrum('Arbitrum', 'Ethereum Arbitrum One', '0x...'),
  plasma('Plasma', 'Plasma Network', '0x...');

  final String name;
  final String description;
  final String addressPrefix;

  const NetworkChain(this.name, this.description, this.addressPrefix);
}

class SupportedAssets {
  SupportedAssets._();

  static const List<CryptoAsset> assets = [
    CryptoAsset.usdt,
    CryptoAsset.usdc,
  ];

  static const List<NetworkChain> networks = [
    NetworkChain.bsc,
    NetworkChain.arbitrum,
    NetworkChain.plasma,
  ];
}
