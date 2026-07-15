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
import '../theme/app_theme.dart';
import 'api_product_detail_page.dart';
import 'api_checkout_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildShopInfo(),
          _buildSearchAndFilter(),
          _buildProductsSection(),
        ],
      ),
    );
  }

  // ── App Bar with Banner ────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowLeft, color: AppTheme.white, size: 20),
        ),
      ),
      actions: [
        _CartBadgeButton(shop: widget.shop),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image
            if (widget.shop.bannerUrl != null && widget.shop.bannerUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.shop.bannerUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildDefaultBanner(),
              )
            else
              _buildDefaultBanner(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 80,
          color: AppTheme.white.withOpacity(0.3),
        ),
      ),
    );
  }

  // ── Shop Info Card ─────────────────────────────────────────────────

  SliverToBoxAdapter _buildShopInfo() {
    return SliverToBoxAdapter(
      child: FadeInDown(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.veryLightGray, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.shop.logoUrl != null && widget.shop.logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.shop.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildLogoFallback(),
                      )
                    : _buildLogoFallback(),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shop.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (widget.shop.tagline != null && widget.shop.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.shop.tagline!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.shop.categories.take(3).map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      color: AppTheme.bgSecondary,
      child: Center(
        child: Text(
          widget.shop.name.isNotEmpty ? widget.shop.name[0].toUpperCase() : 'S',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  // ── Search + Category Filter ───────────────────────────────────────

  SliverToBoxAdapter _buildSearchAndFilter() {
    return SliverToBoxAdapter(
      child: Consumer<ProductProvider>(
        builder: (context, pp, _) {
          final categories = pp.categoriesForShop(widget.shop.id);
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.veryLightGray),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(LucideIcons.search, size: 18, color: AppTheme.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: AppTheme.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Category chips
              if (categories.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryBlue : AppTheme.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.veryLightGray,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppTheme.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          );
        },
      ),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: AppTheme.white, size: 20),
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
