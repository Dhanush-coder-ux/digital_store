import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/store_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'shop_details_page.dart';
import 'notifications_page.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final List<String> _categories = ['All', 'Grocery', 'Pharmacy', 'Bakery', 'Electronics'];
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allStores = [
    {
      "name": "Grace Super Market",
      "image": "https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&q=80&w=1000",
      "rating": "4.8",
      "reviews": "1.2k",
      "time": "15min",
      "distance": "1.2km",
      "categories": ["Groceries", "Fresh Produce", "Bakery"],
      "categoryTag": "Grocery",
      "isOpen": true,
      "isVerified": true,
      "id": "1",
    },
    {
      "name": "Ponnu Super Market",
      "image": "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=1000",
      "rating": "4.5",
      "reviews": "850",
      "time": "25min",
      "distance": "0.8km",
      "categories": ["Organic", "Vegetables", "Dairy"],
      "categoryTag": "Grocery",
      "isOpen": false,
      "isVerified": false,
      "id": "2",
    },
    {
      "name": "Daily Needs Mart",
      "image": "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&q=80&w=1000",
      "rating": "4.2",
      "reviews": "420",
      "time": "30min",
      "distance": "2.5km",
      "categories": ["Household", "Essentials", "Care"],
      "categoryTag": "Pharmacy",
      "isOpen": true,
      "isVerified": false,
      "id": "3",
    },
    {
      "name": "Sweet Tooth Bakery",
      "image": "https://images.unsplash.com/photo-1555507036-ab1e4006aaeb?auto=format&fit=crop&q=80&w=1000",
      "rating": "4.9",
      "reviews": "2.1k",
      "time": "10min",
      "distance": "0.5km",
      "categories": ["Cakes", "Pastries", "Snacks"],
      "categoryTag": "Bakery",
      "isOpen": true,
      "isVerified": true,
      "id": "4",
    },
  ];

  List<Map<String, dynamic>> get _filteredStores {
    return _allStores.where((store) {
      final matchCategory = _selectedIndex == 0 ||
          store['categoryTag'] == _categories[_selectedIndex];
      final matchSearch = _searchQuery.isEmpty ||
          (store['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryChips(),
          _buildResultsRow(),
          Expanded(child: _buildStoresList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.xl, AppTheme.lg, AppTheme.xl, AppTheme.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stores',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.white),
                  ),
                  Text(
                    'Find your favourite store',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.white.withOpacity(0.8)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.xl, AppTheme.lg, AppTheme.xl, 0,
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.veryLightGray),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Row(
          children: [
            const SizedBox(width: AppTheme.lg),
            const Icon(LucideIcons.search, color: AppTheme.textTertiary, size: 18),
            const SizedBox(width: AppTheme.sm),
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
                  hintText: 'Search stores by name...',
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppTheme.veryLightGray),
                ),
              ),
              child: const Icon(
                LucideIcons.slidersHorizontal,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: AppTheme.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
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
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
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

  Widget _buildResultsRow() {
    final count = _filteredStores.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.xl, AppTheme.md, AppTheme.xl, 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count store${count != 1 ? 's' : ''} found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              const Icon(LucideIcons.listFilter, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 4),
              Text(
                'Sort: Distance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoresList() {
    final stores = _filteredStores;

    if (stores.isEmpty) {
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
                child: const Icon(
                  LucideIcons.store,
                  size: 36,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              Text(
                'No stores found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                'Try a different category or search term',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.xl,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return FadeInUp(
          delay: Duration(milliseconds: 80 * index),
          child: StoreCard(
            name: store['name'] as String,
            imageUrl: store['image'] as String,
            rating: store['rating'] as String,
            reviews: store['reviews'] as String,
            time: store['time'] as String,
            distance: store['distance'] as String,
            categories: store['categories'] as List<String>,
            isOpen: store['isOpen'] as bool,
            isVerified: store['isVerified'] as bool,
            heroTag: 'stores-store-${store["id"]}',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) =>
                      ShopDetailsPage(store: store, heroTag: 'stores-store-${store["id"]}'),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
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
