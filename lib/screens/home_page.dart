import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/promo_banner.dart';
import '../widgets/store_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'shop_details_page.dart';
import 'notifications_page.dart';
import 'see_all_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentCarouselIndex = 0;
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _bannerData = [
    {
      "title": "Summer Fashion Sale",
      "subtitle": "50% Off Limited Time",
      "image": "https://img.freepik.com/free-vector/modern-fashion-design-concept_23-2148464687.jpg",
      "color": AppTheme.primaryBlue,
      "accent": AppTheme.softRoyalBlue,
    },
    {
      "title": "Fresh Groceries Daily",
      "subtitle": "Delivered to Your Door",
      "image": "https://img.freepik.com/free-vector/delivery-service-with-mask-concept_23-2148505104.jpg",
      "color": const Color(0xFF0D5C73),
      "accent": AppTheme.mutedCyan,
    },
    {
      "title": "Electronic Deals Week",
      "subtitle": "Tech Sale – 30% Off",
      "image": "https://img.freepik.com/free-vector/smart-home-system-concept-abstract-illustration_335657-3705.jpg",
      "color": const Color(0xFF1A3A52),
      "accent": AppTheme.lightBlue,
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {"label": "All", "icon": LucideIcons.layoutGrid},
    {"label": "Grocery", "icon": LucideIcons.shoppingBag},
    {"label": "Bakery", "icon": LucideIcons.cake},
    {"label": "Pharmacy", "icon": LucideIcons.cross},
    {"label": "Electronics", "icon": LucideIcons.cpu},
    {"label": "Fashion", "icon": LucideIcons.shirt},
  ];

  final List<Map<String, dynamic>> _stores = [
    {
      "id": "1",
      "name": "Grace Super Market",
      "image": "https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&q=80&w=1000",
      "rating": 4.8,
      "reviews": 1200,
      "deliveryTime": 15,
      "distance": 1.2,
      "categories": ["Groceries", "Fresh Produce", "Bakery"],
      "isOpen": true,
      "isVerified": true,
      "time": "15min",
    },
    {
      "id": "2",
      "name": "Fresh Choice Market",
      "image": "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1000",
      "rating": 4.5,
      "reviews": 850,
      "deliveryTime": 25,
      "distance": 0.8,
      "categories": ["Organic", "Vegetables", "Dairy"],
      "isOpen": true,
      "isVerified": true,
      "time": "25min",
    },
    {
      "id": "3",
      "name": "Sweet Tooth Bakery",
      "image": "https://images.unsplash.com/photo-1555507036-ab1e4006aaeb?auto=format&fit=crop&q=80&w=1000",
      "rating": 4.9,
      "reviews": 2100,
      "deliveryTime": 10,
      "distance": 0.5,
      "categories": ["Cakes", "Pastries", "Snacks"],
      "isOpen": true,
      "isVerified": true,
      "time": "10min",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCurvedHeaderAndCarousel(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.xxl),
                _buildCategoryRow(),
                const SizedBox(height: AppTheme.xxl),
                _buildDealsSection(),
                const SizedBox(height: AppTheme.xxl),
                _buildStoresHeader(),
                const SizedBox(height: AppTheme.lg),
                _buildStoresList(),
                const SizedBox(height: AppTheme.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedHeaderAndCarousel() {
    return ClipPath(
      clipper: UpwardCurveClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.softRoyalBlue,
            ],
          ),
        ),
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.xl,
                vertical: AppTheme.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingRow(),
                  const SizedBox(height: AppTheme.xl),
                  _buildSearchBarFullInHeader(),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            _buildCarouselSection(),
            const SizedBox(height: AppTheme.xxxl), // Extra padding for the curve cutout
          ],
        ),
      ),
    ));
  }

  Widget _buildGreetingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInLeft(
              duration: AppDurations.normal,
              child: Text(
                'Good morning 👋',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: AppTheme.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FadeInLeft(
              delay: const Duration(milliseconds: 80),
              duration: AppDurations.normal,
              child: const Text(
                'Deepak Roshan',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  color: AppTheme.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeInUp(
              duration: AppDurations.normal,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    color: AppTheme.paleCyan,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delivering to ',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppTheme.white.withOpacity(0.7),
                    ),
                  ),
                  const Text(
                    'Home • 12th Street',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppTheme.paleCyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.white.withOpacity(0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        FadeInRight(
          duration: AppDurations.normal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    LucideIcons.bell,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.4),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://img.freepik.com/free-vector/businessman-character-avatar-isolated_24877-60111.jpg",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBarFullInHeader() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTheme.lg),
          const Icon(LucideIcons.search, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search stores, products...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(LucideIcons.sliders, size: 14, color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeeAllPage(
                      title: 'All Categories',
                      isGrid: true,
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      items: _categories.map((c) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(color: AppTheme.veryLightGray),
                            boxShadow: AppTheme.shadowSmall,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(c['icon'] as IconData, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: AppTheme.sm),
                              Text(c['label'] as String, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCategory == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
                child: AnimatedContainer(
                  duration: AppDurations.normal,
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: AppTheme.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.lg,
                    vertical: AppTheme.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.veryLightGray,
                    ),
                    boxShadow: isSelected ? AppTheme.shadowMedium : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _categories[index]['icon'] as IconData,
                        size: 14,
                        color: isSelected ? AppTheme.white : AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _categories[index]['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.white : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselSection() {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 190,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: AppDurations.slow,
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, _) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
          items: _bannerData.map((data) {
            return PromoBanner(
              title: data['title'],
              subtitle: data['subtitle'],
              imageUrl: data['image'],
              baseColor: data['color'],
              accentColor: data['accent'],
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerData.length,
            (index) => AnimatedContainer(
              duration: AppDurations.fast,
              height: 6,
              width: _currentCarouselIndex == index ? 20 : 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _currentCarouselIndex == index
                    ? AppTheme.white
                    : AppTheme.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDealsSection() {
    final deals = [
      {
        "title": "Weekly Essentials",
        "subtitle": "Starting at ₹49",
        "image": "https://img.freepik.com/free-photo/foldable-smartphone-with-digital-screen-design_53876-96942.jpg",
        "badge": "20% OFF",
        "badgeColor": AppTheme.errorRed,
      },
      {
        "title": "Fresh Flowers",
        "subtitle": "Starting at ₹99",
        "image": "https://img.freepik.com/free-photo/large-bouquet-red-roses-with-chocolates_114579-72274.jpg",
        "badge": "40% OFF",
        "badgeColor": AppTheme.mutedCyan,
      },
      {
        "title": "Organic Juice",
        "subtitle": "Starting at ₹79",
        "image": "https://img.freepik.com/free-photo/colorful-fruit-drinks-fresh-healthy_23-2148529565.jpg",
        "badge": "NEW",
        "badgeColor": AppTheme.primaryBlue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Deals",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  "Limited time offers",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeeAllPage(
                      title: 'Today\'s Deals',
                      isGrid: true,
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      items: deals.map((d) => _buildDealCard(d)).toList(),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  'See all',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: deals.length,
            itemBuilder: (context, index) {
              return FadeInRight(
                delay: Duration(milliseconds: 80 * index),
                child: _buildDealCard(deals[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: AppTheme.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                deal['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.bgSecondary),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.darkGray.withOpacity(0.75),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: deal['badgeColor'] as Color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        deal['badge'] as String,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      deal['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deal['subtitle'] as String,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    Row(
                      children: [
                        Text(
                          'Shop now',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppTheme.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          LucideIcons.arrowRight,
                          color: AppTheme.white.withOpacity(0.9),
                          size: 12,
                        ),
                      ],
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

  Widget _buildStoresHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Stores',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Discover the best around you',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeeAllPage(
                  title: 'Nearby Stores',
                  isGrid: false,
                  items: _stores.map((s) => StoreCard(
                    name: s['name'] as String,
                    imageUrl: s['image'] as String,
                    rating: s['rating'].toString(),
                    reviews: '${s['reviews']}+',
                    time: s['time'] as String,
                    distance: '${s['distance']}km',
                    categories: (s['categories'] as List<String>).take(2).toList(),
                    isOpen: s['isOpen'] as bool,
                    isVerified: s['isVerified'] as bool,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopDetailsPage(
                            store: s,
                            heroTag: 'home-seeall-store-${s["id"]}',
                          ),
                        ),
                      );
                    },
                  )).toList(),
                ),
              ),
            );
          },
          child: Text(
            'View all',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoresList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        return FadeInUp(
          delay: Duration(milliseconds: 80 * index),
          child: StoreCard(
            name: store['name'] as String,
            imageUrl: store['image'] as String,
            rating: (store['rating'] as double).toString(),
            reviews: store['reviews'].toString(),
            time: store['time'] as String,
            distance: '${store["distance"]}km',
            categories: store['categories'] as List<String>,
            isOpen: store['isOpen'] as bool,
            isVerified: store['isVerified'] as bool,
            heroTag: 'home-store-${store["id"]}',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => ShopDetailsPage(
                    store: store,
                    heroTag: 'home-store-${store["id"]}',
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: AppDurations.normal,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class UpwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    
    // Draw an upward (concave) semicircle
    path.quadraticBezierTo(
      size.width / 2, 
      size.height - 50, 
      size.width, 
      size.height,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
