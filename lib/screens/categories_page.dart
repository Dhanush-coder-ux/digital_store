import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/shop_provider.dart';
import '../models/providers.dart';
import 'main_screen.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('grocer')) return LucideIcons.shoppingBag;
    if (lower.contains('bake') || lower.contains('cake') || lower.contains('pastr')) return LucideIcons.cake;
    if (lower.contains('pharm') || lower.contains('med')) return LucideIcons.cross;
    if (lower.contains('elect') || lower.contains('tech')) return LucideIcons.cpu;
    if (lower.contains('fash') || lower.contains('cloth') || lower.contains('shirt')) return LucideIcons.shirt;
    if (lower.contains('food') || lower.contains('snack')) return LucideIcons.utensils;
    if (lower.contains('veg') || lower.contains('fruit') || lower.contains('organic')) return LucideIcons.leaf;
    if (lower.contains('meat') || lower.contains('dairy')) return LucideIcons.drumstick;
    return LucideIcons.layoutGrid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(child: _buildCategoriesGrid(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.xl, AppTheme.lg, AppTheme.xl, AppTheme.lg,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Categories',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppTheme.white),
                  ),
                  Text(
                    'Browse shops by category',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, sp, _) {
        if (sp.isLoading && sp.shops.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final categories = sp.shops
            .expand((s) => s.categories)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Add some default ones if empty so it's not totally empty when no backend data
        if (categories.isEmpty) {
          categories.addAll(['Grocery', 'Bakery', 'Pharmacy', 'Electronics', 'Fashion']);
        }

        return RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            final loc = context.read<LocationProvider>();
            await sp.fetchAllShops(
              force: true,
            );
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.xl),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.md,
              mainAxisSpacing: AppTheme.md,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final icon = _getCategoryIcon(category);
              return FadeInUp(
                delay: Duration(milliseconds: 50 * (index % 10)), // Modulo to prevent long delays
                child: GestureDetector(
                  onTap: () {
                    // Navigate to stores page which is index 2
                    MainScreen.pageIndexNotifier.value = 2;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.veryLightGray),
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 28, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(height: AppTheme.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            category,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
