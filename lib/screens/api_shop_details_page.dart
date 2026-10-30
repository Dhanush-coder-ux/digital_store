// lib/screens/api_shop_details_page.dart
//
// Redesigned Digital Storefront — Premium, Production-Ready Mobile Shopping UX
// Follows modern retail commerce design principles:
// 1. Clear shop identity & verified information in compact header.
// 2. Compact, elegant service summary (delivery & pickup) without cluttering front page.
// 3. Return policy available on demand via detail modal instead of dominating front page.
// 4. Products front and center with sticky category/search filter & responsive 2-column grid.
// 5. Variant selection bottom sheet, real-time cart synchronization, and smooth shopping.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/product_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/cart_session_model.dart';
import '../models/favorites_api_provider.dart';
import '../models/shop_provider.dart';
import '../models/review_provider.dart';
import '../core/models/review_model.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';
import '../widgets/category_widget.dart';
import 'api_product_detail_page.dart';
import 'api_checkout_page.dart';
import '../services/delivery_eligibility_service.dart';
import '../models/providers.dart';
import '../models/profile_provider.dart';

class ApiShopDetailsPage extends StatefulWidget {
  final Shop shop;

  const ApiShopDetailsPage({super.key, required this.shop});

  @override
  State<ApiShopDetailsPage> createState() => _ApiShopDetailsPageState();
}

class _ApiShopDetailsPageState extends State<ApiShopDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isFollowLoading = false;

  List<Map<String, dynamic>> _announcements = [];
  List<ShopDeliveryOption> _deliveryOptions = [];

  // ── Design Tokens (Mapped to AppTheme) ──────────────────────────────
  static const Color _bgWarm = AppTheme.bgPrimary;               // 0xFFFFFBF4 Cream page bg
  static const Color _surfaceWhite = AppTheme.white;             // 0xFFFFFFFF
  static const Color _accent = AppTheme.primaryBlue;             // 0xFFE0922F Caramel / Primary
  static const Color _accentLight = Color(0xFFFFF6EB);           // Soft warm caramel cream tint
  static const Color _accentMid = AppTheme.softRoyalBlue;         // 0xFFD4842B Deep amber
  static const Color _textPrimary = AppTheme.textPrimary;         // 0xFF2A1708 Espresso
  static const Color _textSecondary = AppTheme.textSecondary;     // 0xFF5C3A21 Medium brown
  static const Color _textTertiary = AppTheme.textTertiary;       // 0xFF8C6549 Light brown
  static const Color _borderSubtle = AppTheme.veryLightGray;     // 0xFFF4EBE1 Warm subtle border
  static const Color _accentGold = AppTheme.primaryBlue;         // 0xFFE0922F
  static const Color _successGreen = AppTheme.successGreen;       // 0xFF22C55E Emerald green

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsByShop(widget.shop.id);
      context.read<ReviewProvider>().fetchShopReviews(widget.shop.id);
      _fetchAnnouncements();
      _fetchDeliveryOptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    if (!mounted) return;
    try {
      final service = context.read<ShopProvider>().service;
      final data = await service.getShopAnnouncements(widget.shop.id);
      if (mounted) {
        setState(() {
          _announcements = data.isNotEmpty ? data : widget.shop.announcements;
        });
        _checkAndShowNewAnnouncementPopup();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _announcements = widget.shop.announcements;
        });
      }
    }
  }

  Future<void> _fetchDeliveryOptions() async {
    if (!mounted) return;
    try {
      final service = context.read<ShopProvider>().service;
      final data = await service.fetchShopDeliveryOptions(widget.shop.id);
      if (mounted) {
        setState(() {
          _deliveryOptions = _deduplicateDeliveryOptions(data);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deliveryOptions = _deduplicateDeliveryOptions(widget.shop.parsedDeliveryOptions);
        });
      }
    }
  }

  static const _eligibilityService = DeliveryEligibilityService();

  List<ShopDeliveryOption> _deduplicateDeliveryOptions(List<ShopDeliveryOption> options) {
    return _eligibilityService.deduplicateOptions(options);
  }

  Future<void> _checkAndShowNewAnnouncementPopup() async {
    if (_announcements.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList('seen_announcements') ?? [];

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
      if (!mounted) return;

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
                      color: _accentGold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.megaphone, color: _accentGold, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Store $type',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5,
                      color: _textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (cta != null && cta.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          cta,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontFamily: 'Outfit', color: _textSecondary),
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

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ProductProvider>().fetchProductsByShop(widget.shop.id, force: true),
      context.read<ReviewProvider>().fetchShopReviews(widget.shop.id, force: true),
      _fetchAnnouncements(),
      _fetchDeliveryOptions(),
    ]);
  }

  // ── Main Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: _textPrimary,
            backgroundColor: _surfaceWhite,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(),
                _buildShopIdentitySection(),
                _buildCompactServiceSummary(),
                _buildSmartDeliveryInfoSection(),
                if (_announcements.isNotEmpty) _buildAnnouncementsSection(),
                _buildProductsHeaderAndFilter(),
                _buildProductsGrid(),
                _buildReviewsSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
          _buildFloatingCartBar(),
        ],
      ),
    );
  }

  // ── Navigation Bar ─────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _surfaceWhite,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _accentLight,
            shape: BoxShape.circle,
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: const Icon(LucideIcons.arrowLeft, color: _accent, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.shop.name,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          letterSpacing: -0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _accentLight,
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withValues(alpha: 0.25)),
            ),
            child: const Icon(LucideIcons.share2, color: _accent, size: 18),
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: 'Check out ${widget.shop.name} on our marketplace!'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Store link copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _CartBadgeButton(shop: widget.shop),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _borderSubtle, height: 1),
      ),
    );
  }

  // ── Shop Identity Section (Compact Header) ─────────────────────────

  SliverToBoxAdapter _buildShopIdentitySection() {
    final hasBanner = widget.shop.bannerUrl != null && widget.shop.bannerUrl!.isNotEmpty;
    final hasLogo = widget.shop.logoUrl != null && widget.shop.logoUrl!.isNotEmpty;
    final double? distance = widget.shop.distance;

    return SliverToBoxAdapter(
      child: Container(
        color: _surfaceWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner (Restrained controlled height)
            if (hasBanner)
              SizedBox(
                height: 125,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: widget.shop.bannerUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: _bgWarm),
                  errorWidget: (context, url, error) => Container(color: _bgWarm),
                ),
              ),

            // Profile info row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Shop Logo
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _surfaceWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderSubtle, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasLogo
                              ? CachedNetworkImage(
                                  imageUrl: widget.shop.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => _buildLogoFallback(),
                                  errorWidget: (context, url, error) => _buildLogoFallback(),
                                )
                              : _buildLogoFallback(),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.shop.name,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 16, color: _accent),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.shop.categories.isNotEmpty
                                  ? widget.shop.categories.join(' • ')
                                  : (widget.shop.city.isNotEmpty ? widget.shop.city : 'Local Retailer'),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Follow Button
                      Consumer2<FavoritesApiProvider, AuthProvider>(
                        builder: (context, favorites, auth, _) {
                          final isFav = favorites.isShopFavorited(widget.shop.id);
                          return SizedBox(
                            height: 34,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFav ? _accentLight : _accent,
                                foregroundColor: isFav ? _accent : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                side: isFav ? BorderSide(color: _accent.withValues(alpha: 0.4)) : BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                }
                              },
                              icon: _isFollowLoading
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isFav ? _accent : Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isFav ? LucideIcons.check : LucideIcons.plus,
                                      size: 14,
                                    ),
                              label: Text(
                                isFav ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Metadata Badges (Rating, Distance, Status)
                  Row(
                    children: [
                      Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          final rating = reviewProvider.averageRatingForShop(widget.shop.id);
                          final count = reviewProvider.reviewCountForShop(widget.shop.id);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: _bgWarm,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  count > 0 ? rating.toStringAsFixed(1) : 'New',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '($count)',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: _textTertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      if (distance != null && distance > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: _bgWarm,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.mapPin, size: 12, color: _textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.circle, size: 7, color: _successGreen),
                            SizedBox(width: 4),
                            Text(
                              'Open',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Short Description / Tagline (Controlled 1-2 lines)
                  if (widget.shop.description?.isNotEmpty == true || widget.shop.tagline?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showServicesBottomSheet(context, initialTab: 0),
                      child: Text(
                        widget.shop.description?.isNotEmpty == true
                            ? widget.shop.description!
                            : widget.shop.tagline!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Container(
      color: _bgWarm,
      child: Center(
        child: Text(
          widget.shop.name.isNotEmpty ? widget.shop.name[0].toUpperCase() : 'S',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Shop Info & Services Summary Bar ────────────────────────────────
  // Displays professional, customer-friendly shop information and service highlights
  // (Delivery, In-Store Pickup, Timings) instead of raw technical strings.

  SliverToBoxAdapter _buildCompactServiceSummary() {
    final activeOptions = _deliveryOptions.isNotEmpty
        ? _deliveryOptions
        : _deduplicateDeliveryOptions(widget.shop.parsedDeliveryOptions);

    final bool hasDelivery = activeOptions.any((o) => !o.isPickup);
    final bool hasPickup = activeOptions.any((o) => o.isPickup);

    // Customer-friendly service highlight text
    String serviceHighlight;
    if (hasDelivery && hasPickup) {
      serviceHighlight = 'Delivery & Store Pickup';
    } else if (hasDelivery) {
      serviceHighlight = 'Home Delivery';
    } else if (hasPickup) {
      serviceHighlight = 'Store Pickup';
    } else {
      serviceHighlight = 'In-Store Shopping';
    }

    final String addressSnippet = widget.shop.displayAddress.isNotEmpty
        ? widget.shop.displayAddress
        : (widget.shop.city.isNotEmpty ? widget.shop.city : '');

    final String subtitleText = addressSnippet.isNotEmpty
        ? '$addressSnippet • Tap for hours & policies'
        : 'Tap to view store hours, address & delivery policies';

    return SliverToBoxAdapter(
      child: Container(
        color: _surfaceWhite,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showServicesBottomSheet(context, initialTab: 0),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _accentLight.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  // Shop / Info Icon Container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _surfaceWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      size: 19,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Shop Info & Services',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: const BoxDecoration(
                                color: _accentMid,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                serviceHighlight,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // View Details Action Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _surfaceWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accent.withValues(alpha: 0.28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 13,
                          color: _accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Smart Customer Delivery Info Section ────────────────────────────
  // Shows eligible delivery options for the current customer location.
  // Does NOT expose admin configuration details.

  SliverToBoxAdapter _buildSmartDeliveryInfoSection() {
    return SliverToBoxAdapter(
      child: _SmartDeliveryInfoWidget(
        shop: widget.shop,
        deliveryOptions: _deliveryOptions,
        eligibilityService: _eligibilityService,
      ),
    );
  }

  // ── Services & Policies Bottom Sheet (Detailed on demand) ─────────

  void _showServicesBottomSheet(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: DefaultTabController(
            length: 3,
            initialIndex: initialTab,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services & Shop Information',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20, color: _textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tab Header
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accentLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withValues(alpha: 0.2)),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: _textSecondary,
                    labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w500),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Store Details'),
                      Tab(text: 'Delivery & Pickup'),
                      Tab(text: 'Return Policy'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.58,
                  ),
                  child: TabBarView(
                    children: [
                      _buildStoreInfoDetailView(),
                      _buildDeliveryOptionsDetailView(),
                      _buildReturnPolicyDetailView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryOptionsDetailView() {
    final activeOptions = _deliveryOptions.isNotEmpty
        ? _deliveryOptions
        : _deduplicateDeliveryOptions(widget.shop.parsedDeliveryOptions);

    if (activeOptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No specific delivery options listed by this shop.',
            style: TextStyle(fontFamily: 'Outfit', color: _textSecondary),
          ),
        ),
      );
    }

    final double? distance = widget.shop.distance;

    return ListView(
      shrinkWrap: true,
      children: [
        ...activeOptions.map((opt) {
          final isFree = opt.deliveryCharge <= 0 || opt.isPickup;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: opt.isPickup ? const Color(0xFFDCFCE7) : _accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    opt.isPickup ? LucideIcons.shoppingBag : LucideIcons.truck,
                    color: opt.isPickup ? _successGreen : _accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt.title,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            isFree ? 'FREE' : '₹${opt.deliveryCharge.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isFree ? _successGreen : _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        opt.isPickup
                            ? (opt.speed.isNotEmpty
                                ? 'Store counter collection (${opt.speed})'
                                : 'Store counter collection • Free pickup')
                            : (opt.speed.isNotEmpty
                                ? 'Estimated delivery: ${opt.speed}'
                                : 'Standard home delivery'),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: _textSecondary),
                      ),
                      if (opt.freeShippingAmount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '• Free delivery on orders over ₹${opt.freeShippingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, color: _successGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (opt.minOrderAmount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '• Minimum order amount: ₹${opt.minOrderAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, color: _textTertiary),
                        ),
                      ],
                      if (distance != null && distance > 0 && opt.isDistanceTiered) ...[
                        const SizedBox(height: 2),
                        Text(
                          '• ${opt.calculate(subtotal: 0.0, distance: distance).description}',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, color: _textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (widget.shop.deliveryInfoMessage?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, size: 15, color: _textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.shop.deliveryInfoMessage!.trim(),
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, color: _textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReturnPolicyDetailView() {
    final raw = widget.shop.returnPolicy;
    if (raw == null || raw.toString().trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This store follows standard return guidelines. Contact retailer for damaged or incorrect items.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: _textSecondary, height: 1.45),
          ),
        ),
      );
    }

    Map<String, dynamic>? policyData;
    try {
      if (raw is Map) {
        policyData = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final parsed = json.decode(raw);
        if (parsed is Map) policyData = Map<String, dynamic>.from(parsed);
      }
    } catch (_) {}

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderSubtle),
        ),
        child: policyData != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (policyData['title'] != null) ...[
                    Text(
                      policyData['title'].toString(),
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (policyData['details'] != null)
                    Text(
                      policyData['details'].toString(),
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, color: _textSecondary, height: 1.5),
                    ),
                  if (policyData['subtitle'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderSubtle)),
                      child: Text(
                        policyData['subtitle'].toString(),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: _textSecondary),
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                raw.toString(),
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, color: _textSecondary, height: 1.5),
              ),
      ),
    );
  }

  Widget _buildStoreInfoDetailView() {
    final double? distance = widget.shop.distance;
    final addressText = widget.shop.displayAddress;
    final operatingHours = widget.shop.operatingHours;
    final gstNumber = widget.shop.businessInfos?['gst_infos']?['number']?.toString();
    final isGstRegistered = widget.shop.businessInfos?['gst_infos']?['registered'] == true ||
        (gstNumber != null && gstNumber.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. About the Shop Card
          if (widget.shop.description?.isNotEmpty == true || widget.shop.tagline?.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.store, size: 16, color: _accent),
                      SizedBox(width: 8),
                      Text(
                        'About the Shop',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.shop.description?.isNotEmpty == true
                        ? widget.shop.description!
                        : widget.shop.tagline!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: _textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Store Location & Address Card
          if (addressText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.mapPin, size: 16, color: _accent),
                          SizedBox(width: 8),
                          Text(
                            'Store Address',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (distance != null && distance > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _surfaceWhite,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _borderSubtle),
                          ),
                          child: Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addressText,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: _textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: addressText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Store address copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _surfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.copy, size: 13, color: _accent),
                          SizedBox(width: 6),
                          Text(
                            'Copy Address',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Operating Hours Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(LucideIcons.clock, size: 16, color: _accent),
                        SizedBox(width: 8),
                        Text(
                          'Store Timings',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, size: 6, color: _successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Open Today',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (operatingHours.isNotEmpty) ...[
                  ...operatingHours.map((h) {
                    final day = (h['day'] ?? h['day_of_week'] ?? '').toString();
                    final isClosed = h['is_closed'] == true;
                    final openAt = (h['open_at'] ?? '09:00').toString();
                    final closeAt = (h['close_at'] ?? '21:00').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day.isNotEmpty ? day : 'Daily',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            isClosed ? 'Closed' : '$openAt – $closeAt',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              color: isClosed ? _textTertiary : _textSecondary,
                              fontWeight: isClosed ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const Text(
                    'Regular business hours apply. Orders accepted daily during active store hours.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Verification & Business Credentials
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.shieldCheck, size: 16, color: _successGreen),
                    SizedBox(width: 8),
                    Text(
                      'Store Verification & Info',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(LucideIcons.check, size: 14, color: _successGreen),
                    SizedBox(width: 6),
                    Text(
                      'Verified Local Merchant on Marketplace',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (isGstRegistered && gstNumber != null && gstNumber.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.check, size: 14, color: _successGreen),
                      const SizedBox(width: 6),
                      Text(
                        'GST Registered: $gstNumber',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Announcements & Offers Section ─────────────────────────────────

  SliverToBoxAdapter _buildAnnouncementsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFFDE68A),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.tag, size: 15, color: Color(0xFFB45309)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORE OFFER',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _announcements.first['message']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                final code = _extractPromoCode(_announcements.first['message']?.toString() ?? '');
                if (code != null) {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coupon code "$code" copied!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  _showNewAnnouncementDialog(_announcements.first);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'View',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewAnnouncementDialog(Map<String, dynamic> ann) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Store Announcement', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
        content: Text(ann['message']?.toString() ?? '', style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
  }

  String? _extractPromoCode(String message) {
    final codeRegex = RegExp(r'(?:code|coupon|promo|voucher)[:\s]+([A-Z0-9_-]{3,15})', caseSensitive: false);
    final match = codeRegex.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  // ── Products Header & Sticky Filter ────────────────────────────────

  SliverPersistentHeader _buildProductsHeaderAndFilter() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProductsFilterHeaderDelegate(
        searchController: _searchController,
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
        shopName: widget.shop.name,
        onSearchChanged: (query) => setState(() => _searchQuery = query),
        onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
        shopId: widget.shop.id,
      ),
    );
  }

  // ── Products Grid ──────────────────────────────────────────────────

  SliverPadding _buildProductsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          if (error != null) return _buildErrorState(error, pp);
          if (products.isEmpty) return _buildEmptyState();

          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _ProductCard(
                  product: product,
                  shop: widget.shop,
                  onSelectVariant: () => _showVariantPickerBottomSheet(context, product, widget.shop),
                );
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.69,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildShimmerGrid() {
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.69,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildErrorState(String error, ProductProvider pp) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.alertCircle, size: 36, color: _accentMid),
              const SizedBox(height: 10),
              const Text(
                'Unable to load products',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => pp.refreshProductsByShop(widget.shop.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _bgWarm, shape: BoxShape.circle),
                child: const Icon(LucideIcons.shoppingBag, size: 32, color: _textTertiary),
              ),
              const SizedBox(height: 14),
              Text(
                _searchQuery.isNotEmpty ? 'No products match "$_searchQuery"' : 'No products available',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try selecting a different category or search term',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Variant Picker Bottom Sheet ────────────────────────────────────

  void _showVariantPickerBottomSheet(BuildContext context, ApiProduct product, Shop shop) {
    if (product.variants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? selectedVariantId = product.variants.first['id']?.toString();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cart = context.watch<ApiCartProvider>();
            final isAdding = cart.state == CartState.adding && cart.addingProductId == product.id;

            return Container(
              decoration: const BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: _borderSubtle, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _bgWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: product.primaryImage != null
                              ? CachedNetworkImage(
                                  imageUrl: product.primaryImage!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(LucideIcons.box, color: _textTertiary),
                                )
                              : const Icon(LucideIcons.box, color: _textTertiary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Select an option below:',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: _textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: _borderSubtle, height: 1),
                  const SizedBox(height: 12),

                  // Variants List
                  ...product.variants.map((v) {
                    final vId = v['id']?.toString() ?? '';
                    final vName = v['name']?.toString() ?? v['title']?.toString() ?? 'Option';
                    final vPrice = ApiProduct.getVariantPrice(v);
                    final isSelected = selectedVariantId == vId;

                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => selectedVariantId = vId);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? _bgWarm : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _textPrimary : _borderSubtle,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? _textPrimary : _textTertiary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  vName,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${vPrice.toStringAsFixed(vPrice.truncateToDouble() == vPrice ? 0 : 2)}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isAdding
                          ? null
                          : () async {
                              await context.read<ApiCartProvider>().addItem(
                                    product: product,
                                    shopId: shop.id,
                                    variantId: selectedVariantId,
                                  );
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${product.name} to cart!'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Add to Cart',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Ratings & Reviews Section (Bottom of Page) ─────────────────────

  SliverToBoxAdapter _buildReviewsSection() {
    return SliverToBoxAdapter(
      child: Consumer2<ReviewProvider, AuthProvider>(
        builder: (context, reviewProvider, authProvider, _) {
          final reviews = reviewProvider.reviewsForShop(widget.shop.id);
          final avgRating = reviewProvider.averageRatingForShop(widget.shop.id);
          final reviewCount = reviewProvider.reviewCountForShop(widget.shop.id);
          final userId = authProvider.userId;
          final hasReviewed = userId != null && reviews.any((r) => r.userId == userId);

          return Container(
            color: _surfaceWhite,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Reviews',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary),
                        ),
                        const SizedBox(height: 3),
                        if (reviewCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${avgRating.toStringAsFixed(1)} / 5.0 ($reviewCount reviews)',
                                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'No reviews yet',
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: _textTertiary),
                          ),
                      ],
                    ),
                    if (userId != null && !hasReviewed)
                      TextButton.icon(
                        onPressed: _showReviewModal,
                        icon: const Icon(LucideIcons.edit3, size: 14, color: _textPrimary),
                        label: const Text(
                          'Write Review',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: _bgWarm,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _borderSubtle)),
                        ),
                      ),
                  ],
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final r = reviews[index];
                        return Container(
                          width: 250,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bgWarm,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 14,
                                  );
                                }),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  r.reviewText?.isNotEmpty == true ? r.reviewText! : 'Verified purchase rating.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.5,
                                    color: r.reviewText?.isNotEmpty == true ? _textPrimary : _textTertiary,
                                    fontStyle: r.reviewText?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
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
              ],
            ),
          );
        },
      ),
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
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setModalState(() => rating = index + 1.0),
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your feedback about this store...',
                        hintStyle: const TextStyle(fontFamily: 'Outfit', color: _textTertiary, fontSize: 13.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _textPrimary)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
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
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _textPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Submit Review', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
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
      },
    );
  }

  // ── Floating Cart Summary Bar ──────────────────────────────────────

  Widget _buildFloatingCartBar() {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          child: FadeInUp(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApiCheckoutPage(shop: widget.shop)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accentMid],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} in cart',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '₹${cart.subtotal.toStringAsFixed(cart.subtotal.truncateToDouble() == cart.subtotal ? 0 : 2)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          'View Cart',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.arrowRight, color: Colors.white, size: 15),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Smart Delivery Info Widget ───────────────────────────────────────
// Evaluates and displays delivery eligibility for the current customer location.

class _SmartDeliveryInfoWidget extends StatefulWidget {
  final Shop shop;
  final List<ShopDeliveryOption> deliveryOptions;
  final DeliveryEligibilityService eligibilityService;

  const _SmartDeliveryInfoWidget({
    required this.shop,
    required this.deliveryOptions,
    required this.eligibilityService,
  });

  @override
  State<_SmartDeliveryInfoWidget> createState() => _SmartDeliveryInfoWidgetState();
}

class _SmartDeliveryInfoWidgetState extends State<_SmartDeliveryInfoWidget> {
  static const Color _bg = AppTheme.bgPrimary;
  static const Color _surface = AppTheme.white;
  static const Color _accent = AppTheme.primary;
  static const Color _textPrimary = AppTheme.textPrimary;
  static const Color _textSecondary = AppTheme.textSecondary;
  static const Color _borderSubtle = AppTheme.border;
  static const Color _successGreen = AppTheme.success;
  static const Color _errorRed = AppTheme.error;

  double? _getEffectiveDistance(BuildContext context) {
    // 1. Use shop.distance if provided by the API
    if (widget.shop.distance != null && widget.shop.distance! > 0) {
      return widget.shop.distance;
    }

    try {
      final profileProvider = context.read<ProfileProvider>();
      final locationProvider = context.read<LocationProvider>();
      final activeAddress = profileProvider.defaultAddress;

      final double? userLat = activeAddress?.latitude ?? locationProvider.latitude;
      final double? userLng = activeAddress?.longitude ?? locationProvider.longitude;

      final shopAddr = widget.shop.address;
      if (shopAddr != null && userLat != null && userLng != null) {
        final double? shopLat = double.tryParse(
            shopAddr['latitude']?.toString() ?? shopAddr['lat']?.toString() ?? '');
        final double? shopLng = double.tryParse(
            shopAddr['longitude']?.toString() ?? shopAddr['lng']?.toString() ?? '');

        if (shopLat != null && shopLng != null) {
          return widget.eligibilityService.calculateDistanceKm(
              userLat, userLng, shopLat, shopLng);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.deliveryOptions.isNotEmpty
        ? widget.deliveryOptions
        : widget.eligibilityService.deduplicateOptions(widget.shop.parsedDeliveryOptions);

    if (options.isEmpty) return const SizedBox.shrink();

    final distance = _getEffectiveDistance(context);
    final results = widget.eligibilityService.evaluateOptions(
      options: options,
      customerDistance: distance,
      subtotal: 0.0, // No cart context on shop detail page
      alreadyDeduplicated: true,
    );

    final eligible = results.where((r) => r.isEligible).toList();
    final hasAddress = distance != null;

    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.truck, size: 14, color: _accent),
                const SizedBox(width: 6),
                const Text(
                  'Delivery Options',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                if (!hasAddress) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'Select address for eligibility',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (!hasAddress) ...[
              // No address — show all enabled options without eligibility judgment
              ...options.map((opt) => _buildOptionRow(
                emoji: _getEmoji(opt),
                label: opt.title,
                detail: _buildNoAddressDetail(opt),
                isHighlighted: false,
              )),
            ] else if (eligible.isEmpty) ...[
              _buildUnavailableRow(distance),
            ] else ...[
              ...eligible.map((r) => _buildEligibleOptionRow(r, distance)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEligibleOptionRow(DeliveryEligibilityResult result, double distance) {
    final opt = result.option;
    final calc = result.calc;
    final isFree = calc?.isFree == true || opt.isPickup;

    String detail;
    if (opt.isPickup) {
      detail = result.speedLabel;
    } else if (opt.isNationwide) {
      detail = result.speedLabel;
    } else if (isFree) {
      detail = 'Free · ${DeliveryEligibilityService.formatDistance(distance)}';
    } else {
      final fee = calc?.fee ?? opt.deliveryCharge;
      detail = '₹${fee.toStringAsFixed(0)} · ${DeliveryEligibilityService.formatDistance(distance)}';
    }

    return _buildOptionRow(
      emoji: _getEmoji(opt),
      label: isFree && !opt.isPickup && !opt.isNationwide
          ? 'Free ${opt.title}'
          : opt.title,
      detail: detail,
      isHighlighted: isFree,
    );
  }

  String _buildNoAddressDetail(ShopDeliveryOption opt) {
    if (opt.isPickup) return opt.speed.isNotEmpty ? opt.speed : 'Same day';
    if (opt.isNationwide) return opt.speed.isNotEmpty ? opt.speed : '5–7 Business Days';
    if (opt.deliveryCharge <= 0) return 'Free · ${opt.speed.isNotEmpty ? opt.speed : "2–3 days"}';
    return '₹${opt.deliveryCharge.toStringAsFixed(0)} · ${opt.speed.isNotEmpty ? opt.speed : "2–3 days"}';
  }

  Widget _buildOptionRow({
    required String emoji,
    required String label,
    required String detail,
    required bool isHighlighted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? _successGreen : _textPrimary,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: isHighlighted ? _successGreen : _textSecondary,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableRow(double distance) {
    return Row(
      children: [
        const Icon(LucideIcons.alertCircle, size: 14, color: _errorRed),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Delivery not available for your location (${DeliveryEligibilityService.formatDistance(distance)})',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: _errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getEmoji(ShopDeliveryOption opt) {
    if (opt.isPickup) return '🏬';
    if (opt.isInstant) return '⚡';
    if (opt.isNationwide) return '🌐';
    return '🚚';
  }
}

// ── Persistent Products Filter Header Delegate ──────────────────────

class _ProductsFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedCategory;
  final String shopName;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final String shopId;

  _ProductsFilterHeaderDelegate({
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategory,
    required this.shopName,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.shopId,
  });

  @override
  double get minExtent => 112;

  @override
  double get maxExtent => 112;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ────────────────────────────────────────────
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(LucideIcons.search, size: 17, color: AppTheme.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search products in store...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.softPeach,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, size: 14, color: AppTheme.primary),
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Categories Horizontal Chips with Realistic Product Thumbnails ─
          Consumer<ProductProvider>(
            builder: (context, pp, _) {
              final rawCats = pp.categoriesForShop(shopId);
              final categories = ['All', ...rawCats.where((c) => c.toLowerCase() != 'all')];

              return SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat == selectedCategory;
                    final item = CategoryCatalog.find(cat);

                    return CategoryPillItem(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onCategorySelected(cat),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProductsFilterHeaderDelegate oldDelegate) {
    return oldDelegate.searchQuery != searchQuery ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.shopId != shopId;
  }
}

// ── Premium Product Card ─────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ApiProduct product;
  final Shop shop;
  final VoidCallback onSelectVariant;

  const _ProductCard({
    required this.product,
    required this.shop,
    required this.onSelectVariant,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasVariants = product.hasVariant && product.variants.isNotEmpty;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consistent 4:3 Image Area
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                      child: product.primaryImage != null
                          ? CachedNetworkImage(
                              imageUrl: product.primaryImage!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppTheme.ultraLightGray),
                              errorWidget: (context, url, error) => _buildFallback(product.name),
                            )
                          : _buildFallback(product.name),
                    ),
                  ),
                  if (hasVariants)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.variants.length} options',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer2<FavoritesApiProvider, AuthProvider>(
                      builder: (context, favorites, auth, _) {
                        final isFav = favorites.isProductFavorited(product.id);
                        return GestureDetector(
                          onTap: () {
                            if (auth.userId != null) {
                              favorites.toggleProductFavorite(auth.userId!, product.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to save favorites'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 15,
                              color: isFav ? const Color(0xFFDC2626) : const Color(0xFF77736D),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Product Details
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (product.unit != null && product.unit!.isNotEmpty)
                      Text(
                        product.unit!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                        ),
                        maxLines: 1,
                      )
                    else
                      const SizedBox(height: 14),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${product.displayPrice.toStringAsFixed(product.displayPrice.truncateToDouble() == product.displayPrice ? 0 : 2)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _QuickAddButton(
                          product: product,
                          shop: shop,
                          onSelectVariant: onSelectVariant,
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
    );
  }

  Widget _buildFallback(String name) {
    return Container(
      color: AppTheme.ultraLightGray,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// ── Quick Add Button ─────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final ApiProduct product;
  final Shop shop;
  final VoidCallback onSelectVariant;

  const _QuickAddButton({
    required this.product,
    required this.shop,
    required this.onSelectVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        final qty = cart.totalQuantityOf(product.id);
        final isAdding = cart.state == CartState.adding && cart.addingProductId == product.id;
        final hasVariants = product.hasVariant && product.variants.isNotEmpty;

        if (qty > 0) {
          return Container(
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(7),
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
                      await cart.updateQuantity(item, item.qty.round() - 1);
                    } else {
                      String? variantId;
                      String? batchId;
                      for (final entry in cart.localItems) {
                        if (entry.product.id == product.id) {
                          variantId = entry.variantId;
                          batchId = entry.batchId;
                          break;
                        }
                      }
                      await cart.removeItem(productId: product.id, variantId: variantId, batchId: batchId);
                    }
                  },
                  child: const SizedBox(
                    width: 24,
                    height: 28,
                    child: Icon(Icons.remove, color: Colors.white, size: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (hasVariants) {
                      onSelectVariant();
                    } else {
                      CartSessionItem? item;
                      for (final i in cart.items) {
                        if (i.productId == product.id) {
                          item = i;
                          break;
                        }
                      }
                      if (item != null) {
                        await cart.updateQuantity(item, item.qty.round() + 1);
                      } else {
                        cart.addItem(product: product, shopId: shop.id);
                      }
                    }
                  },
                  child: const SizedBox(
                    width: 24,
                    height: 28,
                    child: Icon(Icons.add, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: isAdding
              ? null
              : () {
                  if (hasVariants) {
                    onSelectVariant();
                  } else {
                    cart.addItem(product: product, shopId: shop.id);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(7),
            ),
            child: isAdding
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                  )
                : Text(
                    hasVariants ? 'Options' : '+ Add',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ── Cart Badge Button ────────────────────────────────────────────────

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
            MaterialPageRoute(builder: (_) => ApiCheckoutPage(shop: shop)),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text(
                  '${cart.itemCount}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
