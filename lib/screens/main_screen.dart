import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_bottom_bar.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/providers.dart';
import '../models/api_cart_provider.dart';
import '../models/shop_provider.dart';
import '../models/profile_provider.dart';
import '../models/favorites_api_provider.dart';
import '../core/auth/auth_provider.dart';
import 'home_page.dart';
import 'api_checkout_page.dart';
import 'cart_page.dart';
import 'categories_page.dart';
import 'stores_page.dart';
import 'search_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final ValueNotifier<int> pageIndexNotifier = ValueNotifier<int>(0);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const CategoriesPage(),
    const StoresPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    MainScreen.pageIndexNotifier.addListener(_onPageIndexChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        // Fetch profile first so we can check existing addresses
        await context.read<ProfileProvider>().fetchProfile(userId);
        context.read<FavoritesApiProvider>().fetchFavorites(userId);
      }

      final locProvider = context.read<LocationProvider>();
      final locationAddress = await locProvider.requestLocationAndGeocode();
      
      // Fetch shops with location
      context.read<ShopProvider>().fetchAllShops(
        lat: locProvider.latitude,
        lng: locProvider.longitude,
      );

      if (locationAddress != null && userId != null) {
        final profile = context.read<ProfileProvider>();
        final existing = profile.addresses.any((a) => 
          a.fullAddress == locationAddress.fullAddress || 
          (a.city.isNotEmpty && a.city == locationAddress.city && a.pincode == locationAddress.pincode)
        );
        
        if (!existing) {
          final newAddress = locationAddress.copyWith(
            addressId: DateTime.now().millisecondsSinceEpoch.toString(),
            isDefault: profile.addresses.isEmpty,
          );
          await profile.addAddress(userId, newAddress);
        }
      }
    });
  }

  void _onPageIndexChanged() {
    setState(() {
      _currentIndex = MainScreen.pageIndexNotifier.value;
    });
  }

  @override
  void dispose() {
    MainScreen.pageIndexNotifier.removeListener(_onPageIndexChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          _buildFloatingCartBar(context),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          MainScreen.pageIndexNotifier.value = index;
        },
      ),
    );
  }

  Widget _buildFloatingCartBar(BuildContext context) {
    if (_currentIndex == 3) return const SizedBox.shrink();
    return Consumer<ApiCartProvider>(
      builder: (context, cart, child) {
        if (cart.isEmpty) return const SizedBox.shrink();

        String? imageUrl;
        if (cart.items.isNotEmpty) {
          imageUrl = cart.items.first.productImage;
        } else if (cart.localItems.isNotEmpty) {
          final p = cart.localItems.first.product;
          imageUrl = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;
        }
        
        final totalQty = cart.itemCount;
        final totalAmount = cart.subtotal;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () {
                MainScreen.pageIndexNotifier.value = 3;
              },
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.white,
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const Icon(LucideIcons.shoppingBag, color: AppTheme.primary, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalQty Item${totalQty > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppTheme.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'View Cart',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronRight, color: AppTheme.white, size: 20),
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
