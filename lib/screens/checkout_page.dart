import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/providers.dart';
import '../widgets/order_processing_overlay.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'main_screen.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentMethod = 0;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final double itemTotal = cart.subtotal;
    final double deliveryFee = AppNumbers.deliveryFee;
    final double totalAmount = itemTotal + deliveryFee;

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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(child: _buildSectionTitle('Delivery Address')),
            const SizedBox(height: AppTheme.md),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildAddressCard(),
            ),
            const SizedBox(height: AppTheme.xxl),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildSectionTitle('Payment Method'),
            ),
            const SizedBox(height: AppTheme.md),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildPaymentMethods(),
            ),
            const SizedBox(height: AppTheme.xxl),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSectionTitle('Order Summary'),
            ),
            const SizedBox(height: AppTheme.md),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildOrderSummary(itemTotal, deliveryFee, totalAmount),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(totalAmount),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: AppTheme.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home • 12th Street',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '12th Street, Block A, Beverly Hills\nCA 90210',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            'Change',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {'icon': LucideIcons.creditCard, 'title': 'Credit / Debit Card', 'subtitle': 'Visa, MasterCard'},
      {'icon': LucideIcons.smartphone, 'title': 'Digital Wallet', 'subtitle': 'Apple Pay, Google Pay'},
      {'icon': LucideIcons.banknote, 'title': 'Cash on Delivery', 'subtitle': 'Pay at your door'},
    ];

    return Column(
      children: List.generate(methods.length, (index) {
        final isSelected = _selectedPaymentMethod == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = index),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            margin: const EdgeInsets.only(bottom: AppTheme.md),
            padding: const EdgeInsets.all(AppTheme.lg),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.04) : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [] : AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                Icon(
                  methods[index]['icon'] as IconData,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textTertiary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        methods[index]['title'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        methods[index]['subtitle'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrderSummary(double itemTotal, double deliveryFee, double totalAmount) {
    final cart = context.watch<CartProvider>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List of items in checkout
          ...cart.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item.product.name} (x${item.quantity})",
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        "₹${item.subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (item.scheduledFor != null && item.scheduledFor!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                        vertical: 4,
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
                            size: 11,
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
                  const SizedBox(height: AppTheme.sm),
                  Divider(color: AppTheme.veryLightGray),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: AppTheme.sm),
          _buildSummaryRow('Subtotal', '₹${itemTotal.toStringAsFixed(2)}'),
          const SizedBox(height: AppTheme.md),
          _buildSummaryRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: AppTheme.md),
          Divider(color: AppTheme.textTertiary.withOpacity(0.2)),
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double totalAmount) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.xl),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.shadowXlarge,
          border: Border(top: BorderSide(color: AppTheme.veryLightGray)),
        ),
        child: GestureDetector(
          onTap: () {
            // Place order inside dynamic state history
            context.read<CartProvider>().placeOrder();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return OrderProcessingOverlay(
                  onComplete: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    MainScreen.pageIndexNotifier.value = 3;
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Place Order - ₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                const Icon(LucideIcons.arrowRight, color: AppTheme.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
