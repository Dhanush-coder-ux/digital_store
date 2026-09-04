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
import '../models/shop_provider.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'api_product_detail_page.dart';
import 'api_checkout_page.dart';
import 'search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_provider.dart';
import '../core/models/review_model.dart';
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
  bool _isFollowLoading = false;

  List<Map<String, dynamic>> _announcements = [];
  bool _isAnnouncementsLoading = true;
  String? _announcementsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsByShop(widget.shop.id);
      context.read<ReviewProvider>().fetchShopReviews(widget.shop.id);
      _fetchAnnouncements();
    });
  }

  Future<void> _fetchAnnouncements() async {
    if (!mounted) return;
    setState(() {
      _isAnnouncementsLoading = true;
      _announcementsError = null;
    });

    try {
      final service = context.read<ShopProvider>().service;
      final data = await service.getShopAnnouncements(widget.shop.id);
      if (mounted) {
        setState(() {
          _announcements = data;
          _isAnnouncementsLoading = false;
        });
        _checkAndShowNewAnnouncementPopup();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _announcementsError = 'Failed to load announcements';
          _isAnnouncementsLoading = false;
        });
      }
    }
  }

  Future<void> _checkAndShowNewAnnouncementPopup() async {
    if (_announcements.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList('seen_announcements') ?? [];
    
    // Find first unseen announcement
    Map<String, dynamic>? newAnn;
    for (var ann in _announcements) {
      final annId = ann['id']?.toString() ?? ann.hashCode.toString();
      if (!seenIds.contains(annId)) {
        newAnn = ann;
        break;
      }
    }

    if (newAnn != null && mounted) {
      final annId = newAnn['id']?.toString() ?? newAnn.hashCode.toString();
      seenIds.add(annId);
      await prefs.setStringList('seen_announcements', seenIds);
      
      final msg = newAnn['message']?.toString() ?? '';
      final type = newAnn['type']?.toString() ?? 'OFFER';
      final cta = newAnn['call_to_action']?.toString();

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.megaphone, color: Colors.deepOrange, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'New Shop $type',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (cta != null && cta.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          cta,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontFamily: 'Outfit', color: Colors.black54),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ProductProvider>().fetchProductsByShop(widget.shop.id, force: true),
      context.read<ReviewProvider>().fetchShopReviews(widget.shop.id, force: true),
      _fetchAnnouncements(),
    ]);
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
            if (widget.shop.deliveryOptions.isNotEmpty) _buildDeliveryInformationSection(),
            _buildAnnouncementsSection(),
            _buildProductsSection(),
            _buildReviewsSection(),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFav ? Colors.grey[200] : AppTheme.primaryBlue,
                      foregroundColor: isFav ? Colors.black87 : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (_isFollowLoading) return;
                      if (auth.userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to follow shops'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      setState(() => _isFollowLoading = true);
                      
                      await favorites.toggleShopFavorite(auth.userId!, widget.shop.id);
                      
                      if (mounted) {
                        setState(() => _isFollowLoading = false);
                        if (favorites.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(favorites.error!),
                              backgroundColor: AppTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          favorites.clearError();
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isFollowLoading) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isFav ? Colors.black54 : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          isFav ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
              widget.shop.description?.isNotEmpty == true
                  ? widget.shop.description!
                  : 'No description available.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Colors.black.withOpacity(0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Rating
            Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                final rating = reviewProvider.averageRatingForShop(widget.shop.id);
                final count = reviewProvider.reviewCountForShop(widget.shop.id);
                if (count == 0) return const SizedBox.shrink();
                return Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count reviews)',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
  // ── Delivery Information Section ───────────────────────────────────

  Widget _buildDeliveryInformationSection() {
    final opts = widget.shop.deliveryOptions;
    if (opts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // We take the first delivery option as primary for display
    final opt = opts.first;
    final type = opt['type']?.toString() ?? 'DELIVERY';
    final speed = opt['speed']?.toString() ?? 'Standard';
    final freeAmt = opt['free_shipping_amount']?.toString() ?? '0.0';
    final partner = opt['delivery_by']?.toString() ?? 'STORE';

    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.truck, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Delivery Information',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDeliveryDetail(LucideIcons.clock, 'Speed', speed),
                  _buildDeliveryDetail(LucideIcons.package, 'Type', type),
                  _buildDeliveryDetail(LucideIcons.user, 'By', partner),
                ],
              ),
              if (double.tryParse(freeAmt) != null && double.parse(freeAmt) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Free shipping on orders over ₹$freeAmt',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Announcements Section ──────────────────────────────────────────

  Widget _buildAnnouncementsSection() {
    if (_isAnnouncementsLoading) {
      return SliverToBoxAdapter(
        child: Container(
          color: AppTheme.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (_announcementsError != null) {
      return SliverToBoxAdapter(
        child: Container(
          color: AppTheme.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: AppTheme.errorRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _announcementsError!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _fetchAnnouncements,
                  child: const Text('Retry', style: TextStyle(fontFamily: 'Outfit')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: AppTheme.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop Announcements',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: const Text(
                  'No announcements at this time.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shop Announcements',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140, // fixed height for carousel
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _announcements.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final ann = _announcements[index];
                  final msg = ann['message']?.toString() ?? '';
                  final cta = ann['call_to_action']?.toString();
                  final type = ann['type']?.toString() ?? 'OFFER';
                  
                  return Container(
                    width: 280, // fixed width for cards in carousel
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.megaphone, color: Colors.deepOrange, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Text(
                            msg,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (cta != null && cta.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            cta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReviewsSection() {
    return Consumer2<ReviewProvider, AuthProvider>(
      builder: (context, reviewProvider, authProvider, child) {
        final isLoading = reviewProvider.isLoadingShop(widget.shop.id);
        final reviews = reviewProvider.reviewsForShop(widget.shop.id);
        final avgRating = reviewProvider.averageRatingForShop(widget.shop.id);
        final reviewCount = reviewProvider.reviewCountForShop(widget.shop.id);
        
        final userId = authProvider.userId;
        final hasReviewed = userId != null && reviews.any((r) => r.userId == userId);

        if (isLoading && reviews.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Container(
            color: AppTheme.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ratings & Reviews',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (reviewCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${avgRating.toStringAsFixed(1)} out of 5',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' ($reviewCount)',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'No reviews yet.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                    if (userId != null && !hasReviewed)
                      TextButton(
                        onPressed: _showReviewModal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Write a Review',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (reviews.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final r = reviews[index];
                        return Container(
                          width: 280,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < r.rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const Spacer(),
                                  if (r.timestamp != null)
                                    Text(
                                      '${r.timestamp!.day}/${r.timestamp!.month}/${r.timestamp!.year}',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12,
                                        color: Colors.black38,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  r.reviewText?.isNotEmpty == true
                                      ? r.reviewText!
                                      : 'No written review provided.',
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color: r.reviewText?.isNotEmpty == true
                                        ? AppTheme.textPrimary
                                        : Colors.black38,
                                    fontStyle: r.reviewText?.isNotEmpty == true
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewModal() {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    double rating = 5.0;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Write a Review',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rating',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setModalState(() {
                              rating = index + 1.0;
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Review (Optional)',
                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this shop...',
                        hintStyle: const TextStyle(fontFamily: 'Outfit', color: Colors.black38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          final isSubmitting = reviewProvider.isSubmitting;
                          return ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final review = ShopReview(
                                      userId: userId,
                                      shopId: widget.shop.id,
                                      rating: rating,
                                      reviewText: textController.text.trim().isEmpty ? null : textController.text.trim(),
                                    );
                                    
                                    final success = await reviewProvider.submitReview(review);
                                    if (success && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Review submitted successfully!')),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(reviewProvider.error ?? 'Failed to submit review')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Submit Review',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                  if (product.hasVariant && product.variants.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${product.variants.length} Options',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
                              '₹${product.displayPrice.toStringAsFixed(product.displayPrice.truncateToDouble() == product.displayPrice ? 0 : 2)}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            if (product.hasVariant && product.variants.isNotEmpty)
                              Text(
                                '${product.variants.length} variants',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textTertiary,
                                ),
                              )
                            else if (product.unit != null)
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
                    CartSessionItem? item;
                    for (final i in cart.items) {
                      if (i.productId == product.id) {
                        item = i;
                        break;
                      }
                    }
                    if (item != null) {
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
