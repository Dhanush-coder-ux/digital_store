import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';

import '../models/providers.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import 'shop_details_page.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String storeName;
  final String storeId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.storeName,
    required this.storeId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  String _selectedSchedule = 'Today';
  String? _selectedTimeSlot;
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  static const List<String> _scheduleOptions = [
    'Today',
    'Tomorrow',
    'This weekend',
    'Next week',
  ];

  static const Map<String, List<String>> _timeSlots = {
    'Today': ['10:00 AM - 11:00 AM', '02:00 PM - 03:00 PM', '06:00 PM - 07:00 PM'],
    'Tomorrow': ['09:00 AM - 10:00 AM', '12:00 PM - 01:00 PM', '05:00 PM - 06:00 PM'],
    'This weekend': ['10:00 AM - 12:00 PM', '02:00 PM - 04:00 PM'],
    'Next week': ['Flexible timing'],
  };

  String get _name => widget.product['name'] as String? ?? 'Product';
  String get _category => widget.product['category'] as String? ?? 'General';
  String get _weight => widget.product['weight'] as String? ?? '';
  String get _image => widget.product['image'] as String? ?? '';
  String get _description =>
      widget.product['description'] as String? ??
      'Freshly prepared by the retailer with careful packing and quality checks before dispatch.';
      
  List<String> get _images {
    final imgs = widget.product['images'] as List<dynamic>?;
    if (imgs != null && imgs.isNotEmpty) {
      return imgs.cast<String>();
    }
    // Fallback dummy images for 360 view demonstration
    return [
      _image,
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=800&q=80',
    ];
  }

  double get _price => (widget.product['price'] as num?)?.toDouble() ?? 0;
  bool get _requiresPreOrder => widget.product['requiresPreOrder'] == true;
  int get _noticeHours => widget.product['noticeHours'] as int? ?? 0;
  String get _tag => widget.product['tag'] as String? ?? '';
  bool get _isSoldOut => widget.product['isSoldOut'] == true;

  @override
  void initState() {
    super.initState();
    if (_requiresPreOrder) {
      _selectedSchedule = 'Tomorrow';
    }
    // Set default time slot
    _selectedTimeSlot = _timeSlots[_selectedSchedule]?.first;
  }

  @override
  Widget build(BuildContext context) {
    final total = _price * _quantity;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndRating(context),
                  const SizedBox(height: AppTheme.lg),
                  _buildPriceAndTag(context),
                  const SizedBox(height: AppTheme.lg),
                  _buildPriceCompare(context),
                  const SizedBox(height: AppTheme.xl),
                  _buildProductionNotice(context),
                  const SizedBox(height: AppTheme.xl),
                  _buildSchedulePicker(context),
                  const SizedBox(height: AppTheme.lg),
                  if (_requiresPreOrder) _buildTimeSlotPicker(context),
                  if (_requiresPreOrder) const SizedBox(height: AppTheme.xl),
                  _buildProductDetails(context),
                  const SizedBox(height: AppTheme.xl),
                  _buildRetailerPromise(context),
                  const SizedBox(height: AppTheme.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, total),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppTheme.xs),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppTheme.white.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(AppTheme.xs),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: AppTheme.white.withOpacity(0.2),
                child: Consumer<FavoritesProvider>(
                  builder: (context, favProvider, child) {
                    final productId = widget.product['id']?.toString() ?? _name;
                    final isFav = favProvider.isFavorited(productId);
                    
                    return IconButton(
                      icon: Icon(
                        isFav ? LucideIcons.heart : LucideIcons.heartHandshake,
                        color: AppTheme.white,
                      ),
                      onPressed: () {
                        favProvider.toggleFavorite(
                          FavoriteItem(
                            id: productId,
                            name: _name,
                            type: 'product',
                            image: _image,
                            rating: 4.8,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                enableInfiniteScroll: _images.length > 1,
                autoPlay: _images.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                pauseAutoPlayOnTouch: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: _images.map((img) {
                return Builder(
                  builder: (BuildContext context) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.bgSecondary,
                          child: const Icon(
                            LucideIcons.package,
                            color: AppTheme.textTertiary,
                            size: 48,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkGray.withOpacity(0.18),
                    Colors.transparent,
                    AppTheme.darkGray.withOpacity(0.68),
                  ],
                ),
              ),
            ),
            if (_images.length > 1) ...[
              Positioned(
                left: AppTheme.md,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: AppTheme.white.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
                          onPressed: () => _carouselController.previousPage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppTheme.md,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: AppTheme.white.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: const Icon(LucideIcons.chevronRight, color: AppTheme.white),
                          onPressed: () => _carouselController.nextPage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _images.asMap().entries.map((entry) {
                    return Container(
                      width: _currentImageIndex == entry.key ? 20.0 : 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppTheme.white.withValues(
                          alpha: _currentImageIndex == entry.key ? 0.9 : 0.4,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            Positioned(
              left: AppTheme.xl,
              right: AppTheme.xl,
              bottom: AppTheme.xl,
              child: Row(
                children: [
                  if (_tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                        vertical: AppTheme.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: Text(
                        _tag,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppTheme.sm),
                  _buildPill(LucideIcons.store, widget.storeName),
                  const SizedBox(width: AppTheme.sm),
                  if (_requiresPreOrder)
                    _buildPill(
                      LucideIcons.clock3,
                      '${_noticeHours}h notice',
                      color: AppTheme.warningOrange,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndRating(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: AppTheme.sm),
        Row(
          children: [
            Icon(LucideIcons.star, color: AppTheme.warningOrange, size: 16),
            const SizedBox(width: 4),
            Text(
              '4.8 (234 reviews)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          [_category, _weight].where((item) => item.isNotEmpty).join(' • '),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildPriceAndTag(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${_price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                  ),
            ),
            if (_isSoldOut)
              Container(
                margin: const EdgeInsets.only(top: AppTheme.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'Sold out',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductionNotice(BuildContext context) {
    final title = _requiresPreOrder
        ? 'Production item'
        : 'Ready for quick delivery';
    final subtitle = _requiresPreOrder
        ? 'This retailer prepares it after order confirmation, so choose a scheduled slot.'
        : 'Can be packed from available stock. You can still schedule it for later.';

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: (_requiresPreOrder ? AppTheme.warningOrange : AppTheme.successGreen)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: (_requiresPreOrder ? AppTheme.warningOrange : AppTheme.successGreen)
              .withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              _requiresPreOrder ? LucideIcons.timer : LucideIcons.packageCheck,
              color: _requiresPreOrder
                  ? AppTheme.warningOrange
                  : AppTheme.successGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _requiresPreOrder ? 'Schedule production' : 'Schedule delivery',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Wrap(
          spacing: AppTheme.sm,
          runSpacing: AppTheme.sm,
          children: _scheduleOptions.map((option) {
            final isDisabled = _requiresPreOrder && option == 'Today';
            final isSelected = _selectedSchedule == option;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() {
                        _selectedSchedule = option;
                        _selectedTimeSlot =
                            _timeSlots[option]?.first;
                      });
                    },
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.lg,
                    vertical: AppTheme.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.veryLightGray,
                    ),
                    boxShadow: isSelected ? AppTheme.shadowSmall : null,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? AppTheme.textTertiary.withOpacity(0.55)
                          : isSelected
                              ? AppTheme.white
                              : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlotPicker(BuildContext context) {
    final slots = _timeSlots[_selectedSchedule] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select time slot',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Wrap(
          spacing: AppTheme.md,
          runSpacing: AppTheme.md,
          children: slots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;

            return GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = slot),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.lg,
                  vertical: AppTheme.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.softRoyalBlue : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.veryLightGray,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      slot,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProductDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this product',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.veryLightGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: AppTheme.lg),
              Divider(color: AppTheme.veryLightGray, height: 1),
              const SizedBox(height: AppTheme.lg),
              Row(
                children: [
                  _buildDetailItem(LucideIcons.leaf, 'Fresh', 'Quality checked'),
                  const SizedBox(width: AppTheme.xl),
                  _buildDetailItem(LucideIcons.truck, 'Fast', 'Ready to dispatch'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerPromise(BuildContext context) {
    final items = [
      (LucideIcons.clipboardCheck, 'Retailer confirms prep slot'),
      (LucideIcons.bellRing, 'You get status updates'),
      (LucideIcons.sparkles, 'Fresh batch planning'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Retailer workflow',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.sm),
            child: Row(
              children: [
                Icon(item.$1, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: AppTheme.sm),
                Expanded(
                  child: Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, double total) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.shadowLarge,
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity == 1
                        ? null
                        : () => setState(() => _quantity--),
                    icon: const Icon(LucideIcons.minus),
                    iconSize: 18,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(LucideIcons.plus),
                    iconSize: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSoldOut ? null : () => _addScheduledItem(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSoldOut ? AppTheme.textTertiary : AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.veryLightGray,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSoldOut ? LucideIcons.xCircle : LucideIcons.shoppingCart,
                      size: 18,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      _isSoldOut
                          ? 'Sold Out'
                          : 'Add • ₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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

  Widget _buildPill(IconData icon, String label, {Color color = AppTheme.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.42),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _addScheduledItem(BuildContext context) {
    final cart = context.read<CartProvider>();
    final product = Product(
      id: '${widget.storeId}_$_name',
      name: _name,
      category: _category,
      price: _price,
      image: _image,
      description: _description,
      requiresPreOrder: _requiresPreOrder,
      noticeHours: _noticeHours,
    );

    final schedulingInfo =
        _requiresPreOrder ? '$_selectedSchedule at $_selectedTimeSlot' : _selectedSchedule;

    cart.addToCart(
      product,
      widget.storeName,
      quantity: _quantity,
      scheduledFor: schedulingInfo,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added for $_selectedSchedule${_requiresPreOrder ? ' at $_selectedTimeSlot' : ''}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRICE COMPARE
  // ═══════════════════════════════════════════════════════════════════

  /// Generates plausible cross-store price comparisons seeded from this product's price.
  List<Map<String, dynamic>> _getPriceComparisons() {
    final base = _price;
    return [
      {
        'store': widget.storeName,
        'price': base,
        'distance': '0.5km',
        'deliveryTime': '10 min',
        'isCurrentStore': true,
      },
      {
        'store': 'Fresh Choice Market',
        'price': (base * 1.09).ceilToDouble(),
        'distance': '0.8km',
        'deliveryTime': '25 min',
        'isCurrentStore': false,
      },
      {
        'store': 'Grace Super Market',
        'price': (base * 1.18).ceilToDouble(),
        'distance': '1.2km',
        'deliveryTime': '15 min',
        'isCurrentStore': false,
      },
    ]..sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
  }

  Widget _buildPriceCompare(BuildContext context) {
    final comparisons = _getPriceComparisons();
    final minPrice = (comparisons.first['price'] as double);
    final maxPrice = (comparisons.last['price'] as double);
    final saving = maxPrice - minPrice;
    final isCurrentCheapest = comparisons.first['isCurrentStore'] == true;

    return GestureDetector(
      onTap: () => _showPriceCompareSheet(context, comparisons),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon block
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: AppTheme.md),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compare Prices',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCurrentCheapest
                        ? 'Best price here! Save up to ₹${saving.toStringAsFixed(0)} vs others'
                        : 'Available at ${comparisons.length} stores in Coimbatore',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mini store pills preview
                  Row(
                    children: comparisons.take(3).map((c) {
                      final isBest = c['price'] == minPrice;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isBest
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isBest
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '₹${(c['price'] as double).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: isBest ? FontWeight.w800 : FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceCompareSheet(
    BuildContext context,
    List<Map<String, dynamic>> comparisons,
  ) {
    final minPrice = (comparisons.first['price'] as double);
    final maxPrice = (comparisons.last['price'] as double);
    final saving = maxPrice - minPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: AppTheme.xxl,
            right: AppTheme.xxl,
            top: AppTheme.xxl,
            bottom: AppTheme.xxl + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.xl),

              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('📊', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Price comparison · Coimbatore',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.xl),

              // Savings banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.lg,
                  vertical: AppTheme.md,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      color: AppTheme.successGreen,
                      size: 22,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'You save up to ',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: '₹${saving.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.successGreen,
                                fontSize: 16,
                              ),
                            ),
                            const TextSpan(text: ' by choosing the right store.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.xl),

              // Section label
              const Text(
                'STORES IN YOUR CITY',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppTheme.md),

              // Comparison rows
              ...comparisons.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final price = c['price'] as double;
                final isBest = idx == 0;
                final isWorst = idx == comparisons.length - 1;
                final isCurrentStore = c['isCurrentStore'] == true;
                final barFraction = price / maxPrice;

                return GestureDetector(
                  onTap: () {
                    // Navigate to shop detail page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopDetailsPage(
                          store: {
                            'id': 'store-${c['store'].hashCode}',
                            'name': c['store'],
                            'category': 'Supermarket',
                            'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80',
                            'rating': 4.5,
                            'reviews': '1K+',
                            'distance': c['distance'],
                            'deliveryTime': c['deliveryTime'],
                            'isOpen': true,
                            'isVerified': true,
                            'announcements': [],
                          },
                          heroTag: 'compare-store-${c['store'].hashCode}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.md),
                    padding: const EdgeInsets.all(AppTheme.lg),
                    decoration: BoxDecoration(
                      color: isBest
                          ? AppTheme.successGreen.withValues(alpha: 0.05)
                          : isWorst
                              ? AppTheme.errorRed.withValues(alpha: 0.04)
                              : AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: isBest
                            ? AppTheme.successGreen.withValues(alpha: 0.28)
                            : isWorst
                                ? AppTheme.errorRed.withValues(alpha: 0.18)
                                : AppTheme.veryLightGray,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Rank circle
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isBest
                                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                      : isWorst
                                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                          : [
                                              AppTheme.textTertiary,
                                              AppTheme.textTertiary,
                                            ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.md),
                            // Store name + badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          c['store'] as String,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14,
                                            fontWeight: isBest
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrentStore) ...[const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: const Text(
                                            'This store',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 11,
                                        color: AppTheme.textTertiary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        c['distance'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 11,
                                        color: AppTheme.textTertiary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        c['deliveryTime'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Price + badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isBest
                                        ? AppTheme.successGreen
                                        : isWorst
                                            ? AppTheme.errorRed
                                            : AppTheme.textPrimary,
                                  ),
                                ),
                                if (isBest)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ Cheapest',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (isWorst)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.errorRed.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      'Priciest',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.md),
                        // Price bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: barFraction,
                            backgroundColor: AppTheme.veryLightGray,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isBest
                                  ? AppTheme.successGreen
                                  : isWorst
                                      ? AppTheme.errorRed
                                      : const Color(0xFF6366F1),
                            ),
                            minHeight: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Disclaimer
              const SizedBox(height: AppTheme.sm),
              const Text(
                '* Prices are indicative and may vary. Always confirm with the store before ordering.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  color: AppTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppTheme.lg),
            ],
          ),
        );
      },
    );
  }
}
