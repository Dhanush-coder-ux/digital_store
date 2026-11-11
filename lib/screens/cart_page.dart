import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../models/api_cart_provider.dart';
import '../models/shop_provider.dart';
import '../models/shop_model.dart';
import '../l10n/app_translations.dart';
import '../theme/app_theme.dart';
import 'api_checkout_page.dart';
import 'main_screen.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ApiCartProvider, ShopProvider>(
      builder: (context, cart, shopProvider, child) {
        if (cart.isLoading && cart.items.isEmpty && cart.localItems.isEmpty) {
          return const Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          );
        }

        if (cart.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            appBar: AppBar(
              backgroundColor: AppTheme.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                context.tr('my_cart'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AppTheme.veryLightGray, height: 1),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          LucideIcons.shoppingBag,
                          size: 48,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        context.tr('cart_empty'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        context.tr('cart_empty_desc'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            MainScreen.pageIndexNotifier.value = 0;
                          },
                          icon: const Icon(LucideIcons.arrowLeft, size: 18),
                          label: Text(
                            context.tr('start_shopping'),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final shopId = cart.shopId;
        Shop? shop;
        if (shopId != null && shopId.isNotEmpty) {
          shop = shopProvider.shops.where((s) => s.id == shopId).firstOrNull;
        }

        shop ??= Shop(
          id: shopId ?? '',
          name: 'Store',
          categories: const [],
        );

        return ApiCheckoutPage(
          shop: shop,
          isTab: true,
        );
      },
    );
  }
}
