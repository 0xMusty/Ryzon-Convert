import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/deposit/presentation/providers/deposit_addresses_provider.dart';

class DepositAddressCard extends ConsumerStatefulWidget {
  final bool showQrInline;
  final bool isAutoSettlementEnabled;
  final VoidCallback? onQrPressed;
  final ValueChanged<int>? onNetworkChanged;

  const DepositAddressCard({
    super.key,
    this.showQrInline = false,
    this.isAutoSettlementEnabled = true,
    this.onQrPressed,
    this.onNetworkChanged,
  });

  @override
  ConsumerState<DepositAddressCard> createState() => _DepositAddressCardState();
}

class _DepositAddressCardState extends ConsumerState<DepositAddressCard> {
  int _selectedNetworkIndex = 0;

  final List<Map<String, String>> _networks = [
    {
      'label': 'BSC',
      'fullName': 'BNB Smart Chain',
      'assetId': 'USDT_BSC_TEST',
    },
    {
      'label': 'Arbitrum',
      'fullName': 'Arbitrum One',
      'assetId': 'USDC_ARB_SEPOLIA_V84S',
    },
    {
      'label': 'Plasma',
      'fullName': 'Polygon Plasma',
      'assetId': 'USD_POLYGON_TEST_MUMBAI_QFXA',
    },
  ];

  Map<String, String> get _currentNetwork => _networks[_selectedNetworkIndex];

  String _truncate(String addr) {
    if (addr.length <= 16) return addr;
    return '${addr.substring(0, 10)}...${addr.substring(addr.length - 8)}';
  }

  void _copyAddress(String fullAddress) {
    Clipboard.setData(ClipboardData(text: fullAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deposit address copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQrModal(String fullAddress, String chainName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$chainName Deposit QR Code',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: fullAddress,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              fullAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerateAddress() async {
    final net = _currentNetwork;
    final chainLabel = net['label']!;
    final assetId = net['assetId']!;

    final addr = await ref
        .read(depositAddressesProvider.notifier)
        .generateAddressForChain(
          chainLabel: chainLabel,
          assetId: assetId,
          autoSettlement: widget.isAutoSettlementEnabled,
        );

    if (addr == null && mounted) {
      final err = ref.read(depositAddressesProvider).error ?? 'Failed to generate address';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation Notice: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositState = ref.watch(depositAddressesProvider);
    final chainLabel = _currentNetwork['label']!;
    final String? fullAddress = depositState.chainAddresses[chainLabel.toUpperCase()] ??
        depositState.chainAddresses['BSC'] ??
        depositState.chainAddresses['ARBITRUM'] ??
        depositState.chainAddresses['PLASMA'];
    final bool hasAddress = fullAddress != null && fullAddress.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_networks.length, (index) {
                final isSelected = _selectedNetworkIndex == index;
                final netLabel = _networks[index]['label']!;
                final isGenerated = depositState.chainAddresses.containsKey(netLabel.toUpperCase()) ||
                    depositState.chainAddresses.containsKey('BSC') ||
                    depositState.chainAddresses.containsKey('ARBITRUM') ||
                    depositState.chainAddresses.containsKey('PLASMA');

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNetworkIndex = index;
                    });
                    if (widget.onNetworkChanged != null) {
                      widget.onNetworkChanged!(index);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          netLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        if (isGenerated) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row for compact mode
          if (!widget.showQrInline) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your Deposit Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAddress) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      // Copy Button
                      GestureDetector(
                        onTap: () => _copyAddress(fullAddress),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // QR Button
                      GestureDetector(
                        onTap: () => _showQrModal(fullAddress, _currentNetwork['fullName']!),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (depositState.isLoading)
            const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasAddress)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No $chainLabel address generated yet',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _handleGenerateAddress,
                    icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(
                      'Generate $chainLabel Deposit Address',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (widget.showQrInline) ...[
            // Inline Large QR Display mode for Deposit Screen
            Center(
              child: Column(
                children: [
                  QrImageView(
                    data: fullAddress,
                    version: QrVersions.auto,
                    size: 190.0,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    fullAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyAddress(fullAddress),
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Copy Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Compact address text mode for Home Screen
            Text(
              _truncate(fullAddress),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Automatically converts any incoming stablecoin into Naira instantly.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
