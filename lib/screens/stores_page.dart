import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/store_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../models/shop_model.dart';
import '../models/shop_provider.dart';
import '../models/providers.dart';
import 'api_shop_details_page.dart';
import 'notifications_page.dart';
import 'search_page.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShops();
    });
  }

  void _loadShops({bool force = false}) {
    final loc = context.read<LocationProvider>();
    context.read<ShopProvider>().fetchAllShops(
      force: force,
      lat: loc.latitude,
      lng: loc.longitude,
    );
  }

  List<String> _buildCategories(List<Shop> shops) {
    final cats = shops
        .expand((s) => s.categories)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  List<Shop> _filteredShops(List<Shop> shops, List<String> categories) {
    return shops.where((shop) {
      final matchCategory = _selectedIndex == 0 ||
          (categories.length > _selectedIndex &&
              shop.categories.contains(categories[_selectedIndex]));
      final matchSearch = _searchQuery.isEmpty ||
          shop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          shop.displayAddress.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

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
          _buildWhiteHeader(),
          _buildResultsRow(),
          Expanded(child: _buildStoresList()),
        ],
      ),
    );
  }

  Widget _buildWhiteHeader() {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.md, AppTheme.xl, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Shops',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Consumer<ShopProvider>(
                        builder: (_, sp, __) => Text(
                          sp.hasShops
                              ? '${sp.shops.length} shop${sp.shops.length != 1 ? 's' : ''} connected'
                              : 'Manage your shops',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Icon(LucideIcons.bell, color: AppTheme.textPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildZeptoSearchBar(),
            Consumer<ShopProvider>(
              builder: (_, sp, __) {
                final categories = _buildCategories(sp.shops);
                if (categories.length <= 1) return const SizedBox(height: AppTheme.md);
                return _buildZeptoCategories(categories);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeptoSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.veryLightGray.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(LucideIcons.search, size: 18, color: AppTheme.textTertiary),
            const SizedBox(width: 10),
            Text(
              'Search for products...',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'all': return LucideIcons.layoutGrid;
      case 'fresh': return LucideIcons.leaf;
      case 'electronics': return LucideIcons.cpu;
      case 'fashion': return LucideIcons.shirt;
      case 'bakery': return LucideIcons.cake;
      case 'grocery': return LucideIcons.shoppingBag;
      case 'pharmacy': return LucideIcons.cross;
      default: return LucideIcons.box;
    }
  }

  Widget _buildZeptoCategories(List<String> categories) {
    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.bgSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(cat),
                      size: 20,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsRow() {
    return Consumer<ShopProvider>(
      builder: (_, sp, __) {
        final categories = _buildCategories(sp.shops);
        final count = _filteredShops(sp.shops, categories).length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.xl, AppTheme.md, AppTheme.xl, 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sp.isLoading
                    ? 'Loading shops...'
                    : '$count shop${count != 1 ? 's' : ''} found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (sp.hasShops)
                Row(
                  children: [
                    const Icon(LucideIcons.listFilter,
                        size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Live Data',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoresList() {
    return Consumer<ShopProvider>(
      builder: (context, sp, _) {
        if (sp.isLoading) return _buildShimmer();
        if (sp.error != null) return _buildError(sp);

        final categories = _buildCategories(sp.shops);
        final shops = _filteredShops(sp.shops, categories);

        if (shops.isEmpty) return _buildEmpty(sp);
        return _buildList(shops);
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.xl),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: AppTheme.errorRed, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load shops',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                sp.error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadShops(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
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
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.store,
                size: 36,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No shops match your search'
                  : 'No shops found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create a shop to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!sp.hasFetched) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _loadShops(force: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Load Shops'),
              ),
            ],
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildList(List<Shop> shops) {
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () async => _loadShops(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.xl),
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return FadeInUp(
            delay: Duration(milliseconds: 80 * index),
            child: StoreCard(
              name: shop.name,
              imageUrl: shop.bannerUrl ??
                  shop.logoUrl ??
                  'https://placehold.co/400x200/1D4ED8/FFFFFF?text=${Uri.encodeComponent(shop.name)}',
              shopId: shop.id,
              time: shop.hasDelivery ? 'Delivery' : 'Pickup',
              distance: shop.distance != null 
                  ? '${shop.distance!.toStringAsFixed(1)} km'
                  : (shop.displayAddress.isNotEmpty
                      ? shop.displayAddress.split(',').first
                      : shop.city),
              categories: shop.categories.isNotEmpty
                  ? shop.categories
                  : ['General'],
              isOpen: shop.visibleOnline,
              isVerified: true,
              heroTag: 'shop-${shop.id}',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) =>
                        ApiShopDetailsPage(shop: shop),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: AppDurations.normal,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
