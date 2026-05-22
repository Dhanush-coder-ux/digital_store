import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/providers.dart';
import '../utils/snackbar_util.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'main_screen.dart';
import 'product_detail_page.dart';

class ShopDetailsPage extends StatefulWidget {
  final Map<String, dynamic> store;
  final String? heroTag;

  const ShopDetailsPage({super.key, required this.store, this.heroTag});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  bool _isFollowing = false;
  late final ScrollController _scrollController;
  int _selectedCategory = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedCategoryTitle;
  late List<String> _storeImages;
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  bool _showCartBar = false;
  Timer? _cartBarTimer;
  bool _hasSeenPopup = false; // false = first visit (show dialog), true = returning (show inline)

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _storeImages = [
      _storeImage,
      "https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&q=80&w=1000",
      "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&q=80&w=1000"
    ];
    
    _imageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _storeImages.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndShowPopups(context);
      }
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _cartBarTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'All Items',
    'Fresh Fruits',
    'Vegetables',
    'Dairy & Eggs',
  ];

  List<List<Map<String, dynamic>>> get _productSections => [
    [
      {"name": "Red Apples", "weight": "Approx. 1kg", "price": 140.0, "image": "https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?q=80&w=1000", "category": "Fresh Fruits", "description": "Crisp red apples selected by the retailer for daily fruit boxes and family baskets."},
      {"name": "Bananas", "weight": "1 Bunch", "price": 200.0, "image": "https://images.unsplash.com/photo-1603833665858-e81b1c7e4460?q=80&w=1000", "tag": "BEST", "category": "Fresh Fruits", "description": "Naturally ripened banana bunches packed for same-day delivery."},
      {"name": "Oranges", "weight": "Pack of 6", "price": 100.0, "image": "https://images.unsplash.com/photo-1547514701-42782101795e?q=80&w=1000", "isSoldOut": true, "category": "Fresh Fruits", "description": "Juicy oranges packed as a family-size portion."},
    ],
    [
      {"name": "Farm Milk", "weight": "1 Gallon", "price": 50.0, "image": "https://images.unsplash.com/photo-1550583724-12770d8a6020?q=80&w=1000", "category": "Dairy & Eggs", "description": "Fresh dairy stock packed cold by the retailer before dispatch."},
      {"name": "Brown Eggs", "weight": "Dozen", "price": 10.0, "image": "https://images.unsplash.com/photo-1518562144247-5aa35d36746f?q=80&w=1000", "tag": "SALE", "category": "Dairy & Eggs", "description": "Brown eggs checked and packed as a dozen."},
      {"name": "Custom Butter Cake", "weight": "1 kg", "price": 650.0, "image": "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000", "category": "Bakery", "requiresPreOrder": true, "noticeHours": 24, "tag": "PRE-ORDER", "description": "Made-to-order butter cake baked fresh after confirmation. Best for tomorrow or weekend pickup/delivery."},
    ],
  ];

  String get _storeName => widget.store['name'] as String? ?? 'Store';
  String get _storeImage => widget.store['image'] as String? ?? '';
  String get _storeRating => (widget.store['rating'] ?? 4.5).toString();
  String get _storeTime => widget.store['time'] as String? ?? '30min';
  String get _storeId => widget.store['id'] as String? ?? '0';
  List<Map<String, dynamic>> get _regularCustomers =>
      (widget.store['regularCustomers'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ??
      [
        {'name': 'Deepak', 'orders': 9},
        {'name': 'Priya', 'orders': 6},
        {'name': 'Arun', 'orders': 4},
        {'name': 'Nisha', 'orders': 3},
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverAppBar(
            pinned: true,
            toolbarHeight: 160,
            backgroundColor: AppTheme.bgPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(context),
                  const SizedBox(height: AppTheme.xl),
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasSeenPopup) ...[                  
                    _buildInlineOffersSection(context),
                    const SizedBox(height: AppTheme.xl),
                  ],
                  _buildShopTrendingSection(context),
                  const SizedBox(height: AppTheme.xxl),
                  _buildProductSection(context, 'Fresh Fruits', _productSections[0]),
                  const SizedBox(height: AppTheme.xxl),
                  _buildProductSection(context, 'Dairy & Eggs', _productSections[1]),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildFloatingCartBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(AppTheme.sm),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkGray.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowLeft, color: AppTheme.white, size: 20),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              final isFavorited = favoritesProvider.isFavorited(_storeId);
              return GestureDetector(
                onTap: () {
                  favoritesProvider.toggleFavorite(FavoriteItem(
                    id: _storeId,
                    name: _storeName,
                    type: 'store',
                    image: _storeImage,
                    rating: double.tryParse(_storeRating) ?? 4.5,
                  ));
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.darkGray.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorited ? Icons.favorite_rounded : LucideIcons.heart,
                    color: isFavorited ? AppTheme.errorRed : AppTheme.white,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppTheme.md, left: 4),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.darkGray.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.share2, color: AppTheme.white, size: 18),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.store['id'] != null || widget.heroTag != null
                ? Hero(
                    tag: widget.heroTag ?? 'store-${widget.store["id"]}',
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1500),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Image.network(
                        _storeImages[_currentImageIndex],
                        key: ValueKey<int>(_currentImageIndex),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(key: ValueKey('error'), color: AppTheme.primaryBlue),
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1500),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Image.network(
                      _storeImages[_currentImageIndex],
                      key: ValueKey<int>(_currentImageIndex),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(key: ValueKey('error'), color: AppTheme.primaryBlue),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkGray.withOpacity(0.35),
                    Colors.transparent,
                    AppTheme.darkGray.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: AppTheme.xl,
              left: AppTheme.xl,
              right: AppTheme.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _storeName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isFollowing = !_isFollowing),
                        child: AnimatedContainer(
                          duration: AppDurations.normal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.md,
                            vertical: AppTheme.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _isFollowing ? AppTheme.white : AppTheme.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                              color: _isFollowing ? AppTheme.white : AppTheme.white.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFollowing ? LucideIcons.check : LucideIcons.plus,
                                size: 13,
                                color: _isFollowing ? AppTheme.primaryBlue : AppTheme.white,
                              ),
                              const SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: AppDurations.fast,
                                child: Text(
                                  _isFollowing ? 'Unfollow' : 'Follow',
                                  key: ValueKey(_isFollowing),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _isFollowing ? AppTheme.primaryBlue : AppTheme.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (widget.store['categories'] != null)
                    Text(
                      (widget.store['categories'] as List<String>).join(' • '),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: AppTheme.md),
                  Row(
                    children: [
                      _buildInfoPill(Icons.star_rounded, _storeRating, const Color(0xFFF59E0B)),
                      const SizedBox(width: AppTheme.sm),
                      _buildInfoPill(LucideIcons.clock, _storeTime, AppTheme.white),
                      const SizedBox(width: AppTheme.sm),
                      _buildInfoPill(LucideIcons.truck, 'Free Delivery', AppTheme.paleCyan),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Text(
                          'OPEN',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkAndShowPopups(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'store_visited_${_storeId}';
    final hasVisited = prefs.getBool(key) ?? false;

    if (!mounted) return;

    if (!hasVisited) {
      // First visit — show the dialog popup, then mark as visited
      await prefs.setBool(key, true);
      if (!mounted) return;
      setState(() => _hasSeenPopup = false);
      _showOffersDialog(context, _getAnnouncements());
    } else {
      // Returning visit — use inline offers banner instead of popup
      setState(() => _hasSeenPopup = true);
    }
  }

  List<Map<String, dynamic>> _getAnnouncements() {
    final rawAnnouncements = widget.store['announcements'] as List<dynamic>? ?? [];
    return rawAnnouncements.isNotEmpty
        ? rawAnnouncements.cast<Map<String, dynamic>>()
        : [
            {
              'title': 'Weekend Flash Sale',
              'description': 'Get 20% off on all bakery products above ₹299.',
              'discount': '20% OFF',
              'icon': '🔥',
              'gradient': [const Color(0xFFFF6B35), const Color(0xFFFF4500)],
            },
            {
              'title': 'Free Delivery',
              'description': 'Free delivery on your first order from this store.',
              'discount': 'FREE',
              'icon': '🚚',
              'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            },
            {
              'title': 'Buy 1 Get 1',
              'description': 'Selected snacks are now Buy 1 Get 1 for today.',
              'discount': 'BOGO',
              'icon': '🎁',
              'gradient': [const Color(0xFF059669), const Color(0xFF0D9488)],
            },
          ];
  }

  void _showOffersDialog(BuildContext context, List<dynamic> announcements) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.xxl,
            ),
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.white.withOpacity(0.18),
                      AppTheme.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.28),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.xl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.22),
                            const Color(0xFFEC4899).withOpacity(0.16),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusXl),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.white.withOpacity(0.24),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: AppTheme.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppTheme.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Special Offers! 🎉',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppTheme.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${announcements.length} new announcement${announcements.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppTheme.white.withOpacity(0.76),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.xs),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                color: AppTheme.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.xl,
                          AppTheme.lg,
                          AppTheme.xl,
                          AppTheme.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...announcements.asMap().entries.map((entry) {
                              final index = entry.key;
                              final announcement = entry.value as Map<String, dynamic>?;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < announcements.length - 1 ? AppTheme.md : 0,
                                ),
                                child: _buildOfferCard(announcement),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.xl,
                        AppTheme.md,
                        AppTheme.xl,
                        AppTheme.xl,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showWelcomeDialog(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.white.withOpacity(0.24),
                                AppTheme.white.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppTheme.white.withOpacity(0.18),
                            ),
                          ),
                          child: const Text(
                            'Explore Now',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic>? offer) {
    if (offer == null) return const SizedBox();
    
    final title = offer['title'] as String? ?? 'Special Offer';
    final description = offer['description'] as String? ?? '';
    final discount = offer['discount'] as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (discount.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.24),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppTheme.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sm),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppTheme.white.withOpacity(0.78),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.xxl,
            ),
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.all(AppTheme.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.white.withOpacity(0.18),
                      AppTheme.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.28),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.white.withOpacity(0.24),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.store,
                            color: AppTheme.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTheme.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome! 👋',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppTheme.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _storeName,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppTheme.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.xs),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              color: AppTheme.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.lg),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.md),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.12),
                          ),
                        ),
                      child: Text(
                        'Explore our exclusive deals and discover fresh items curated just for you. Enjoy fast delivery and premium quality with every order!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassStat('⭐', _storeRating, 'Rating'),
                        ),
                        const SizedBox(width: AppTheme.sm),
                        Expanded(
                          child: _buildGlassStat('🚚', _storeTime, 'Delivery'),
                        ),
                        const SizedBox(width: AppTheme.sm),
                        Expanded(
                          child: _buildGlassStat('🎁', 'Free', 'Shipping'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.lg),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.md,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.white.withOpacity(0.24),
                              AppTheme.white.withOpacity(0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.white.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Start Shopping',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassStat(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.white.withOpacity(0.68),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppTheme.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(LucideIcons.search, color: AppTheme.textTertiary, size: 18),
          hintText: 'Search inside store...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: AppDurations.normal,
              margin: const EdgeInsets.only(right: AppTheme.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.lg,
                vertical: AppTheme.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildProductSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> products,
  ) {
    final filteredProducts = _searchQuery.isEmpty
        ? products
        : products.where((p) => (p['name'] as String).toLowerCase().contains(_searchQuery)).toList();

    if (filteredProducts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_expandedCategoryTitle == title) {
                    _expandedCategoryTitle = null;
                  } else {
                    _expandedCategoryTitle = title;
                  }
                });
              },
              child: Text(
                _expandedCategoryTitle == title ? 'Show less' : 'View all',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),
        if (_expandedCategoryTitle == title)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: AppTheme.md,
              mainAxisSpacing: AppTheme.md,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: 50 * index),
                child: _buildProductCard(context, filteredProducts[index]),
              );
            },
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return FadeInRight(
                  delay: Duration(milliseconds: 80 * index),
                  child: _buildProductCard(context, filteredProducts[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final isSoldOut = product['isSoldOut'] == true;
    final price = (product['price'] as num).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              storeName: _storeName,
              storeId: _storeId,
            ),
          ),
        );
      },
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl),
              ),
              child: Stack(
                children: [
                  Image.network(
                    product['image'] as String,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    color: isSoldOut ? Colors.grey : null,
                    colorBlendMode: isSoldOut ? BlendMode.saturation : null,
                    errorBuilder: (_, __, ___) => Container(
                      height: 130,
                      color: AppTheme.bgSecondary,
                    ),
                  ),
                  Positioned(
                    top: AppTheme.sm,
                    right: AppTheme.sm,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, _) {
                        final productId = '${_storeId}_${product["name"]}';
                        final isFavorited = favoritesProvider.isFavorited(productId);
                        return GestureDetector(
                          onTap: () {
                            favoritesProvider.toggleFavorite(FavoriteItem(
                              id: productId,
                              name: product['name'] as String,
                              type: 'product',
                              image: product['image'] as String?,
                              rating: 4.5,
                            ));
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.shadowSmall,
                            ),
                            child: Icon(
                              isFavorited ? Icons.favorite_rounded : LucideIcons.heart,
                              color: isFavorited ? AppTheme.errorRed : AppTheme.textTertiary,
                              size: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (product['tag'] != null)
                    Positioned(
                      top: AppTheme.sm,
                      left: AppTheme.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: product['tag'] == 'BEST'
                              ? const Color(0xFFF59E0B)
                              : AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          product['tag'] as String,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (isSoldOut)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Text(
                            'SOLD OUT',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
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
                    product['name'] as String,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['weight'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: isSoldOut
                            ? null
                            : () => _addToCart(context, product, price),
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSoldOut
                                ? AppTheme.veryLightGray
                                : AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            color: isSoldOut ? AppTheme.textTertiary : AppTheme.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(
    BuildContext context,
    Map<String, dynamic> product,
    double price,
  ) {
    final cart = context.read<CartProvider>();
    final productObj = Product(
      id: '${_storeId}_${product["name"]}',
      name: product['name'] as String,
      category: product['category'] as String? ?? 'General',
      price: price,
      image: product['image'] as String?,
    );
    cart.addToCart(productObj, _storeName);

    // Show cart bar
    setState(() {
      _showCartBar = true;
    });

    // Hide cart bar after 2 seconds
    _cartBarTimer?.cancel();
    _cartBarTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCartBar = false;
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // INLINE OFFERS SECTION (shown on returning visits instead of popup)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildInlineOffersSection(BuildContext context) {
    final offers = _getAnnouncements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🎉 OFFERS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Offers for You',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showOffersDialog(context, offers),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Exclusive deals active right now',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.lg),

        // Horizontal scroll of offer cards
        SizedBox(
          height: 142,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final gradientColors = offer['gradient'] as List<Color>? ??
                  [AppTheme.primaryBlue, AppTheme.softRoyalBlue];
              final icon = offer['icon'] as String? ?? '🎉';
              final title = offer['title'] as String? ?? 'Special Offer';
              final description = offer['description'] as String? ?? '';
              final discount = offer['discount'] as String? ?? '';

              return FadeInRight(
                delay: Duration(milliseconds: 60 * index),
                child: GestureDetector(
                  onTap: () => _showOffersDialog(context, [offer]),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: AppTheme.md),
                    padding: const EdgeInsets.all(AppTheme.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon bubble
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Discount badge
                            if (discount.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  discount,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Description
                        Text(
                          description,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        const Divider(color: Color(0xFFF0F3F7)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRENDING SECTION (embedded in shop)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildShopTrendingSection(BuildContext context) {
    final trending = [
      {
        'name': 'Alphonso Mangoes',
        'price': 249.0,
        'originalPrice': '₹320',
        'image': 'https://images.unsplash.com/photo-1601493700631-2b16ec4b4716?auto=format&fit=crop&w=400&q=80',
        'tag': '🔥 Hot',
        'rank': 1,
        'orders': '2.4k orders',
        'tagColor': const Color(0xFFFF4500),
        'category': 'Fresh Fruits',
        'weight': 'Approx. 1kg',
        'description': 'Premium Alphonso mangoes sourced fresh — one of the most trending items across all stores in Coimbatore this season.',
        'requiresPreOrder': false,
        'noticeHours': 0,
      },
      {
        'name': 'Sourdough Bread',
        'price': 179.0,
        'originalPrice': '₹220',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
        'tag': '⚡ Fast',
        'rank': 2,
        'orders': '1.8k orders',
        'tagColor': const Color(0xFF7C3AED),
        'category': 'Bakery',
        'weight': '500g loaf',
        'description': 'Freshly baked sourdough — a fast-moving crowd favourite trending at the top of our weekly charts.',
        'requiresPreOrder': false,
        'noticeHours': 0,
      },
      {
        'name': 'Greek Yoghurt',
        'price': 89.0,
        'originalPrice': '₹110',
        'image': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
        'tag': '🌿 Organic',
        'rank': 3,
        'orders': '1.1k orders',
        'tagColor': const Color(0xFF059669),
        'category': 'Dairy & Eggs',
        'weight': '400g',
        'description': 'Rich, creamy organic Greek yoghurt — high protein and incredibly popular with health-conscious shoppers.',
        'requiresPreOrder': false,
        'noticeHours': 0,
      },
      {
        'name': 'Cold Brew Coffee',
        'price': 199.0,
        'originalPrice': '₹249',
        'image': 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=400&q=80',
        'tag': '☕ Popular',
        'rank': 4,
        'orders': '760 orders',
        'tagColor': const Color(0xFF92400E),
        'category': 'Beverages',
        'weight': '300ml',
        'description': 'Smooth cold brew coffee steeped for 18 hours. A top seller every single day.',
        'requiresPreOrder': false,
        'noticeHours': 0,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '🔥 LIVE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Trending in Store',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'What customers are buying right now',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.lg),
        SizedBox(
          height: 218,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trending.length,
            itemBuilder: (context, index) {
              return FadeInRight(
                delay: Duration(milliseconds: 60 * index),
                child: _buildShopTrendingCard(context, trending[index], index),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        const Divider(color: Color(0xFFF0F3F7)),
      ],
    );
  }

  Widget _buildShopTrendingCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final rankColors = [
      [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
      [const Color(0xFFC0C0C0), const Color(0xFF808080)],
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
      [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
    ];
    final colors = rankColors[index < 4 ? index : 3];
    final price = item['price'] as double;
    final originalPrice = item['originalPrice'] as String;
    final isSoldOut = item['isSoldOut'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: item,
              storeName: _storeName,
              storeId: _storeId,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowMedium,
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Image.network(
                      item['image'] as String,
                      fit: BoxFit.cover,
                      color: isSoldOut ? Colors.grey : null,
                      colorBlendMode: isSoldOut ? BlendMode.saturation : null,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.bgSecondary,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#${item["rank"]}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Tag
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (item['tagColor'] as Color).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['tag'] as String,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['category'] as String,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        originalPrice,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['orders'] as String,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4500),
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

  void _sendRegularsOffer(BuildContext context) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.xxl,
            ),
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.all(AppTheme.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.white.withOpacity(0.18),
                      AppTheme.white.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.28),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.white.withOpacity(0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.white.withOpacity(0.24),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.send,
                                color: AppTheme.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppTheme.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Offer',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppTheme.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'To ${_regularCustomers.length} loyal customers',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppTheme.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.xs),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.16),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  color: AppTheme.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.xl),
                        TextField(
                          controller: messageController,
                          maxLines: 4,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your offer or announcement...',
                            hintStyle: TextStyle(
                              color: AppTheme.white.withOpacity(0.5),
                              fontFamily: 'Outfit',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: AppTheme.white.withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: AppTheme.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: AppTheme.primaryBlue.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: AppTheme.white.withOpacity(0.06),
                            contentPadding: const EdgeInsets.all(AppTheme.md),
                          ),
                        ),
                        const SizedBox(height: AppTheme.xl),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.white.withOpacity(0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppTheme.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.md),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (messageController.text.trim().isNotEmpty) {
                                    Navigator.pop(context);
                                    SnackbarUtil.showSuccess(
                                      context,
                                      'Offer sent to ${_regularCustomers.length} customers! 🎉',
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Please enter an offer message'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
                                    ),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Send',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppTheme.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingCartBar(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty || !_showCartBar) return const SizedBox();
        return SafeArea(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/cart');
            },
            child: Container(
              margin: const EdgeInsets.all(AppTheme.lg),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.xl,
                vertical: AppTheme.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        cart.itemCount.toString(),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: Text(
                      'View cart',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '₹${cart.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  const Icon(LucideIcons.arrowRight, color: AppTheme.white, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
