import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/providers.dart';
import '../widgets/components.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'delivery_address_page.dart';
import 'stores_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text(
          "Shopping Cart",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Cart items list
              Expanded(
                child: _buildCartList(context, cart),
              ),
              // Checkout button
              _buildCheckoutSection(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.shoppingCart,
      title: "Your cart is empty",
      subtitle: "Browse our stores and add items to your cart",
      actionLabel: "Start Shopping",
      onAction: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StoresPage()),
        );
      },
    );
  }

Widget _buildDeliveryBanner(BuildContext context){
    return FadeInDown(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg,
          vertical: AppTheme.md,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sm),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Delivering to",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Text(
                    "Home • 12th Street",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
      children: [
        const SizedBox(height: AppTheme.lg),
        ...cart.groupedByStore.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.xl),
            child: FadeInUp(
              child: _buildStoreGroup(context, entry.key, entry.value),
            ),
          );
        }).toList(),
        const SizedBox(height: AppTheme.lg),
      ],
    );
  }

  Widget _buildStoreGroup(
    BuildContext context,
    String storeName,
    List<CartItem> items,
  ) {
    int totalItems = items.fold(0, (sum, item) => sum + item.quantity);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.all(AppTheme.lg),
          childrenPadding: const EdgeInsets.only(left: AppTheme.lg, right: AppTheme.lg, bottom: AppTheme.lg),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.md),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  LucideIcons.store,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.xs),
                    Text(
                      "$totalItems ${totalItems == 1 ? 'Item' : 'Items'} • Free Delivery",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: AppTheme.lg),
            // Items list
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.lg),
                child: _buildCartItemRow(context, item),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemRow(BuildContext context, CartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            width: 80,
            height: 80,
            color: AppTheme.veryLightGray,
            child: Image.network(
              item.product.image ?? "",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  LucideIcons.package,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        // Product details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                item.product.category,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              if (item.scheduledFor != null && item.scheduledFor!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: AppTheme.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.warningOrange.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: AppTheme.warningOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.scheduledFor!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppTheme.warningOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹${item.product.price.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _buildQuantityControl(context, item),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControl(BuildContext context, CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.veryLightGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.veryLightGray.withOpacity(0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: item.quantity > 1
              ? () {
                  context.read<CartProvider>().updateQuantity(
                    item,
                    item.quantity - 1,
                  );
                }
              : () {
                  context.read<CartProvider>().removeFromCart(item);
                },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: AppTheme.sm,
              ),
              child: Icon(
                item.quantity == 1 ? LucideIcons.trash2 : LucideIcons.minus,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.veryLightGray,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
            child: Text(
              "${item.quantity}",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppTheme.veryLightGray,
          ),
          GestureDetector(
            onTap: () {
              context.read<CartProvider>().updateQuantity(
                item,
                item.quantity + 1,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: AppTheme.sm,
              ),
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    final deliveryFee = AppNumbers.deliveryFee;
    final total = cart.subtotal + deliveryFee;

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border(
            top: BorderSide(
              color: AppTheme.veryLightGray.withOpacity(0.5),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price breakdown
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  collapsedBackgroundColor: AppTheme.bgSecondary,
                  backgroundColor: AppTheme.bgSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: 0),
                  childrenPadding: const EdgeInsets.only(left: AppTheme.lg, right: AppTheme.lg, bottom: AppTheme.lg),
                  title: _buildPriceRow(
                    context,
                    "Total",
                    "₹${total.toStringAsFixed(2)}",
                    isTotal: true,
                  ),
                  children: [
                    Divider(color: AppTheme.textTertiary.withOpacity(0.2)),
                    const SizedBox(height: AppTheme.md),
                    _buildPriceRow(context, "Subtotal", "₹${cart.subtotal.toStringAsFixed(2)}"),
                    const SizedBox(height: AppTheme.md),
                    _buildPriceRow(context, "Delivery Fee", "₹${deliveryFee.toStringAsFixed(2)}"),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              // Checkout button
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: "Proceed to Checkout",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeliveryAddressPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
