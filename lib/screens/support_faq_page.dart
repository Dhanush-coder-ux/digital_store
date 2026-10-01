import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class SupportFaqPage extends StatefulWidget {
  const SupportFaqPage({super.key});

  @override
  State<SupportFaqPage> createState() => _SupportFaqPageState();
}

class _SupportFaqPageState extends State<SupportFaqPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How can I track my order?',
      'answer': 'You can track your order by going to "My Orders" in your profile and tapping on the specific order. You will see real-time updates and live tracking once it is dispatched.'
    },
    {
      'question': 'What are the delivery hours?',
      'answer': 'Delivery hours vary by local stores. Most stores operate between 8:00 AM and 10:00 PM. Check the specific store page for exact timings.'
    },
    {
      'question': 'Can I cancel my order?',
      'answer': 'You can cancel your order within 5 minutes of placing it without any charges. Go to "My Orders", select the order, and tap "Cancel Order".'
    },
    {
      'question': 'How do refunds work?',
      'answer': 'If you cancel an order or items are unavailable, the refund will be automatically initiated to your original payment method. It usually takes 3-5 business days to reflect.'
    },
    {
      'question': 'Are there any delivery charges?',
      'answer': 'Delivery charges depend on your distance from the store and the order value. Some stores offer free delivery above a certain amount.'
    },
    {
      'question': 'How do I contact customer support?',
      'answer': 'You can reach out to our support team via email at support@digistore.com or call us at 1-800-123-4567.'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final search = _searchQuery.toLowerCase();
      return q.contains(search) || a.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Support & FAQ',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search for answers...',
                    prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.veryLightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredFaqs.isEmpty
                ? const Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.xl),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.md),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.shadowSmall,
                          border: Border.all(color: AppTheme.veryLightGray),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.sm),
                            iconColor: AppTheme.primaryBlue,
                            collapsedIconColor: AppTheme.textSecondary,
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(AppTheme.lg, 0, AppTheme.lg, AppTheme.lg),
                                child: Text(
                                  faq['answer']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
