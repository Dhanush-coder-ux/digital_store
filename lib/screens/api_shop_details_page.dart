// lib/screens/api_shop_details_page.dart
//
// Shop detail page showing real products from the Inventory Service.
// Products are loaded lazily when the page is first opened.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/product_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/cart_session_model.dart';
import '../models/favorites_api_provider.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'api_product_detail_page.dart';
import 'api_checkout_page.dart';
import 'search_page.dart';

class ApiShopDetailsPage extends StatefulWidget {
  final Shop shop;

  const ApiShopDetailsPage({super.key, required this.shop});

  @override
  State<ApiShopDetailsPage> createState() => _ApiShopDetailsPageState();
}

class _ApiShopDetailsPageState extends State<ApiShopDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsByShop(widget.shop.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<ProductProvider>().fetchProductsByShop(widget.shop.id, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildAppBar(),
            _buildShopInfo(),
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  // ── App Bar with Banner ────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.black, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.shop.name,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      actions: [
        Consumer2<FavoritesApiProvider, AuthProvider>(
          builder: (context, favorites, auth, child) {
            final isFav = favorites.isShopFavorited(widget.shop.id);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppTheme.errorRed : Colors.black,
                size: 22,
              ),
              onPressed: () {
                if (auth.userId != null) {
                  favorites.toggleShopFavorite(auth.userId!, widget.shop.id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to save favourites'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.share2, color: Colors.black, size: 20),
          onPressed: () {},
        ),
        _CartBadgeButton(shop: widget.shop),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(138),
        child: Container(
          color: AppTheme.white,
          child: Consumer<ProductProvider>(
            builder: (context, pp, _) {
              final categories = pp.categoriesForShop(widget.shop.id);
              return Column(
                children: [
                  _buildSearchBarInAppBar(),
                  if (categories.isNotEmpty) _buildZeptoCategories(categories),
                ],
              );
            },
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.bgSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(cat),
                      size: 20,
                      color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryBlue : Colors.transparent,
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

  Widget _buildSearchBarInAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.veryLightGray.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(LucideIcons.search, size: 18, color: AppTheme.textTertiary),
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
      ),
    );
  }

  // ── Shop Info Card ─────────────────────────────────────────────────

  SliverToBoxAdapter _buildShopInfo() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.white,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Verified
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.shop.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
                // Open Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 8),
                      const SizedBox(width: 4),
                      const Text(
                        'Open',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Tagline
            Text(
              widget.shop.tagline?.isNotEmpty == true
                  ? widget.shop.tagline!
                  : 'Baked fresh every morning, with love.',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              'Small-batch home bakery in RS Puram, Coimbatore. Brownies, cookies, cakes & festive hampers — made fresh to order with real butter and good cocoa.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Colors.black.withOpacity(0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Stats Row
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const Text('4.8', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14)),
                const Text(' (127)', style: TextStyle(fontFamily: 'Outfit', color: Colors.black54, fontSize: 14)),
                _buildDivider(),
                const Icon(Icons.people_outline, color: Colors.black54, size: 18),
                const Text('1,284', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14)),
                const Text(' followers', style: TextStyle(fontFamily: 'Outfit', color: Colors.black54, fontSize: 14)),
                _buildDivider(),
                const Icon(Icons.local_shipping_outlined, color: Colors.black54, size: 18),
                const Text('Delivery in ', style: TextStyle(fontFamily: 'Outfit', color: Colors.black54, fontSize: 14)),
                const Text('2 km', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
                    label: const Text(
                      'Follow Unfollow',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call_outlined, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 14,
      color: Colors.grey.shade300,
    );
  }


  // ── Products Grid ─────────────────────────────────────────────────

  SliverPadding _buildProductsSection() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: Consumer<ProductProvider>(
        builder: (context, pp, _) {
          final isLoading = pp.isLoadingShop(widget.shop.id);
          final error = pp.errorForShop(widget.shop.id);
          final products = pp.filteredProducts(
            widget.shop.id,
            category: _selectedCategory == 'All' ? null : _selectedCategory,
            query: _searchQuery,
          );

          if (isLoading) return _buildShimmerGrid();
          if (error != null) return _buildError(error, pp);
          if (products.isEmpty) return _buildEmpty();
          return _buildGrid(products);
        },
      ),
    );
  }

  SliverGrid _buildGrid(List<ApiProduct> products) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return FadeInUp(
            delay: Duration(milliseconds: 60 * (index % 6)),
            child: _ProductCard(product: products[index], shop: widget.shop),
          );
        },
        childCount: products.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
    );
  }

  SliverFillRemaining _buildShimmerGrid() {
    return SliverFillRemaining(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildError(String error, ProductProvider pp) {
    return SliverFillRemaining(
      child: Center(
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
              child: Icon(Icons.wifi_off_rounded, color: AppTheme.errorRed, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => pp.refreshProductsByShop(widget.shop.id),
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
    );
  }

  SliverFillRemaining _buildEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: FadeIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.package, color: AppTheme.primaryBlue, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No products match your search' : 'No products yet',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'This shop hasn\'t added any products yet',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product Card ────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ApiProduct product;
  final Shop shop;

  const _ProductCard({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApiProductDetailPage(
              product: product,
              shop: shop,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.primaryImage != null
                          ? CachedNetworkImage(
                              imageUrl: product.primaryImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (_, __) => Container(color: AppTheme.bgSecondary),
                              errorWidget: (_, __, ___) => _buildImageFallback(product.name),
                            )
                          : _buildImageFallback(product.name),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer2<FavoritesApiProvider, AuthProvider>(
                      builder: (context, favorites, auth, child) {
                        final isFav = favorites.isProductFavorited(product.id);
                        return GestureDetector(
                          onTap: () {
                            if (auth.userId != null) {
                              favorites.toggleProductFavorite(auth.userId!, product.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to save favourites'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 18,
                              color: isFav ? AppTheme.errorRed : AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${product.displayPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            if (product.unit != null)
                              Text(
                                product.unit!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                          ],
                        ),
                        // Add to cart quick button
                        _QuickAddButton(product: product, shop: shop),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback(String name) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgSecondary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// ── Quick Add Button ───────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final ApiProduct product;
  final Shop shop;

  const _QuickAddButton({required this.product, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        final qty = cart.quantityOf(product.id);
        final isAdding = cart.state == CartState.adding;

        if (qty > 0) {
          return Container(
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final item = cart.items.firstWhere(
                      (i) => i.productId == product.id,
                      orElse: () => CartSessionItem(productId: '', shopId: '', qty: 0),
                    );
                    if (item.productId.isNotEmpty) {
                      await cart.updateQuantity(item, qty - 1);
                    } else {
                      await cart.removeItem(productId: product.id);
                    }
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 30,
                    child: Icon(Icons.remove_rounded, color: AppTheme.white, size: 14),
                  ),
                ),
                Text(
                  '$qty',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => cart.addItem(
                    product: product,
                    shopId: shop.id,
                  ),
                  child: const SizedBox(
                    width: 28,
                    height: 30,
                    child: Icon(Icons.add_rounded, color: AppTheme.white, size: 14),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: isAdding
              ? null
              : () => cart.addItem(product: product, shopId: shop.id),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isAdding
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Icon(Icons.add_rounded, color: AppTheme.white, size: 18),
          ),
        );
      },
    );
  }
}

// ── Cart Badge Button ──────────────────────────────────────────────

class _CartBadgeButton extends StatelessWidget {
  final Shop shop;

  const _CartBadgeButton({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApiCheckoutPage(shop: shop),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shoppingCart, color: Colors.black, size: 20),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
