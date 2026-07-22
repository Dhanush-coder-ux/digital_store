// lib/screens/favorites_page.dart
//
// Favorites page — backed by DigitalStore User API via FavoritesApiProvider.
// Shows favorited shops and products, loaded from the backend on mount.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../core/auth/auth_provider.dart';
import '../models/favorites_api_provider.dart';
import '../models/shop_provider.dart';
import '../models/product_provider.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import 'api_shop_details_page.dart';
import 'api_product_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        context.read<FavoritesApiProvider>().fetchFavorites(
          authProvider.userId!,
          force: false,
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      await context.read<FavoritesApiProvider>().fetchFavorites(
        authProvider.userId!,
        force: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
              ),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Favorites',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                AppTheme.xl, 0, AppTheme.xl, AppTheme.md,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textTertiary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSmall,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Stores'),
                  Tab(text: 'Products'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildStoresTab(context),
            _buildProductsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresTab(BuildContext context) {
    return Consumer2<FavoritesApiProvider, ShopProvider>(
      builder: (context, favorites, shopProvider, child) {
        if (favorites.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final shopIds = favorites.favoriteShopIds.toList();

        if (shopIds.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                alignment: Alignment.center,
                child: _buildEmptyState(
                  context,
                  icon: LucideIcons.store,
                  title: 'No favourite stores yet',
                  subtitle: 'Tap the heart on any store to save it here',
                ),
              ),
            ),
          );
        }

        // Get matched shops from ShopProvider cache
        final allShops = shopProvider.shops;
        final favShops = allShops
            .where((s) => shopIds.contains(s.id))
            .toList();

        // If not all shops are cached, show the raw IDs count at least
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.xl),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: shopIds.length,
            itemBuilder: (context, index) {
            final shopId = shopIds[index];
            final shop = favShops.firstWhere(
              (s) => s.id == shopId,
              orElse: () => Shop(
                id: shopId,
                name: 'Shop #${shopId.substring(0, 8)}',
                categories: [],
              ),
            );

            return FadeInUp(
              delay: Duration(milliseconds: 80 * index),
              child: _buildFavShopCard(context, shop, favorites),
            );
          },
        ),
        );
      },
    );
  }

  Widget _buildFavShopCard(BuildContext context, Shop shop, FavoritesApiProvider favorites) {
    final authProvider = context.read<AuthProvider>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ApiShopDetailsPage(shop: shop)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Shop image / icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                    ? Image.network(
                        shop.logoUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _shopIconFallback(),
                      )
                    : _shopIconFallback(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shop.categories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        shop.categories.take(2).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Remove favorite button
              GestureDetector(
                onTap: () {
                  if (authProvider.userId != null) {
                    favorites.toggleShopFavorite(authProvider.userId!, shop.id);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.errorRed,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopIconFallback() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.bgSecondary,
      child: const Icon(LucideIcons.store, color: AppTheme.textTertiary, size: 24),
    );
  }

  Widget _buildProductsTab(BuildContext context) {
    return Consumer<FavoritesApiProvider>(
      builder: (context, favorites, child) {
        if (favorites.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final productIds = favorites.favoriteProductIds.toList();

        if (productIds.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                alignment: Alignment.center,
                child: _buildEmptyState(
                  context,
                  icon: LucideIcons.heart,
                  title: 'No favourite products yet',
                  subtitle: 'Tap the heart on any product to save it here',
                ),
              ),
            ),
          );
        }

        // Get cached products from all shops via ProductProvider
        final productProvider = context.read<ProductProvider>();
        final allProducts = productProvider.allCachedProducts;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.xl),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppTheme.md,
              mainAxisSpacing: AppTheme.md,
            ),
            itemCount: productIds.length,
            itemBuilder: (context, index) {
              final productId = productIds[index];
              final product = allProducts.firstWhere(
                (p) => p.id == productId,
                orElse: () => ApiProduct(id: productId, name: 'Product', shopId: '', sellingPrice: 0),
              );

              return FadeInUp(
                delay: Duration(milliseconds: 80 * index),
                child: _buildProductCard(context, product, favorites),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ApiProduct product, FavoritesApiProvider favorites) {
    final authProvider = context.read<AuthProvider>();

    return GestureDetector(
      onTap: () {
        if (product.shopId.isNotEmpty) {
          final shopProvider = context.read<ShopProvider>();
          final shop = shopProvider.shops.firstWhere(
            (s) => s.id == product.shopId,
            orElse: () => Shop(
              id: product.shopId,
              name: 'Shop',
              categories: [],
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApiProductDetailPage(product: product, shop: shop),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl),
                    ),
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _productImageFallback(),
                          )
                        : _productImageFallback(),
                  ),
                  Positioned(
                    top: AppTheme.sm,
                    right: AppTheme.sm,
                    child: GestureDetector(
                      onTap: () {
                        if (authProvider.userId != null) {
                          favorites.toggleProductFavorite(authProvider.userId!, product.id);
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.errorRed,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.sellingPrice > 0
                        ? '\u20B9${product.sellingPrice.toStringAsFixed(0)}'
                        : (product.mrp != null && product.mrp! > 0)
                            ? '\u20B9${product.mrp!.toStringAsFixed(0)}'
                            : 'Price N/A',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productImageFallback() {
    return Container(
      color: AppTheme.bgSecondary,
      child: const Center(
        child: Icon(LucideIcons.image, color: AppTheme.textTertiary),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
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
              child: Icon(icon, size: 36, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
