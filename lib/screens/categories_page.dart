// lib/screens/categories_page.dart
//
// Blinkit & Zepto-inspired Categories Screen
// Features high-quality realistic product photography for all categories,
// responsive grid layout, instant category search, and seamless navigation to filtered stores.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../l10n/app_translations.dart';
import '../models/shop_provider.dart';
import '../models/category_model.dart';
import '../widgets/category_widget.dart';
import 'stores_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildCategoriesGrid(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, AppTheme.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('categories'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryText,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Consumer<ShopProvider>(
                        builder: (_, sp, __) {
                          final dynamicCats = sp.shops
                              .expand((s) => s.categories)
                              .where((c) => c.isNotEmpty)
                              .toSet()
                              .toList();
                          final allItems = CategoryCatalog.getAllCategories(dynamicCats);
                          return Text(
                            context.tr('categories_available', args: {'count': '${allItems.length}'}),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.softPeach,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Instant Delivery',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Input
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppTheme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_categories_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.secondaryText),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.secondaryText),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
          return _buildShimmerGrid();
        }

        final dynamicCats = sp.shops
            .expand((s) => s.categories)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        final allCategories = CategoryCatalog.getAllCategories(dynamicCats);

        final filteredCategories = _searchQuery.isEmpty
            ? allCategories
            : allCategories.where((item) {
                final q = _searchQuery.toLowerCase();
                return item.name.toLowerCase().contains(q) ||
                    (item.subtitle != null && item.subtitle!.toLowerCase().contains(q));
              }).toList();

        if (filteredCategories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.softPeach,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(LucideIcons.searchX, color: AppTheme.primary, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No category matching "$_searchQuery"',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Try searching for fruits, vegetables, dairy, or bakery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Text(
                      'Clear Search',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          onRefresh: () async {
            await sp.fetchAllShops(force: true);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600
                  ? 4
                  : (constraints.maxWidth > 340 ? 3 : 2);

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(AppTheme.md, AppTheme.md, AppTheme.md, AppTheme.xl),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.80,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final item = filteredCategories[index];
                  return CategoryGridCard(
                    item: item,
                    onTap: () {
                      // Navigate to stores page pre-filtered with this category
                      StoresPage.selectCategory(item.name);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0EBE1),
      highlightColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 0.80,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
