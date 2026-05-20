import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../models/providers.dart';
import '../widgets/store_card.dart';
import 'shop_details_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
              ),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Favorites',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                AppTheme.xl, 0, AppTheme.xl, AppTheme.md,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textTertiary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSmall,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Stores'),
                  Tab(text: 'Products'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildStoresTab(context),
            _buildProductsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresTab(BuildContext context) {
    final favStores = context.watch<FavoritesProvider>().stores;

    if (favStores.isEmpty) {
      return _buildEmptyState(
        context,
        icon: LucideIcons.store,
        title: 'No favourite stores yet',
        subtitle: 'Stores you like will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.xl),
      physics: const BouncingScrollPhysics(),
      itemCount: favStores.length,
      itemBuilder: (context, index) {
        final fav = favStores[index];
        return FadeInUp(
          delay: Duration(milliseconds: 80 * index),
          child: StoreCard(
            name: fav.name,
            imageUrl: fav.image ?? '',
            rating: fav.rating?.toString() ?? '4.5',
            reviews: '1k+',
            time: '30min',
            distance: '2km',
            categories: const ['Groceries'],
            isOpen: true,
            isVerified: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopDetailsPage(
                    store: {
                      'id': fav.id,
                      'name': fav.name,
                      'image': fav.image,
                      'rating': fav.rating,
                    },
                    heroTag: 'fav-store-${fav.id}',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsTab(BuildContext context) {
    final favProducts = context.watch<FavoritesProvider>().products;

    if (favProducts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: LucideIcons.heart,
        title: 'No favourite products yet',
        subtitle: 'Products you like will appear here',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.xl),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.md,
        mainAxisSpacing: AppTheme.md,
      ),
      itemCount: favProducts.length,
      itemBuilder: (context, index) {
        final fav = favProducts[index];
        return FadeInUp(
          delay: Duration(milliseconds: 80 * index),
          child: _buildProductCard(context, fav),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, FavoriteItem fav) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                  child: Image.network(
                    fav.image ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.bgSecondary,
                      child: const Center(
                        child: Icon(
                          LucideIcons.image,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppTheme.sm,
                  right: AppTheme.sm,
                  child: GestureDetector(
                    onTap: () {
                      context.read<FavoritesProvider>().removeFavorite(fav.id);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowSmall,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.errorRed,
                        size: 16,
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
                  fav.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹99.00',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              child: Icon(icon, size: 36, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
