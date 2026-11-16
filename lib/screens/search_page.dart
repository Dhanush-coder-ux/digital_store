// lib/screens/search_page.dart
//
// Global search page for products and shops.
// Features debounced search, recent history, tabbed results,
// product-term matched shop tagging, and resolved shop branding.
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
import 'notifications_page.dart';
import '../models/shop_provider.dart';
import '../models/shop_model.dart';
import '../models/review_provider.dart';

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
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _focusNode.requestFocus();

    // Seed shop cache with already loaded shops from ShopProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final shopList = context.read<ShopProvider>().shops;
      if (shopList.isNotEmpty) {
        context.read<SearchProvider>().seedShopCache(shopList);
      }

      // Load search history if user is logged in
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<SearchProvider>().loadSearchHistory(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (mounted) setState(() {});
    final userId = context.read<AuthProvider>().userId;
    final cachedShops = context.read<ShopProvider>().shops;
    context.read<SearchProvider>().search(
      query,
      userId: userId,
      cachedShops: cachedShops,
    );
  }

  void _onSubmitted(String query) {
    if (query.trim().isEmpty) return;
    _focusNode.unfocus();
    final userId = context.read<AuthProvider>().userId;
    final cachedShops = context.read<ShopProvider>().shops;
    context.read<SearchProvider>().executeSearchNow(
      query: query,
      userId: userId,
      cachedShops: cachedShops,
    );
  }

  void _onRecentTap(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _focusNode.unfocus();
    if (mounted) setState(() {});
    final userId = context.read<AuthProvider>().userId;
    final cachedShops = context.read<ShopProvider>().shops;
    context.read<SearchProvider>().executeSearchNow(
      query: term,
      userId: userId,
      cachedShops: cachedShops,
    );
  }

  Future<void> _onRefresh() async {
    final search = context.read<SearchProvider>();
    final userId = context.read<AuthProvider>().userId;
    final cachedShops = context.read<ShopProvider>().shops;
    if (search.query.isEmpty && userId != null) {
      await search.loadSearchHistory(userId);
    } else {
      await search.executeSearchNow(userId: userId, cachedShops: cachedShops);
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
                    return _buildEmptyQueryContent(search);
                  }
                  if (search.isSearching && !search.hasResults) {
                    return _buildSearchingState(search);
                  }
                  if (!search.isSearching && !search.hasResults) {
                    return _buildNoResultsState(search);
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue, size: 18),
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
                      const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Builder(
            builder: (context) {
              final unreadCount = context.watch<NotificationsProvider>().unreadCount;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.veryLightGray),
                      ),
                      child: const Icon(LucideIcons.bell, color: AppTheme.textSecondary, size: 18),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarRow() {
    final isFocused = _focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused ? Colors.transparent : AppTheme.border.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isFocused
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.search,
                        size: 17,
                        color: isFocused ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSubmitted,
                      textInputAction: TextInputAction.search,
                      cursorColor: AppTheme.primary,
                      cursorWidth: 2.0,
                      cursorRadius: const Radius.circular(2),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search stores, categories or items...',
                        hintStyle: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textTertiary.withValues(alpha: 0.8),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<SearchProvider>().clearResults();
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: AppTheme.bgSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.x, size: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueryContent(SearchProvider search) {
    final userId = context.read<AuthProvider>().userId;
    final recent = search.recentSearches;
    final popular = [
      'Fresh milk',
      'Birthday cake',
      'Organic groceries',
      'Homemade soap',
      'Fresh juice',
      'Madurai sweets',
      'Cotton shirts',
      'Bakery snacks',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recent Searches ───────────────────────────────────────
          if (search.isLoadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            )
          else if (recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.history, size: 14, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'RECENT SEARCHES',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => search.clearSearchHistory(userId),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent.map((entry) {
                return _buildRecentChip(entry.searchTerm, search);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── Popular Searches ──────────────────────────────────────
          const Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(
                'POPULAR SEARCHES',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: popular.map((term) => _buildPopularChip(term)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChip(String text, SearchProvider search) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onRecentTap(text),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.clock, size: 13, color: AppTheme.textTertiary),
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
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => search.removeRecentSearchLocally(text),
                  child: const Icon(LucideIcons.x, size: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ),
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
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, size: 13, color: AppTheme.primaryBlue),
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

  Widget _buildSearchingState(SearchProvider search) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching stores & products...',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Looking for "${search.query}"',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(SearchProvider search) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.searchX, size: 30, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found for "${search.query}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any stores or items. Try searching for generic items like milk, bread, cake, or groceries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                search.clearResults();
                if (mounted) setState(() {});
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 14),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
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
        if (search.isSearching)
          const LinearProgressIndicator(
            minHeight: 2.5,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        // ── Summary Banner ──────────────────────────────────────────
        _buildSummaryBanner(search),

        // ── Tabs with Counts ────────────────────────────────────────
        Container(
          color: AppTheme.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textTertiary,
            indicatorColor: AppTheme.primaryBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.store, size: 16),
                    const SizedBox(width: 8),
                    Text('Shops (${search.shopResults.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.package2, size: 16),
                    const SizedBox(width: 8),
                    Text('Products (${search.productResults.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Tab Views ───────────────────────────────────────────────
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

  Widget _buildSummaryBanner(SearchProvider search) {
    final shopCount = search.shopResults.length;
    final productCount = search.productResults.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'Found '),
                  TextSpan(
                    text: '$shopCount ${shopCount == 1 ? 'shop' : 'shops'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: '$productCount ${productCount == 1 ? 'product' : 'products'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const TextSpan(text: ' for '),
                  TextSpan(
                    text: '"${search.query}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopResults(SearchProvider search) {
    if (search.shopResults.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.store,
        title: 'No shops found',
        subtitle: 'No shops sell items matching this query.',
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
          final hasMatchedProducts = search.isShopMatchedViaProduct(shop.id);
          final matchedProductSummary = search.getMatchedProductSummary(shop.id);

          return FadeInUp(
            duration: const Duration(milliseconds: 250),
            delay: Duration(milliseconds: index * 40),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              color: AppTheme.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            shop.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              LucideIcons.store,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                          ),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      shop.displayAddress.isNotEmpty ? shop.displayAddress : 'Local shop',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Consumer<ReviewProvider>(
                      builder: (context, reviewProv, _) {
                        final provRating = reviewProv.averageRatingForShop(shop.id);
                        final provCount = reviewProv.reviewCountForShop(shop.id);
                        final rating = provCount > 0 ? provRating : (shop.rating ?? provRating);
                        final count = provCount > 0 ? provCount : (shop.reviewCount ?? provCount);
                        if (count == 0 && rating <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.star, color: Color(0xFFF59E0B), size: 13),
                              const SizedBox(width: 3),
                              Text(
                                rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '($count reviews)',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    // Product Term Matched Tag / Badge
                    if (hasMatchedProducts && matchedProductSummary != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.packageCheck,
                              size: 12,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                matchedProductSummary,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
        subtitle: 'No items match your search query.',
      );
    }

    final shopProvider = context.read<ShopProvider>();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryBlue,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: search.productResults.length,
        itemBuilder: (context, index) {
          final product = search.productResults[index];

          // Resolve real shop branding from cache or provider
          final shop = search.getShop(product.shopId) ??
              shopProvider.shops.cast<Shop?>().firstWhere(
                (s) => s?.id == product.shopId,
                orElse: () => null,
              );
          final shopName = shop?.name ?? search.getShopName(product.shopId);
          final shopLogo = shop?.logoUrl;

          return FadeInUp(
            duration: const Duration(milliseconds: 250),
            delay: Duration(milliseconds: index * 40),
            child: GestureDetector(
              onTap: () {
                final resolvedShop = shop ??
                    Shop(
                      id: product.shopId,
                      name: shopName,
                      categories: const [],
                      visibleOnline: true,
                    );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApiProductDetailPage(product: product, shop: resolvedShop),
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
                        padding: const EdgeInsets.all(10),
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
                            // Resolved Real Shop Name & Logo
                            Row(
                              children: [
                                if (shopLogo != null && shopLogo.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.network(
                                      shopLogo,
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        LucideIcons.store,
                                        size: 13,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    LucideIcons.store,
                                    size: 13,
                                    color: AppTheme.textTertiary,
                                  ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    shopName,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
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
