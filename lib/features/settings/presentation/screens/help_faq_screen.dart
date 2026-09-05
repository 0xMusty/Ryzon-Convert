import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/auth_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'contact_support_screen.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  int _selectedFilterIndex = 0;
  int? _expandedIndex; // Closed by default
  String _searchQuery = '';
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

  final List<String> _filters = ['All', 'Account', 'Transfers', 'Security'];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Security',
      'question': 'How do I reset my password?',
      'answer':
          'You can reset your password from the login screen by tapping "Forgot password?" or in PIN & Security settings.',
    },
    {
      'category': 'Account',
      'question': 'How to link a new bank account?',
      'answer':
          'Go to your Profile tab, select "Add Bank Account", choose your bank, and enter your 10-digit account number.',
    },
    {
      'category': 'Transfers',
      'question': 'What are the transfer limits?',
      'answer':
          'Daily transfer limit is ₦5,000,000. You can request a limit increase by contacting support.',
    },
    {
      'category': 'Security',
      'question': 'How do I enable biometric login?',
      'answer':
          'Enable biometric auth from Security Settings using Face ID or Fingerprint on supported devices.',
    },
    {
      'category': 'Security',
      'question': 'Is my money safe?',
      'answer':
          'Yes! All deposits are protected and verified with CBN license & NDIC insurance standards.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showBackButton: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & FAQ',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            CustomTextField(
              focusNode: _searchFocusNode,
              hintText: 'Search for help...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _expandedIndex = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Accordion Cards
            Builder(builder: (context) {
              final selectedCategory = _filters[_selectedFilterIndex];
              final filteredFaqs = _faqs.where((faq) {
                final matchesCategory = selectedCategory == 'All' ||
                    faq['category'] == selectedCategory;
                final matchesSearch = _searchQuery.isEmpty ||
                    faq['question']!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    faq['answer']!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredFaqs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No matching FAQ articles found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(filteredFaqs.length, (index) {
                  final isExpanded = _expandedIndex == index;
                  final faq = filteredFaqs[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isExpanded
                              ? AppColors.primary
                              : AppColors.inputBorder,
                          width: isExpanded ? 1.5 : 1.0,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  faq['question']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isExpanded
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.chevron_right_rounded,
                                color: isExpanded
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            Text(
                              faq['answer']!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              );
            }),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Still need help? Our support is 24/7.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Outlined CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
