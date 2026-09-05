import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'add_account_details_screen.dart';

class SelectBankScreen extends StatefulWidget {
  const SelectBankScreen({super.key});

  @override
  State<SelectBankScreen> createState() => _SelectBankScreenState();
}

class _SelectBankScreenState extends State<SelectBankScreen> {
  String _searchQuery = '';
  int _selectedBankIndex = -1; // No bank selected by default
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'Access Bank',
      'fullName': 'Access Bank Plc',
      'color': const Color(0xFFE0561B),
    },
    {
      'name': 'Fidelity Bank',
      'fullName': 'Fidelity Bank Plc',
      'color': const Color(0xFF0F5298),
    },
    {
      'name': 'First Bank',
      'fullName': 'First Bank of Nigeria',
      'color': const Color(0xFF002B49),
    },
    {
      'name': 'GTBank',
      'fullName': 'Guaranty Trust Bank',
      'color': const Color(0xFFE55B13),
    },
    {
      'name': 'Kuda Bank',
      'fullName': 'Kuda Microfinance Bank',
      'color': const Color(0xFF401967),
    },
    {
      'name': 'OPay',
      'fullName': 'OPay Digital Services',
      'color': const Color(0xFF00B875),
    },
    {
      'name': 'Stanbic IBTC',
      'fullName': 'Stanbic IBTC Bank',
      'color': const Color(0xFF0033A0),
    },
    {
      'name': 'UBA',
      'fullName': 'United Bank for Africa',
      'color': const Color(0xFFD32F2F),
    },
    {
      'name': 'Wema Bank',
      'fullName': 'Wema Bank Plc',
      'color': const Color(0xFF8E24AA),
    },
    {
      'name': 'Zenith Bank',
      'fullName': 'Zenith Bank Plc',
      'color': const Color(0xFFD32F2F),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredBanks = _banks
        .where((b) => b['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return AuthBackground(
      showBackButton: true,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add Bank Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomTextField(
              focusNode: _searchFocusNode,
              hintText: 'Search bank name',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bank List Card Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.inputBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredBanks.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 64,
                  endIndent: 20,
                  color: AppColors.inputBorder,
                ),
                itemBuilder: (context, index) {
                  final bank = filteredBanks[index];
                  final isSelected = index == _selectedBankIndex;

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: bank['color'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            bank['name'].toString().substring(0, 1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        bank['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 22,
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 22,
                            ),
                      onTap: () {
                        setState(() {
                          _selectedBankIndex = index;
                        });
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => AddAccountDetailsScreen(
                              bankName: bank['name'] as String,
                              bankFullName: bank['fullName'] as String,
                              bankColor: bank['color'] as Color,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
