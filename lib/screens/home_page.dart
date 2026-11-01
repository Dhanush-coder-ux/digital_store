import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/providers.dart';
import '../models/shop_provider.dart';
import '../models/shop_model.dart';
import '../models/profile_provider.dart';
import '../core/auth/auth_provider.dart';
import '../widgets/store_card.dart';
import '../widgets/location_bottom_sheet.dart';
import 'api_shop_details_page.dart';
import 'search_page.dart';
import 'notifications_page.dart';
import 'main_screen.dart';
import '../models/category_model.dart';
import '../widgets/category_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedLocationFilter = 2; // 0=Near, 1=City, 2=Nationwide
  int _selectedCategory = 0;

  Future<void> _onRefresh() async {
    final loc = context.read<LocationProvider>();
    await context.read<ShopProvider>().fetchAllShops(
      force: true,
      lat: loc.latitude,
      lng: loc.longitude,
    );
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.userId != null) {
      await context.read<ProfileProvider>().fetchProfile(auth.userId!, force: true);
    }
  }

  void _openLocationSheet() {
    LocationBottomSheet.show(context);
  }

  void _setDeliveryScope(int index) {
    setState(() => _selectedLocationFilter = index);
    const types = ['INSTANT', 'STANDARD', 'NATIONWIDE'];
    final loc = context.read<LocationProvider>();
    context.read<ShopProvider>().setDeliveryType(
      types[index], lat: loc.latitude, lng: loc.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primary,
        backgroundColor: AppTheme.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          slivers: [
            // ── Header (Theme Brand Color) ───────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Content ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.lg),
                  _buildDiscoveryScope(),
                  const SizedBox(height: AppTheme.xxl),
                  _buildCategoryRow(),
                  const SizedBox(height: AppTheme.xxl),
                  _buildStoresHeader(),
                  const SizedBox(height: AppTheme.md),
                  _buildStoresList(),
                  const SizedBox(height: AppTheme.xxxl + 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Header — Warm Tangerine theme background with high contrast
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF493629).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.md, AppTheme.lg, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 3),
                        _buildLocationSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  _buildNotificationButton(),
                ],
              ),
              const SizedBox(height: AppTheme.md),
              _buildSearchBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final auth = context.watch<AuthProvider>();
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
        final name = profile.userName.isNotEmpty
            ? profile.userName.split(' ').first
            : (auth.isAuthenticated ? '' : 'Guest');
        return Text(
          name.isNotEmpty ? '$greeting, $name 👋' : '$greeting 👋',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 0.2,
          ),
        );
      },
    );
  }

  Widget _buildLocationSelector() {
    return Consumer<LocationProvider>(
      builder: (context, loc, _) {
        final label = _buildLocationLabel(loc);
        return GestureDetector(
          onTap: _openLocationSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.mapPin, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
            ],
          ),
        );
      },
    );
  }

  String _buildLocationLabel(LocationProvider loc) {
    final full = loc.fullAddressName;
    if (full.isEmpty || full == 'Locating...' || full.startsWith('Location')) {
      return loc.currentAddressName.isNotEmpty ? loc.currentAddressName : 'Set delivery location';
    }
    // Show a compact label: locality or first non-empty segment
    final parts = full.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first;
    // Return first 2 parts max
    return parts.take(2).join(', ');
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        ),
        child: const Icon(LucideIcons.bell, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(LucideIcons.search, size: 17, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Search stores, categories or items...',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Discovery scope — compact chip row
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDiscoveryScope() {
    final labels = ['Near you', 'Across city', 'Nationwide'];
    final icons  = [LucideIcons.mapPin, LucideIcons.building2, LucideIcons.globe];

    return Row(children: List.generate(3, (i) {
      final sel = _selectedLocationFilter == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setDeliveryScope(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i < 2 ? AppTheme.sm : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppTheme.softPeach : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: sel ? AppTheme.primary : AppTheme.border,
                width: sel ? 1.5 : 1.0,
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icons[i], size: 13,
                color: sel ? AppTheme.primary : AppTheme.secondaryText),
              const SizedBox(width: 5),
              Text(labels[i],
                style: TextStyle(
                  fontFamily: 'Outfit', fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? AppTheme.primaryDark : AppTheme.secondaryText,
                )),
            ]),
          ),
        ),
      );
    }));
  }

  // ─────────────────────────────────────────────────────────────────
  // Categories row
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return Consumer<ShopProvider>(
      builder: (context, sp, _) {
        final dynamicCats = sp.shops
            .expand((s) => s.categories)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        final categories = CategoryCatalog.getHomeCategories(dynamicCats);

        if (_selectedCategory >= categories.length) {
          _selectedCategory = 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Categories', style: Theme.of(context).textTheme.titleMedium),
              GestureDetector(
                onTap: () => MainScreen.pageIndexNotifier.value = 1,
                child: Text('See all',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: AppTheme.md),
            SizedBox(
              height: 98,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final item = categories[i];
                  final sel = _selectedCategory == i;
                  return CategoryRowItem(
                    item: item,
                    isSelected: sel,
                    onTap: () => setState(() => _selectedCategory = i),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Stores section header
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStoresHeader() {
    return Consumer<ShopProvider>(
      builder: (_, sp, __) {
        final count = sp.shops.length;
        return Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nearby Stores', style: Theme.of(context).textTheme.titleMedium),
            if (count > 0)
              Text('$count store${count != 1 ? "s" : ""} available',
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          GestureDetector(
            onTap: () => MainScreen.pageIndexNotifier.value = 2,
            child: Text('See all',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ]);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Stores list — uses real ShopProvider data
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStoresList() {
    return Consumer<ShopProvider>(
      builder: (context, sp, _) {
        if (sp.isLoading && sp.shops.isEmpty) {
          return _buildShimmer();
        }
        if (sp.error != null && sp.shops.isEmpty) {
          return _buildError(sp);
        }
        if (!sp.hasFetched || sp.shops.isEmpty) {
          return _buildEmpty();
        }

        final dynamicCats = sp.shops
            .expand((s) => s.categories)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        final categories = CategoryCatalog.getHomeCategories(dynamicCats);
        final selectedItem = _selectedCategory < categories.length ? categories[_selectedCategory] : null;
        final cat = (selectedItem != null && selectedItem.id != 'all') ? selectedItem.name : '';
        final filtered = cat.isEmpty
            ? sp.shops
            : sp.shops.where((s) => s.categories.any((c) => c.toLowerCase().contains(cat.toLowerCase()))).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
            child: Center(
              child: Column(children: [
                const Icon(LucideIcons.store, color: AppTheme.textTertiary, size: 40),
                const SizedBox(height: AppTheme.sm),
                Text('No stores in this category', style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          );
        }

        return Column(
          children: filtered.map((shop) => _buildStoreCardFromShop(shop)).toList(),
        );
      },
    );
  }

  Widget _buildStoreCardFromShop(Shop shop) {
    return StoreCard(
      name: shop.name,
      imageUrl: shop.bannerUrl ?? shop.logoUrl ?? '',
      shopId: shop.id,
      time: shop.hasDelivery ? 'Delivery' : 'Pickup',
      distance: shop.distance != null
          ? '${shop.distance!.toStringAsFixed(1)} km'
          : (shop.displayAddress.isNotEmpty ? shop.displayAddress.split(',').first.trim() : shop.city),
      categories: shop.categories.isNotEmpty ? shop.categories : ['General'],
      isOpen: shop.visibleOnline,
      isVerified: false,
      heroTag: 'home-shop-${shop.id}',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApiShopDetailsPage(shop: shop)),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column(children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.lg),
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
      ))),
    );
  }

  Widget _buildError(ShopProvider sp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppTheme.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.wifi_off_rounded, color: AppTheme.errorRed, size: 26),
        ),
        const SizedBox(height: AppTheme.md),
        Text('Failed to load stores', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(sp.error ?? 'Unknown error', textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppTheme.lg),
        ElevatedButton(
          onPressed: _onRefresh,
          child: const Text('Retry'),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
      child: Column(children: [
        const Icon(LucideIcons.store, color: AppTheme.textTertiary, size: 40),
        const SizedBox(height: AppTheme.sm),
        Text('No stores found nearby', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('Try a different location or discovery scope.',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
