// lib/screens/api_product_detail_page.dart
//
// Full product detail page — shows all product info, images gallery,
// and the add-to-cart flow with quantity selector.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../models/api_cart_provider.dart';
import '../theme/app_theme.dart';
import 'api_checkout_page.dart';

class ApiProductDetailPage extends StatefulWidget {
  final ApiProduct product;
  final Shop shop;

  const ApiProductDetailPage({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  State<ApiProductDetailPage> createState() => _ApiProductDetailPageState();
}

class _ApiProductDetailPageState extends State<ApiProductDetailPage> {
  int _selectedImageIndex = 0;
  int _qty = 1;
  String? _selectedVariantId;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    // Default select first variant/batch if available
    if (widget.product.variants.isNotEmpty) {
      _selectedVariantId = widget.product.variants.first['id']?.toString();
    }
    if (widget.product.batches.isNotEmpty) {
      _selectedBatchId = widget.product.batches.first['id']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.imageUrls;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(images),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Thumbnail strip
                if (images.length > 1) _buildImageStrip(images),
                const SizedBox(height: 8),
                _buildProductInfo(product),
                _buildSelectors(product),
                _buildDeliveryInfo(),
                _buildDescription(product),
                const SizedBox(height: 120), // Bottom CTA space
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(product),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(List<String> images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.bgPrimary,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? PageView.builder(
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _selectedImageIndex = i),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppTheme.bgSecondary),
                  errorWidget: (_, __, ___) => _buildImageFallback(),
                ),
              )
            : _buildImageFallback(),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: AppTheme.bgSecondary,
      child: Center(
        child: Text(
          widget.product.name.isNotEmpty
              ? widget.product.name[0].toUpperCase()
              : 'P',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 80,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // ── Image Strip ────────────────────────────────────────────────────

  Widget _buildImageStrip(List<String> images) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: images.asMap().entries.map((entry) {
          final i = entry.key;
          final url = entry.value;
          final selected = i == _selectedImageIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedImageIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              width: selected ? 64 : 56,
              height: selected ? 64 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppTheme.bgSecondary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Product Info ───────────────────────────────────────────────────

  Widget _buildProductInfo(ApiProduct product) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Shop
            Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.store, size: 13, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  widget.shop.name,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (product.category != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${product.displayPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                if (product.unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '/ ${product.unit}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (product.mrp != null && product.mrp! > product.sellingPrice) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${product.mrp!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          color: AppTheme.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercent!.toStringAsFixed(0)}% off',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Stock status
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: product.isInStock
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  product.isInStock
                      ? 'In Stock (${product.availableQty.toStringAsFixed(0)} ${product.unit ?? 'units'} available)'
                      : 'Out of Stock',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: product.isInStock
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Variant & Batch Selectors ────────────────────────────────────────
  
  Widget _buildSelectors(ApiProduct product) {
    if (product.variants.isEmpty && product.batches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return FadeInUp(
      delay: const Duration(milliseconds: 50),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.variants.isNotEmpty) ...[
              const Text(
                'Available Options',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.variants.map((v) {
                  final id = v['id']?.toString();
                  final name = v['name']?.toString() ?? 'Option';
                  final isSelected = _selectedVariantId == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedVariantId = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (product.batches.isNotEmpty) const SizedBox(height: 16),
            ],
            if (product.batches.isNotEmpty) ...[
              const Text(
                'Available Batches',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.batches.map((b) {
                  final id = b['id']?.toString();
                  final name = b['name']?.toString() ?? 'Batch';
                  final isSelected = _selectedBatchId == id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBatchId = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.successGreen : AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.successGreen : AppTheme.veryLightGray,
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Delivery Info ──────────────────────────────────────────────────

  Widget _buildDeliveryInfo() {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _infoChip(Icons.local_shipping_outlined, 'Delivery',
                widget.shop.hasDelivery ? 'Available' : 'Pickup Only',
                widget.shop.hasDelivery ? AppTheme.successGreen : AppTheme.textTertiary),
            const SizedBox(width: 16),
            _infoChip(Icons.storefront_rounded, 'Shop', widget.shop.name,
                AppTheme.primaryBlue),
            if (widget.shop.minDeliveryCharge > 0) ...[
              const SizedBox(width: 16),
              _infoChip(Icons.currency_rupee_rounded, 'Delivery Fee',
                  '₹${widget.shop.minDeliveryCharge.toStringAsFixed(0)}',
                  AppTheme.warningOrange),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────

  Widget _buildDescription(ApiProduct product) {
    if (product.description == null || product.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom CTA ─────────────────────────────────────────────────────

  Widget _buildBottomCTA(ApiProduct product) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        final inCart = cart.isInCart(product.id);
        final isAdding = cart.state == CartState.adding;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quantity selector
              if (!inCart) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Quantity: ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        if (_qty > 1) setState(() => _qty--);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_qty',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => _qty++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isAdding || !product.isInStock)
                          ? null
                          : () async {
                              await cart.addItem(
                                product: product,
                                shopId: widget.shop.id,
                                qty: _qty.toDouble(),
                                variantId: _selectedVariantId,
                                batchId: _selectedBatchId,
                              );
                              if (cart.error != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(cart.error!),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                                cart.clearError();
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart ✓'),
                                    backgroundColor: AppTheme.successGreen,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inCart
                            ? AppTheme.successGreen
                            : AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isAdding
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppTheme.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  inCart
                                      ? Icons.check_circle_rounded
                                      : Icons.shopping_cart_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  inCart ? 'Added to Cart' : 'Add to Cart',
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

                  if (inCart) ...[
                    const SizedBox(width: 12),
                    // Go to Checkout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ApiCheckoutPage(shop: widget.shop),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningOrange,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}
