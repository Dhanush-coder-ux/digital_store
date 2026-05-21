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
      {"name": "Red Apples", "weight": "Approx. 1kg", "price": 140.0, "image": "https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?q=80&w=1000", "category": "Fresh Fruits"},
      {"name": "Bananas", "weight": "1 Bunch", "price": 200.0, "image": "https://images.unsplash.com/photo-1603833665858-e81b1c7e4460?q=80&w=1000", "tag": "BEST", "category": "Fresh Fruits"},
      {"name": "Oranges", "weight": "Pack of 6", "price": 100.0, "image": "https://images.unsplash.com/photo-1547514701-42782101795e?q=80&w=1000", "isSoldOut": true, "category": "Fresh Fruits"},
    ],
    [
      {"name": "Farm Milk", "weight": "1 Gallon", "price": 50.0, "image": "https://images.unsplash.com/photo-1550583724-12770d8a6020?q=80&w=1000", "category": "Dairy & Eggs"},
      {"name": "Brown Eggs", "weight": "Dozen", "price": 10.0, "image": "https://images.unsplash.com/photo-1518562144247-5aa35d36746f?q=80&w=1000", "tag": "SALE", "category": "Dairy & Eggs"},
      {"name": "Butter", "weight": "Salted 200g", "price": 200.0, "image": "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?q=80&w=1000", "category": "Dairy & Eggs"},
    ],
  ];

  String get _storeName => widget.store['name'] as String? ?? 'Store';
  String get _storeImage => widget.store['image'] as String? ?? '';
  String get _storeRating => (widget.store['rating'] ?? 4.5).toString();
  String get _storeTime => widget.store['time'] as String? ?? '30min';
  String get _storeId => widget.store['id'] as String? ?? '0';

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

  void _checkAndShowPopups(BuildContext context) {
    // Check if store has announcements/offers
    final announcements = widget.store['announcements'] as List<dynamic>? ?? [];
    
    if (announcements.isNotEmpty) {
      _showOffersDialog(context, announcements);
    } else {
      _showWelcomeDialog(context);
    }
  }

  void _showOffersDialog(BuildContext context, List<dynamic> announcements) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF59E0B).withOpacity(0.3),
                            const Color(0xFFEC4899).withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: AppTheme.white,
                              size: 24,
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  '${announcements.length} new announcement${announcements.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 12,
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
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
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
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 250,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.lg),
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
                      padding: const EdgeInsets.all(AppTheme.lg),
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
                                AppTheme.white.withOpacity(0.3),
                                AppTheme.white.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: AppTheme.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Explore Now',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
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
          color: AppTheme.white.withOpacity(0.15),
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
                    fontSize: 13,
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
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    discount,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppTheme.white,
                      fontSize: 11,
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
                color: AppTheme.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
                padding: const EdgeInsets.all(AppTheme.lg),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.store,
                            color: AppTheme.white,
                            size: 24,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                _storeName,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppTheme.white,
                                  fontSize: 13,
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
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
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
                    const SizedBox(height: AppTheme.lg),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.md),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        'Explore our exclusive deals and discover fresh items curated just for you. Enjoy fast delivery and premium quality with every order!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.white.withOpacity(0.95),
                          fontSize: 13,
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
                              AppTheme.white.withOpacity(0.3),
                              AppTheme.white.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.white.withOpacity(0.1),
                              blurRadius: 10,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
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

  Widget _buildGlassStat(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.white.withOpacity(0.7),
              fontSize: 9,
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

    return Container(
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
