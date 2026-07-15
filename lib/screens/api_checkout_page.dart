// lib/screens/api_checkout_page.dart
//
// Checkout page connected to the backend cart session.
// Displays enriched cart items, delivery address, payment method,
// and places the order via the Order Service.
// No authentication required — anonymous customer checkout.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shop_model.dart';
import '../models/api_cart_provider.dart';
import '../models/cart_session_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'order_success_page.dart';

class ApiCheckoutPage extends StatefulWidget {
  final Shop shop;

  const ApiCheckoutPage({super.key, required this.shop});

  @override
  State<ApiCheckoutPage> createState() => _ApiCheckoutPageState();
}

class _ApiCheckoutPageState extends State<ApiCheckoutPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedPayment = 'Cash on Delivery';

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'UPI',
    'Card',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    // Refresh cart items to get latest enriched data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiCartProvider>().refreshCart();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(ApiCartProvider cart) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Map<String, dynamic>? deliveryAddress;
    if (_addressController.text.trim().isNotEmpty) {
      deliveryAddress = {'address': _addressController.text.trim()};
    }

    final success = await cart.placeOrder(
      shopId: widget.shop.id,
      customerName: name,
      customerPhone: phone,
      paymentMethod: _selectedPayment,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      deliveryAddress: deliveryAddress,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            order: cart.lastOrder,
            shopName: widget.shop.name,
          ),
        ),
      );
    } else if (!success && mounted && cart.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.error!),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 4),
        ),
      );
      cart.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
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
            title: const Text(
              'Checkout',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
            centerTitle: true,
          ),
          body: cart.isLoading && cart.items.isEmpty
              ? _buildLoading()
              : cart.isEmpty
                  ? _buildEmptyCart()
                  : _buildContent(cart),
          bottomNavigationBar: cart.isEmpty ? null : _buildPlaceOrderButton(cart),
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shoppingCart, size: 60, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some products before checking out',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ApiCartProvider cart) {
    final subtotal = cart.subtotal;
    final deliveryFee = widget.shop.minDeliveryCharge > 0
        ? widget.shop.minDeliveryCharge
        : AppNumbers.deliveryFee;
    final total = subtotal + deliveryFee;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop info
          _buildShopCard(),
          const SizedBox(height: 16),

          // Cart items
          _buildCartItems(cart),
          const SizedBox(height: 16),

          // Customer details
          _buildCustomerSection(),
          const SizedBox(height: 16),

          // Delivery address
          _buildAddressSection(),
          const SizedBox(height: 16),

          // Payment method
          _buildPaymentSection(),
          const SizedBox(height: 16),

          // Order note
          _buildNoteSection(),
          const SizedBox(height: 16),

          // Price summary
          _buildPriceSummary(subtotal, deliveryFee, total),
        ],
      ),
    );
  }

  Widget _buildShopCard() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: widget.shop.logoUrl != null && widget.shop.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: widget.shop.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(Icons.storefront_rounded,
                      color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shop.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.shop.displayAddress.isNotEmpty
                      ? widget.shop.displayAddress
                      : 'Shop order',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems(ApiCartProvider cart) {
    return FadeInUp(
      child: _sectionCard(
        title: 'Order Items',
        icon: LucideIcons.shoppingBag,
        child: Column(
          children: [
            ...cart.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _CartItemRow(item: item, cart: cart),
                  if (i < cart.items.length - 1)
                    Divider(color: AppTheme.veryLightGray, height: 16),
                ],
              );
            }).toList(),
            // Local mirror items (before backend sync)
            if (cart.items.isEmpty)
              ...cart.localItems.map((e) => _LocalItemRow(entry: e)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 50),
      child: _sectionCard(
        title: 'Customer Details',
        icon: LucideIcons.user,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Full Name',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Phone Number',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: _sectionCard(
        title: 'Delivery Address',
        icon: LucideIcons.mapPin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _addressController,
              maxLines: 3,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter delivery address...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 150),
      child: _sectionCard(
        title: 'Payment Method',
        icon: LucideIcons.creditCard,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final selected = method == _selectedPayment;
            return GestureDetector(
              onTap: () => setState(() => _selectedPayment = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryBlue : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                  ),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: _sectionCard(
        title: 'Order Note (optional)',
        icon: LucideIcons.fileText,
        child: TextField(
          controller: _noteController,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Any special instructions...',
            hintStyle: TextStyle(
              fontFamily: 'Outfit',
              color: AppTheme.textTertiary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary(double subtotal, double deliveryFee, double total) {
    return FadeInUp(
      delay: const Duration(milliseconds: 250),
      child: _sectionCard(
        title: 'Price Summary',
        icon: LucideIcons.receipt,
        child: Column(
          children: [
            _priceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _priceRow('Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppTheme.veryLightGray),
            ),
            _priceRow(
              'Total',
              '₹${total.toStringAsFixed(2)}',
              isBold: true,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton(ApiCartProvider cart) {
    final isPlacing = cart.state == CartState.placingOrder;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isPlacing ? null : () => _placeOrder(cart),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: AppTheme.white,
            disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: isPlacing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Placing Order...',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Place Order · ₹${(cart.subtotal + AppNumbers.deliveryFee).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Cart Item Row ──────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartSessionItem item;
  final ApiCartProvider cart;

  const _CartItemRow({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.bgSecondary,
          ),
          clipBehavior: Clip.antiAlias,
          child: item.productImage != null
              ? CachedNetworkImage(
                  imageUrl: item.productImage!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    LucideIcons.package,
                    color: AppTheme.textTertiary,
                    size: 24,
                  ),
                )
              : Icon(LucideIcons.package, color: AppTheme.textTertiary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.variantName != null || item.batchName != null || item.serialName != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.variantName != null) 'Variant: ${item.variantName}',
                    if (item.batchName != null) 'Batch: ${item.batchName}',
                    if (item.serialName != null) 'Serial: ${item.serialName}',
                  ].join(' | '),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Qty: ${item.qty.toStringAsFixed(0)}${item.unit != null ? ' ${item.unit}' : ''}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${item.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => cart.removeItem(productId: item.productId),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(LucideIcons.trash2, size: 14, color: AppTheme.errorRed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocalItemRow extends StatelessWidget {
  final dynamic entry; // _LocalCartEntry

  const _LocalItemRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.bgSecondary,
          ),
          child: Center(
            child: Text(
              entry.product.name.isNotEmpty
                  ? entry.product.name[0].toUpperCase()
                  : 'P',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.product.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Qty: ${entry.qty}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹${(entry.product.displayPrice * entry.qty).toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
