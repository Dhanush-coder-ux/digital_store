// lib/screens/api_product_detail_page.dart
//
// Premium Product Detail Experience — Warm, Light, Customer-Focused Mobile Shopping
//
// Design System:
// - Warm ivory canvas (#FCFAF6) & pure white surfaces (#FFFFFF)
// - Restrained amber (#D99A32) for primary actions and active selections
// - Deep warm text (#493629) & muted secondary text (#8A7664)
// - Subtle warm borders (#EDE5D8) & complementary sage green (#258A68) for stock/success
//
// Key Features:
// 1. Swipeable image gallery with natural aspect ratio, micro-indicator, and thumbnail strip.
// 2. Clear product identity, category tag, store storefront link, and star ratings.
// 3. Humanized variant attributes (e.g. "8 GB RAM" instead of "variant : ram : 8").
// 4. Clean selectable option cards with in-stock, selected, and out-of-stock states.
// 5. Delivery promise, expandable product description, return policy, and technical specs.
// 6. Sticky bottom purchase bar with integrated quantity stepper and prominent amber CTA.
// 7. Full synchronization with ApiCartProvider, FavoritesApiProvider, and ReviewProvider.
//

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../models/api_cart_provider.dart';
import '../models/favorites_api_provider.dart';
import '../models/review_provider.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_util.dart';
import 'api_checkout_page.dart';
import 'api_shop_details_page.dart';

class ApiProductDetailPage extends StatefulWidget {
  final ApiProduct product;
  final Shop shop;

  const ApiProductDetailPage({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  State<ApiProductDetailPage> createState() => _ApiProductDetailPageState();
}

class _ApiProductDetailPageState extends State<ApiProductDetailPage> {
  late final PageController _pageController;
  int _currentImageIndex = 0;
  int _qty = 1;
  String? _selectedVariantId;
  String? _selectedBatchId;
  bool _isDescriptionExpanded = false;

  // ═══════════════════════════════════════════════════════════════════
  // STATE INITIALIZATION & DISPOSAL
  // ═══════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Default select first available variant/batch
    if (widget.product.variants.isNotEmpty) {
      Map<String, dynamic>? initialVariant;
      for (final v in widget.product.variants) {
        final stock = ApiProduct.getVariantStock(v, haveTracking: widget.product.haveTracking);
        final price = ApiProduct.getVariantPrice(v);
        if (stock > 0 || price > 0) {
          initialVariant = v;
          break;
        }
      }
      initialVariant ??= widget.product.variants.first;
      _selectedVariantId = initialVariant['id']?.toString();
    }

    if (widget.product.batches.isNotEmpty) {
      Map<String, dynamic>? initialBatch;
      for (final b in widget.product.batches) {
        final bStock = b['stock_infos'] is Map ? b['stock_infos'] as Map : {};
        final qty = (bStock['available_stocks'] as num?)?.toDouble() ??
            (bStock['physical_stocks'] as num?)?.toDouble() ??
            (b['available_qty'] as num?)?.toDouble() ??
            (b['stock'] as num?)?.toDouble() ??
            0;
        if (qty > 0) {
          initialBatch = b;
          break;
        }
      }
      initialBatch ??= widget.product.batches.first;
      _selectedBatchId = initialBatch['id']?.toString();
    }

    // Refresh reviews for shop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchShopReviews(widget.shop.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMPUTED GETTERS
  // ═══════════════════════════════════════════════════════════════════

  List<String> get _images => widget.product.imageUrls;

  Map<String, dynamic>? get _selectedVariant {
    if (_selectedVariantId == null || widget.product.variants.isEmpty) return null;
    for (final v in widget.product.variants) {
      if (v['id']?.toString() == _selectedVariantId) return v;
    }
    return widget.product.variants.first;
  }

  double get _effectivePrice {
    if (_selectedVariant != null) {
      final vp = ApiProduct.getVariantPrice(_selectedVariant!);
      if (vp > 0) return vp;
    }
    return widget.product.displayPrice;
  }

  double? get _effectiveMrp {
    if (_selectedVariant != null) {
      final vPricing = _selectedVariant!['pricing_infos'] is Map ? _selectedVariant!['pricing_infos'] as Map : {};
      if (vPricing['mrp'] != null) {
        final vm = double.tryParse(vPricing['mrp'].toString());
        if (vm != null && vm > 0) return vm;
      }
    }
    return widget.product.mrp;
  }

  double get _effectiveStock {
    if (_selectedVariant != null) {
      return ApiProduct.getVariantStock(_selectedVariant!, haveTracking: widget.product.haveTracking);
    }
    if (widget.product.batches.isNotEmpty) {
      double batchStockSum = 0;
      for (final b in widget.product.batches) {
        final bStock = b['stock_infos'] is Map ? b['stock_infos'] as Map : {};
        if (bStock.containsKey('available_stocks') && bStock['available_stocks'] != null) {
          batchStockSum += (bStock['available_stocks'] as num?)?.toDouble() ?? 0;
        } else if (bStock.containsKey('physical_stocks') && bStock['physical_stocks'] != null) {
          batchStockSum += (bStock['physical_stocks'] as num?)?.toDouble() ?? 0;
        } else if (b['available_qty'] != null) {
          batchStockSum += (b['available_qty'] as num?)?.toDouble() ?? 0;
        } else if (b['stock'] != null) {
          batchStockSum += (b['stock'] as num?)?.toDouble() ?? 0;
        }
      }
      if (batchStockSum > 0) return batchStockSum;
    }
    return widget.product.availableQty;
  }

  bool get _effectiveInStock => !widget.product.haveTracking || _effectiveStock > 0;

  String? get _effectiveBatchId {
    if (_selectedBatchId != null) return _selectedBatchId;
    final v = _selectedVariant;
    if (v != null && v['batch_infos'] is List && (v['batch_infos'] as List).isNotEmpty) {
      for (final b in (v['batch_infos'] as List)) {
        if (b is Map && b['id'] != null) {
          return b['id'].toString();
        }
      }
    }
    if (widget.product.batches.isNotEmpty) {
      return widget.product.batches.first['id']?.toString();
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  // VARIANT HUMANIZER
  // ═══════════════════════════════════════════════════════════════════

  String _humanizeVariant(Map<String, dynamic> variant) {
    // 1. Check structured attributes
    if (variant['attributes'] is Map && (variant['attributes'] as Map).isNotEmpty) {
      final parts = <String>[];
      (variant['attributes'] as Map).forEach((k, val) {
        if (val != null && val.toString().trim().isNotEmpty) {
          parts.add(_formatAttribute(k.toString(), val.toString()));
        }
      });
      if (parts.isNotEmpty) return parts.join(' • ');
    }

    // 2. Check type_infos
    if (variant['type_infos'] is Map && (variant['type_infos'] as Map).isNotEmpty) {
      final parts = <String>[];
      (variant['type_infos'] as Map).forEach((k, val) {
        if (val != null && val.toString().trim().isNotEmpty) {
          parts.add(_formatAttribute(k.toString(), val.toString()));
        }
      });
      if (parts.isNotEmpty) return parts.join(' • ');
    }

    // 3. Parse raw string (e.g. "variant : ram : 8" -> "8 GB RAM")
    String raw = (variant['name'] ?? variant['title'] ?? variant['label'] ?? '').toString().trim();
    if (raw.isEmpty) return 'Standard Option';

    // Strip technical prefixes
    raw = raw.replaceAll(RegExp(r'^(variant|varient|option|item)\s*[:\-]\s*', caseSensitive: false), '');

    if (raw.contains(':')) {
      final segments = raw.split(':').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (segments.length == 2) {
        return _formatAttribute(segments[0], segments[1]);
      } else if (segments.length > 2) {
        final formatted = <String>[];
        for (int i = 0; i < segments.length - 1; i += 2) {
          formatted.add(_formatAttribute(segments[i], segments[i + 1]));
        }
        if (segments.length.isOdd) {
          formatted.add(segments.last);
        }
        return formatted.join(' • ');
      }
    }

    if (raw.contains('/')) {
      return raw.split('/').map((s) => _cleanWord(s.trim())).join(' / ');
    }

    return _cleanWord(raw);
  }

  String _formatAttribute(String key, String value) {
    final k = key.trim().toLowerCase();
    final v = value.trim();
    if (k.isEmpty) return v;
    if (v.isEmpty) return key;

    if (k == 'ram') {
      final isNum = RegExp(r'^\d+$').hasMatch(v);
      return isNum ? '$v GB RAM' : (v.toLowerCase().contains('ram') ? v.toUpperCase() : '$v RAM');
    }
    if (k == 'storage' || k == 'rom' || k == 'memory') {
      final isNum = RegExp(r'^\d+$').hasMatch(v);
      return isNum ? '$v GB Storage' : (v.toLowerCase().contains('gb') || v.toLowerCase().contains('tb') ? v.toUpperCase() : '$v Storage');
    }
    if (k == 'size') {
      return 'Size ${v.toUpperCase()}';
    }
    if (k == 'weight' || k == 'volume' || k == 'qty') {
      return v;
    }
    if (k == 'color' || k == 'colour') {
      return _cleanWord(v);
    }

    final capKey = k[0].toUpperCase() + k.substring(1);
    if (v.toLowerCase().contains(k)) return _cleanWord(v);
    return '$v $capKey';
  }

  String _cleanWord(String str) {
    if (str.isEmpty) return str;
    return str.split(' ').map((w) {
      if (w.isEmpty) return '';
      final upper = w.toUpperCase();
      if (['RAM', 'ROM', 'XL', 'XXL', 'XS', 'GB', 'TB', 'MB', 'ML', 'KG', 'GM'].contains(upper)) {
        return upper;
      }
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Scrollable Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildGalleryHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductIdentity(product),
                        if (product.variants.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildVariantSelector(product),
                        ],
                        const SizedBox(height: 16),
                        _buildFulfillmentCard(),
                        if (product.description != null && product.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDescriptionCard(product.description!.trim()),
                        ],
                        if (product.returnPolicy != null && product.returnPolicy.toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildReturnPolicyCard(product),
                        ],
                        _buildSpecificationsCard(product),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Top Floating Navigation Bar
            _buildTopActionBar(),

            // Sticky Bottom Purchase Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyPurchaseBar(product),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. PRODUCT IMAGE GALLERY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGalleryHeader() {
    final images = _images;
    final screenWidth = MediaQuery.of(context).size.width;
    final galleryHeight = screenWidth * 0.88; // Balanced 1:1.1 proportion, never overly tall

    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.white,
        child: Column(
          children: [
            SizedBox(
              height: galleryHeight,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // PageView Gallery
                  if (images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                          child: Hero(
                            tag: 'product-${widget.product.id}-$index',
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => _buildFallbackImage(),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _buildFallbackImage(),
                    ),

                  // Subtle Page Pill Indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 14,
                      right: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Thumbnail Strip for Multi-Image Products
            if (images.length > 1)
              Container(
                height: 56,
                padding: const EdgeInsets.only(bottom: 12),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isSelected = i == _currentImageIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                            width: isSelected ? 2 : 1,
                          ),
                          color: AppTheme.white,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(LucideIcons.image, size: 16, color: AppTheme.textTertiary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 1, color: AppTheme.veryLightGray),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: const Icon(LucideIcons.package2, size: 44, color: AppTheme.textTertiary),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP FLOATING ACTION BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopActionBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.veryLightGray),
                  boxShadow: AppTheme.shadowSmall,
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 18),
              ),
            ),

            // Right Actions: Storefront & Favorite
            Row(
              children: [
                // Storefront shortcut
                GestureDetector(
                  onTap: _navigateToShop,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.veryLightGray),
                      boxShadow: AppTheme.shadowSmall,
                    ),
                    child: const Icon(LucideIcons.store, color: AppTheme.textPrimary, size: 18),
                  ),
                ),

                // Favorite Button
                Consumer2<FavoritesApiProvider, AuthProvider>(
                  builder: (context, favorites, auth, _) {
                    final isFav = favorites.isProductFavorited(widget.product.id);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (auth.userId != null) {
                          favorites.toggleProductFavorite(auth.userId!, widget.product.id);
                        } else {
                          SnackbarUtil.showError(context, 'Please sign in to save favourites');
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withValues(alpha: 0.94),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.veryLightGray),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.errorRed : AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. PRODUCT IDENTITY & PRICING
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildProductIdentity(ApiProduct product) {
    final price = _effectivePrice;
    final mrp = _effectiveMrp;
    final hasDiscount = mrp != null && mrp > price;
    final discountPercent = hasDiscount ? (((mrp - price) / mrp) * 100).round() : 0;
    final inStock = _effectiveInStock;
    final stock = _effectiveStock;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Rating Row (only when available)
          Consumer<ReviewProvider>(
            builder: (context, reviews, _) {
              final rating = reviews.averageRatingForShop(widget.shop.id);
              final count = reviews.reviewCountForShop(widget.shop.id);
              final hasRating = count > 0 && rating > 0;
              final hasCategory = product.category != null && product.category!.trim().isNotEmpty;

              if (!hasRating && !hasCategory) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    if (hasCategory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.veryLightGray),
                        ),
                        child: Text(
                          product.category!.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    if (hasCategory && hasRating) const SizedBox(width: 8),
                    if (hasRating)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '($count)',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // Product Name
          Text(
            product.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Tappable Shop Identity Row
          GestureDetector(
            onTap: _navigateToShop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.veryLightGray),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.store, size: 13, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.shop.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.veryLightGray),
          const SizedBox(height: 16),

          // Price & Stock Status Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (product.unit != null && product.unit!.trim().isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '/ ${product.unit}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '₹${mrp.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Stock Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: inStock ? AppTheme.successBg : AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: inStock
                        ? AppTheme.successGreen.withValues(alpha: 0.25)
                        : AppTheme.errorRed.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      inStock ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                      size: 13,
                      color: inStock ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      !inStock
                          ? 'Out of Stock'
                          : (product.haveTracking && stock > 0 && stock <= 5
                              ? 'Only ${stock.toStringAsFixed(0)} left'
                              : 'In Stock'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: inStock ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. VARIANT & OPTION SELECTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildVariantSelector(ApiProduct product) {
    final variants = product.variants;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Option',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${variants.length} available',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clean selectable option cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variants.map((v) {
              final id = v['id']?.toString();
              final isSelected = _selectedVariantId == id;
              final humanLabel = _humanizeVariant(v);
              final vPrice = ApiProduct.getVariantPrice(v);
              final vStock = ApiProduct.getVariantStock(v, haveTracking: product.haveTracking);
              final hasStock = !product.haveTracking || vStock > 0;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedVariantId = id;
                    _qty = 1;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.skyBlue
                        : (hasStock ? AppTheme.white : AppTheme.bgSecondary),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : (hasStock ? AppTheme.veryLightGray : AppTheme.bgTertiary),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected ? AppTheme.shadowSmall : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            humanLabel,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : (hasStock ? AppTheme.textPrimary : AppTheme.textTertiary),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryBlue),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (vPrice > 0)
                            Text(
                              '₹${vPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : (hasStock ? AppTheme.textSecondary : AppTheme.textTertiary),
                              ),
                            ),
                          if (!hasStock) ...[
                            if (vPrice > 0)
                              const Text(' · ', style: TextStyle(fontSize: 10, color: AppTheme.errorRed)),
                            const Text(
                              'Out of stock',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. FULFILLMENT & DELIVERY PROMISE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildFulfillmentCard() {
    final shop = widget.shop;
    final hasDelivery = shop.hasDelivery;
    final deliveryCharge = shop.minDeliveryCharge;
    final locationLabel = shop.city.isNotEmpty ? shop.city : (shop.displayAddress.isNotEmpty ? shop.displayAddress.split(',').first : 'Local');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasDelivery ? AppTheme.successBg : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasDelivery ? LucideIcons.truck : LucideIcons.store,
                  size: 18,
                  color: hasDelivery ? AppTheme.successGreen : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDelivery ? 'Home Delivery Available' : 'Store Pickup Only',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasDelivery
                          ? (deliveryCharge > 0 ? 'Delivery fee from ₹${deliveryCharge.toStringAsFixed(0)}' : 'Free delivery on eligible orders')
                          : 'Collect in store at $locationLabel',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.veryLightGray),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.shieldCheck, size: 18, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genuine Local Commerce',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Direct from verified neighborhood retailers',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. EXPANDABLE DESCRIPTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDescriptionCard(String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this item',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (description.length > 180) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDescriptionExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. RETURN POLICY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildReturnPolicyCard(ApiProduct product) {
    Map<String, dynamic>? policyData;
    try {
      final raw = product.returnPolicy;
      if (raw is Map) {
        policyData = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final parsed = json.decode(raw);
        if (parsed is Map) policyData = Map<String, dynamic>.from(parsed);
      }
    } catch (_) {}

    final title = policyData?['title']?.toString() ?? 'Return & Replacement Policy';
    final details = policyData?['details']?.toString() ?? product.returnPolicy.toString();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          iconColor: AppTheme.primaryBlue,
          collapsedIconColor: AppTheme.textSecondary,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.rotateCcw, size: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                details,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 7. SPECIFICATIONS & ADDITIONAL INFO
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSpecificationsCard(ApiProduct product) {
    final specs = <MapEntry<String, String>>[];

    if (product.customFields != null) {
      for (final entry in product.customFields!.entries) {
        final k = entry.key.toLowerCase().trim();
        if (k.contains('variant') ||
            k.contains('varient') ||
            k.contains('return_policy') ||
            k == 'barcode' ||
            k == 'sku' ||
            k == 'unit') {
          continue;
        }
        final val = entry.value?.toString().trim() ?? '';
        if (val.isNotEmpty) {
          final label = entry.key
              .split('_')
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
              .join(' ');
          specs.add(MapEntry(label, val));
        }
      }
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: specs.asMap().entries.map((item) {
                final idx = item.key;
                final entry = item.value;
                final isLast = idx == specs.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8. STICKY PURCHASE BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStickyPurchaseBar(ApiProduct product) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        final inCart = cart.isVariantInCart(product.id, _selectedVariantId, _effectiveBatchId);
        final currentCartQty = inCart
            ? cart.quantityOf(product.id, variantId: _selectedVariantId, batchId: _effectiveBatchId)
            : _qty;
        final isAdding = cart.state == CartState.adding && cart.addingProductId == product.id;
        final inStock = _effectiveInStock;
        final maxStock = product.haveTracking ? _effectiveStock.round() : 999;
        final canIncrement = currentCartQty < maxStock;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            border: const Border(top: BorderSide(color: AppTheme.veryLightGray, width: 1)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.veryLightGray),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepperBtn(
                            icon: LucideIcons.minus,
                            enabled: inCart ? (currentCartQty > 0) : (_qty > 1),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              if (inCart) {
                                if (currentCartQty > 0) {
                                  await cart.updateQuantityByProduct(
                                    product: product,
                                    shopId: widget.shop.id,
                                    newQty: currentCartQty - 1,
                                    variantId: _selectedVariantId,
                                    batchId: _effectiveBatchId,
                                  );
                                }
                              } else {
                                if (_qty > 1) setState(() => _qty--);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$currentCartQty',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          _buildStepperBtn(
                            icon: LucideIcons.plus,
                            enabled: inStock && canIncrement,
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              if (!canIncrement) {
                                SnackbarUtil.showError(context, 'Only $maxStock available in stock');
                                return;
                              }
                              if (inCart) {
                                await cart.updateQuantityByProduct(
                                  product: product,
                                  shopId: widget.shop.id,
                                  newQty: currentCartQty + 1,
                                  variantId: _selectedVariantId,
                                  batchId: _effectiveBatchId,
                                );
                              } else {
                                setState(() => _qty++);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Primary Purchase Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (!inStock || isAdding)
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  if (inCart) {
                                    // Go to checkout
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApiCheckoutPage(shop: widget.shop),
                                      ),
                                    );
                                    return;
                                  }

                                  // Add to cart
                                  await cart.addItem(
                                    product: product,
                                    shopId: widget.shop.id,
                                    qty: _qty.toDouble(),
                                    variantId: _selectedVariantId,
                                    batchId: _effectiveBatchId,
                                  );

                                  if (context.mounted) {
                                    SnackbarUtil.showSuccess(
                                      context,
                                      '${product.name} added to cart',
                                      imageUrl: product.primaryImage,
                                    );
                                    setState(() => _qty = 1);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inCart ? AppTheme.successGreen : AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            disabledBackgroundColor: AppTheme.bgTertiary,
                            disabledForegroundColor: AppTheme.textTertiary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                          ),
                          child: isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      inCart
                                          ? LucideIcons.check
                                          : (inStock ? LucideIcons.shoppingBag : LucideIcons.alertCircle),
                                      size: 17,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        !inStock
                                            ? 'Out of Stock'
                                            : (inCart
                                                ? 'View Cart'
                                                : 'Add to Cart • ₹${(_effectivePrice * _qty).toStringAsFixed(0)}'),
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Active Cart Floating Pill (if cart has items from this store)
              if (cart.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ApiCheckoutPage(shop: widget.shop)),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.shoppingBag, size: 16, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''} in cart',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '₹${cart.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.arrowRight, size: 15, color: AppTheme.primaryBlue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 48,
        color: Colors.transparent,
        child: Center(
          child: Icon(
            icon,
            size: 15,
            color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAVIGATION HELPERS
  // ═══════════════════════════════════════════════════════════════════

  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApiShopDetailsPage(shop: widget.shop),
      ),
    );
  }
}
