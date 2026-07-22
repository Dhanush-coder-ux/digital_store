// lib/screens/search_page.dart
//
// Global search page for products and shops.
// Features debounced search, recent history, and tabbed results.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/auth/auth_provider.dart';
import '../models/search_provider.dart';
import '../models/providers.dart';
import '../core/widgets/empty_state.dart';
import '../theme/app_theme.dart';
import 'api_shop_details_page.dart';
import 'api_product_detail_page.dart';
import '../models/shop_provider.dart';
import '../models/shop_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode.requestFocus();

    // Load search history
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<SearchProvider>().loadSearchHistory(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final userId = context.read<AuthProvider>().userId;
    context.read<SearchProvider>().search(query, userId: userId);
  }

  void _onRecentTap(String term) {
    _searchController.text = term;
    _onSearchChanged(term);
  }

  Future<void> _onRefresh() async {
    final search = context.read<SearchProvider>();
    final userId = context.read<AuthProvider>().userId;
    if (search.query.isEmpty && userId != null) {
      await search.loadSearchHistory(userId);
    } else {
      await search.executeSearchNow(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            _buildSearchBarRow(),
            Divider(height: 1, color: AppTheme.veryLightGray),
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, search, _) {
                  if (search.query.isEmpty) {
                    return _buildPopularSearches(search);
                  }
                  if (search.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                        strokeWidth: 2.5,
                      ),
                    );
                  }
                  if (!search.hasResults) {
                    return EmptyStateWidget.noSearchResults();
                  }
                  return _buildResults(search);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppTheme.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivering to',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<LocationProvider>(
                        builder: (context, locationProvider, child) {
                          return Text(
                            locationProvider.currentAddressName,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textPrimary.withOpacity(0.6)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.veryLightGray),
                ),
                child: const Icon(LucideIcons.bell, color: AppTheme.textPrimary, size: 18),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.textTertiary.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search stores, categories or items...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SearchProvider>().clearResults();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearches(SearchProvider search) {
    final popular = ['Homemade soap', 'Birthday cake', 'Fresh juice', 'Organic groceries', 'Madurai sweets'];
    
    return Container(
      width: double.infinity,
      color: AppTheme.bgPrimary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPULAR SEARCHES',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: popular.map((term) => _buildPopularChip(term)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularChip(String text) {
    return GestureDetector(
      onTap: () => _onRecentTap(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trendingUp, size: 14, color: AppTheme.textSecondary.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(SearchProvider search) {
    return Column(
      children: [
        Container(
          color: AppTheme.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textTertiary,
            indicatorColor: AppTheme.primaryBlue,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Shops (${search.shopResults.length})'),
              Tab(text: 'Products (${search.productResults.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildShopResults(search),
              _buildProductResults(search),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopResults(SearchProvider search) {
    if (search.shopResults.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.store,
        title: 'No shops found',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: search.shopResults.length,
        itemBuilder: (context, index) {
          final shop = search.shopResults[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 50),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              color: AppTheme.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(shop.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(LucideIcons.store, color: AppTheme.primaryBlue, size: 24),
                ),
                title: Text(
                  shop.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  shop.displayAddress.isNotEmpty ? shop.displayAddress : 'Local shop',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.textTertiary),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApiShopDetailsPage(shop: shop)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductResults(SearchProvider search) {
    if (search.productResults.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.package2,
        title: 'No products found',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryBlue,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: search.productResults.length,
        itemBuilder: (context, index) {
          final product = search.productResults[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 50),
            child: GestureDetector(
              onTap: () {
                final shopList = context.read<ShopProvider>().shops;
                final foundShop = shopList.firstWhere(
                  (s) => s.id == product.shopId, 
                  orElse: () => Shop(id: product.shopId, name: 'Unknown Shop', categories: [])
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApiProductDetailPage(product: product, shop: foundShop),
                  ),
                );
              },
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppTheme.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: product.imageUrls.isNotEmpty
                                ? Image.network(product.imageUrls.first, fit: BoxFit.cover)
                                : Container(
                                    color: AppTheme.bgSecondary,
                                    child: const Icon(LucideIcons.package2, size: 32, color: AppTheme.textTertiary),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppTheme.shadowSmall,
                              ),
                              child: Text(
                                '₹${product.displayPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(LucideIcons.store, size: 12, color: AppTheme.textTertiary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Shop ID: ${product.shopId.substring(0, 4)}...',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      color: AppTheme.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
  }
}
