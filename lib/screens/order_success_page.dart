// lib/screens/order_success_page.dart
//
// Order success confirmation screen with animation.
// Shown after a successful order placement.
//

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class OrderSuccessPage extends StatefulWidget {
  final ApiOrder? order;
  final String? shopName;

  const OrderSuccessPage({super.key, this.order, this.shopName});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                // Success animation
                _buildSuccessAnimation(),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      const Text(
                        'Order Placed!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your order has been successfully placed with ${widget.shopName ?? 'the shop'}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Order details card
                if (order != null) _buildOrderCard(order),
                const Spacer(),
                // Actions
                _buildActions(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _circleController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successGreen,
              AppTheme.successGreen.withGreen(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.successGreen.withOpacity(0.35),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _checkController,
          builder: (_, __) => Opacity(
            opacity: _checkController.value,
            child: Transform.scale(
              scale: _checkController.value,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(ApiOrder order) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _detailRow('Order ID', '#${order.id.split('-').first.toUpperCase()}'),
            const Divider(height: 20, color: AppTheme.veryLightGray),
            _detailRow('Status', order.status),
            const Divider(height: 20, color: AppTheme.veryLightGray),
            _detailRow(
              'Total',
              '₹${order.totalAmount.toStringAsFixed(2)}',
              valueStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 800),
      child: Column(
        children: [
          // Back to Shopping
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to main screen (stores tab)
                MainScreen.pageIndexNotifier.value = 1;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Go to orders
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                MainScreen.pageIndexNotifier.value = 0; // Home
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (_) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
