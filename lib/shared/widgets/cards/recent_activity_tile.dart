import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/transactions/presentation/screens/transaction_detail_screen.dart';

class RecentActivityTile extends StatefulWidget {
  final String title;
  final String date;
  final String amount;
  final String status;
  final bool isUsdt;
  final String? amountCrypto;
  final String? token;
  final String? network;
  final String? exchangeRate;
  final String? hash;
  final VoidCallback? onTap;

  const RecentActivityTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.status = 'Completed',
    this.isUsdt = true,
    this.amountCrypto,
    this.token,
    this.network,
    this.exchangeRate,
    this.hash,
    this.onTap,
  });

  @override
  State<RecentActivityTile> createState() => _RecentActivityTileState();
}

class _RecentActivityTileState extends State<RecentActivityTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded ? AppColors.primary.withValues(alpha: 0.5) : AppColors.inputBorder,
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.isUsdt ? const Color(0xFF10B981) : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        widget.isUsdt ? Icons.swap_calls_rounded : Icons.currency_exchange_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount & Status Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.amount,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Inline Details
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.inputBorder),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Crypto Amount', widget.amountCrypto ?? (widget.isUsdt ? '500.00 USDT' : '250.00 USDC')),
                  const SizedBox(height: 8),
                  _buildDetailRow('Exchange Rate', widget.exchangeRate ?? '₦1,520.00 / ${widget.isUsdt ? "USDT" : "USDC"}'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Network', widget.network ?? (widget.isUsdt ? 'BSC (BNB Smart Chain)' : 'Arbitrum One')),
                  const SizedBox(height: 8),
                  _buildDetailRow('Tx Hash', widget.hash ?? '0x8f2e91a0c441b89d2a3b1', isHash: true),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: widget.onTap ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                  title: widget.title,
                                  amountCrypto: widget.amountCrypto ?? (widget.isUsdt ? '500.00 USDT' : '250.00 USDC'),
                                  amountNaira: widget.amount,
                                  type: 'Auto-Convert',
                                  token: widget.token ?? (widget.isUsdt ? 'USDT' : 'USDC'),
                                  network: widget.network ?? (widget.isUsdt ? 'BSC (BNB Smart Chain)' : 'Arbitrum One'),
                                  exchangeRate: widget.exchangeRate ?? '₦1,520.00 / ${widget.isUsdt ? "USDT" : "USDC"}',
                                  hash: widget.hash ?? '0x8f2e91a0c441b89d2a3b1',
                                ),
                              ),
                            );
                          },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text(
                        'View Full Page Details',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHash = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          isHash && value.length > 18 ? '${value.substring(0, 10)}...${value.substring(value.length - 6)}' : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isHash ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
