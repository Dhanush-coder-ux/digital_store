import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/store_card.dart';
import '../theme/app_theme.dart';
import '../models/shop_model.dart';
import '../models/shop_provider.dart';
import '../models/providers.dart';
import '../models/category_model.dart';
import '../widgets/category_widget.dart';
import 'api_shop_details_page.dart';
import 'search_page.dart';
import 'main_screen.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  /// Pending category selection triggered from external screens (like CategoriesPage)
  static String? pendingCategory;

  /// Programmatically switch to Stores page and filter by category
  static void selectCategory(String categoryName) {
    pendingCategory = categoryName;
    MainScreen.pageIndexNotifier.value = 2;
  }

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  void _loadShops({bool force = false}) {
    final loc = context.read<LocationProvider>();
    context.read<ShopProvider>().fetchAllShops(
      force: force, lat: loc.latitude, lng: loc.longitude,
    );
  }

  List<String> _buildCategories(List<Shop> shops) {
    final cats = shops.expand((s) => s.categories).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Shop> _filteredShops(List<Shop> shops, List<String> categories) {
    return shops.where((shop) {
      final matchCat = _selectedCategoryIndex == 0 ||
          (categories.length > _selectedCategoryIndex &&
              shop.categories.contains(categories[_selectedCategoryIndex]));
      final matchSearch = _searchQuery.isEmpty ||
          shop.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Check if an external navigation requested a specific category selection
    final pending = StoresPage.pendingCategory;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (StoresPage.pendingCategory != null && mounted) {
          final sp = context.read<ShopProvider>();
          final categories = _buildCategories(sp.shops);
          final target = StoresPage.pendingCategory!.toLowerCase().trim();
          final idx = categories.indexWhere(
            (c) => c.toLowerCase() == target || c.toLowerCase().contains(target) || target.contains(c.toLowerCase()),
          );
          if (idx != -1) {
            setState(() => _selectedCategoryIndex = idx);
          }
          StoresPage.pendingCategory = null;
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, 0),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore Stores', style: Theme.of(context).textTheme.headlineSmall),
                  Consumer<ShopProvider>(
                    builder: (_, sp, __) => Text(
                      sp.hasShops ? '${sp.shops.length} stores available' : 'Find stores near you',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: AppTheme.md),
          // Search bar
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F4),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                const SizedBox(width: AppTheme.lg),
                const Icon(LucideIcons.search, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: AppTheme.sm),
                const Text('Search stores or products',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppTheme.textTertiary)),
              ]),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          // Horizontally scrollable realistic image-category row
          Consumer<ShopProvider>(
            builder: (_, sp, __) {
              final categories = _buildCategories(sp.shops);
              if (categories.length <= 1) return const SizedBox(height: AppTheme.sm);
              return SizedBox(
                height: 94,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final sel = i == _selectedCategoryIndex;
                    final item = CategoryCatalog.find(cat);
                    return CategoryRowItem(
                      item: item,
                      isSelected: sel,
                      containerSize: 56.0,
                      onTap: () => setState(() => _selectedCategoryIndex = i),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.sm),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ShopProvider>(
      builder: (context, sp, _) {
        if (sp.isLoading && sp.shops.isEmpty) return _buildShimmer();
        if (sp.error != null && sp.shops.isEmpty) return _buildError(sp);

        final categories = _buildCategories(sp.shops);
        final shops = _filteredShops(sp.shops, categories);

        if (shops.isEmpty) return _buildEmpty(sp);

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.white,
          onRefresh: () async => _loadShops(force: true),
          child: Column(children: [
            // Results count row
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, 0),
              child: Row(children: [
                Text('${shops.length} store${shops.length != 1 ? "s" : ""} found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, AppTheme.xl),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return StoreCard(
                    name: shop.name,
                    imageUrl: shop.bannerUrl ?? shop.logoUrl ?? '',
                    shopId: shop.id,
                    time: shop.hasDelivery ? 'Delivery' : 'Pickup',
                    distance: shop.distance != null
                        ? '${shop.distance!.toStringAsFixed(1)} km'
                        : (shop.displayAddress.isNotEmpty
                            ? shop.displayAddress.split(',').first.trim()
                            : shop.city),
                    categories: shop.categories.isNotEmpty ? shop.categories : ['General'],
                    isOpen: shop.visibleOnline,
                    isVerified: false,
                    heroTag: 'stores-shop-${shop.id}',
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ApiShopDetailsPage(shop: shop),
                        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgSecondary,
      highlightColor: AppTheme.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.lg),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: AppTheme.lg),
          height: 120,
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        ),
      ),
    );
  }

  Widget _buildError(ShopProvider sp) {
    return RefreshIndicator(
      onRefresh: () async => _loadShops(force: true),
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: AppTheme.errorBg, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, color: AppTheme.errorRed, size: 28),
              ),
              const SizedBox(height: AppTheme.lg),
              Text('Failed to load stores', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(sp.error ?? '', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(height: AppTheme.xl),
              ElevatedButton.icon(
                onPressed: () => _loadShops(force: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ShopProvider sp) {
    return RefreshIndicator(
      onRefresh: () async => _loadShops(force: true),
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppTheme.lightBlue, shape: BoxShape.circle),
                child: const Icon(LucideIcons.store, size: 28, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: AppTheme.lg),
              Text(_searchQuery.isNotEmpty ? 'No stores match your search' : 'No stores found',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.xs),
              Text(
                _searchQuery.isNotEmpty ? 'Try different keywords' : 'Pull down to refresh',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
