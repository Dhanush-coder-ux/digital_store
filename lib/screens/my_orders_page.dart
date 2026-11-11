// lib/screens/my_orders_page.dart
//
// Premium Flutter E-commerce My Orders experience.
// Warm, light-themed retail design consistent with storefront and checkout.
// Clean horizontally scrollable status filters, compact order cards,
// skeleton loading, pull-to-refresh, and full integration with OrderDetailPage.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/auth/auth_provider.dart';
import '../models/user_order_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/shop_provider.dart';
import '../models/product_provider.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_translations.dart';
import 'order_detail_page.dart';
import 'my_return_requests_page.dart';
import 'main_screen.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // ═══════════════════════════════════════════════════════════════════
  // DESIGN SYSTEM PALETTE — Centralized Warm Tangerine
  // ═══════════════════════════════════════════════════════════════════
  static const Color _bg = AppTheme.background;
  static const Color _surface = AppTheme.surface;
  static const Color _secondarySurface = AppTheme.softCream;
  static const Color _amber = AppTheme.primary; // Warm Tangerine #F28C28
  static const Color _softAmber = AppTheme.softPeach; // Soft Peach #FFF3E3
  static const Color _textPrimary = AppTheme.primaryText; // #493629
  static const Color _textSecondary = AppTheme.secondaryText; // #8A7664
  static const Color _textMuted = AppTheme.textTertiary;
  static const Color _border = AppTheme.border; // #E9E2D8
  static const Color _success = AppTheme.success; // #258A68
  static const Color _successBg = AppTheme.successBackground; // #E9F7EF
  static const Color _info = AppTheme.information; // Accessible blue #2563EB
  static const Color _infoBg = AppTheme.informationBackground; // Pale blue #EFF6FF
  static const Color _error = AppTheme.error; // Accessible red #DC2626
  static const Color _errorBg = AppTheme.errorBackground; // Pale red #FEF2F2

  // Status Filter Enum / Types
  static const List<String> _filters = [
    'All',
    'Pending',
    'Accepted',
    'Preparing',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  void _loadOrders() {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      context.read<UserOrderProvider>().fetchUserOrders(auth.userId!, limit: 50);
    } else {
      context.read<ApiCartProvider>().refreshOrders();
    }
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      await context
          .read<UserOrderProvider>()
          .fetchUserOrders(auth.userId!, limit: 50, force: true);
    } else {
      await context.read<ApiCartProvider>().refreshOrders();
    }
  }

  // ── Status Matching Logic ──────────────────────────────────────────
  bool _matchesFilter(ApiOrder order, String filter) {
    if (filter == 'All') return true;
    final status = order.status.toUpperCase().trim();

    switch (filter) {
      case 'Pending':
        return status == 'PENDING';
      case 'Accepted':
        return status == 'ACCEPTED' || status == 'CONFIRMED';
      case 'Preparing':
        return status == 'PREPARING' || status == 'PROCESSING';
      case 'Out for Delivery':
        return status == 'OUT_FOR_DELIVERY';
      case 'Delivered':
        return status == 'DELIVERED' || status == 'COMPLETED';
      case 'Cancelled':
        return status == 'CANCELLED' ||
            status == 'CANCELED' ||
            status == 'REFUNDED';
      default:
        return true;
    }
  }

  // ── Date Formatter ─────────────────────────────────────────────────
  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return raw.contains('T') ? raw.split('T').first : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cartProvider = context.watch<ApiCartProvider>();
    final userOrderProvider = context.watch<UserOrderProvider>();

    final List<ApiOrder> sourceOrders = auth.userId != null
        ? userOrderProvider.orders
        : cartProvider.myOrders;

    final bool isLoading = auth.userId != null
        ? userOrderProvider.isLoading
        : cartProvider.isLoading;

    final String? errorMessage =
        auth.userId != null ? userOrderProvider.error : cartProvider.error;

    // Filtered orders
    final List<ApiOrder> displayedOrders =
        sourceOrders.where((o) => _matchesFilter(o, _selectedFilter)).toList();

    // In-progress count (Active orders: Pending, Accepted, Preparing, Out for Delivery)
    final int activeCount = sourceOrders.where((o) {
      final s = o.status.toUpperCase().trim();
      return s == 'PENDING' ||
          s == 'ACCEPTED' ||
          s == 'CONFIRMED' ||
          s == 'PREPARING' ||
          s == 'PROCESSING' ||
          s == 'OUT_FOR_DELIVERY';
    }).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: _border, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _textPrimary, size: 20),
          tooltip: context.tr('back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('my_orders'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        centerTitle: false,
        titleSpacing: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Material(
              color: _softAmber,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyReturnRequestsPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.assignment_return_outlined,
                        color: _amber,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        context.tr('returns'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5C10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.rotateCw, color: _textSecondary, size: 19),
            tooltip: context.tr('refresh'),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Order Summary Pill
            if (sourceOrders.isNotEmpty) _buildSummaryBar(sourceOrders.length, activeCount),

            // 2. Horizontally Scrollable Filter Chips
            _buildFilterRow(sourceOrders),

            // 3. Orders List / Skeletons / Empty State
            Expanded(
              child: _buildBody(
                isLoading: isLoading,
                errorMessage: errorMessage,
                sourceOrders: sourceOrders,
                displayedOrders: displayedOrders,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 1: SUMMARY BAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSummaryBar(int totalOrders, int activeOrders) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _secondarySurface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.package, size: 15, color: _amber),
          const SizedBox(width: 8),
          Text(
            '$totalOrders ${totalOrders == 1 ? 'Order' : 'Orders'} total',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          if (activeOrders > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: _textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$activeOrders Active',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _amber,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 2: FILTER CHIPS ROW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFilterRow(List<ApiOrder> sourceOrders) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final bool isSelected = _selectedFilter == filter;

          // Compute count for this filter
          final count = sourceOrders.where((o) => _matchesFilter(o, filter)).length;

          return InkWell(
            onTap: () {
              setState(() => _selectedFilter = filter);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _softAmber : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _amber : _border,
                  width: isSelected ? 1.2 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF6E491A) : _textSecondary,
                    ),
                  ),
                  if (count > 0 && filter != 'All') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _amber.withValues(alpha: 0.25)
                            : _secondarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF6E491A)
                              : _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 3: LIST / SKELETONS / EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBody({
    required bool isLoading,
    required String? errorMessage,
    required List<ApiOrder> sourceOrders,
    required List<ApiOrder> displayedOrders,
  }) {
    // 1. Initial Skeleton Loading State
    if (isLoading && sourceOrders.isEmpty) {
      return _buildSkeletonList();
    }

    // 2. Error State with Retry
    if (errorMessage != null && sourceOrders.isEmpty) {
      return _buildErrorState(errorMessage);
    }

    // 3. Overall Empty State (Customer has zero orders)
    if (sourceOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: _amber,
        backgroundColor: _surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildEmptyState(
              icon: LucideIcons.shoppingBag,
              title: 'No orders yet',
              message:
                  'Looks like you haven\'t placed any orders yet. Discover fresh local products now!',
              buttonLabel: 'Explore Stores',
              onButtonPressed: () {
                MainScreen.pageIndexNotifier.value = 1;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        ),
      );
    }

    // 4. Filtered Empty State (No orders matching selected status filter)
    if (displayedOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: _amber,
        backgroundColor: _surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildEmptyState(
              icon: LucideIcons.filterX,
              title: 'No $_selectedFilter orders',
              message:
                  'There are currently no orders in this category. Check other filters to view your history.',
              buttonLabel: 'View All Orders',
              onButtonPressed: () {
                setState(() => _selectedFilter = 'All');
              },
            ),
          ),
        ),
      );
    }

    // 5. Order Cards List
    final shops = context.watch<ShopProvider>().shops;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _amber,
      backgroundColor: _surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: displayedOrders.length,
        itemBuilder: (context, index) {
          final order = displayedOrders[index];
          final shop = shops.where((s) => s.id == order.shopId).firstOrNull;
          return _buildOrderCard(order, shop);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 4: COMPACT ORDER CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOrderCard(ApiOrder order, Shop? shop) {
    final status = order.status.toUpperCase().trim();
    final bool isCancelled =
        status == 'CANCELLED' || status == 'CANCELED' || status == 'REFUNDED';
    final bool isOutForDelivery = status == 'OUT_FOR_DELIVERY';

    final String displayId = order.uiId ?? order.id;
    final cachedProducts =
        context.watch<ProductProvider>().allCachedProducts;

    // Gather preview image URLs
    final List<String> imageUrls = [];
    for (final item in order.items) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        imageUrls.add(item.imageUrl!);
      } else {
        final cached =
            cachedProducts.where((p) => p.id == item.productId).firstOrNull;
        if (cached?.primaryImage != null && cached!.primaryImage!.isNotEmpty) {
          imageUrls.add(cached.primaryImage!);
        }
      }
    }

    // Primary item name
    final String primaryName = order.items.isNotEmpty
        ? (order.items.first.productName ?? 'Product')
        : (shop?.name ?? 'Store Order');

    // Concise additional items label
    String? additionalLabel;
    if (order.items.length > 1) {
      additionalLabel = 'and ${order.items.length - 1} more item${order.items.length - 1 == 1 ? '' : 's'}';
    } else if (order.items.isNotEmpty && order.items.first.unit != null) {
      additionalLabel = '${order.items.first.qty.toStringAsFixed(order.items.first.qty.truncateToDouble() == order.items.first.qty ? 0 : 1)} ${order.items.first.unit}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(order: order, shop: shop),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Card Header: Order ID + Date + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #$displayId',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed on ${_formatDate(order.createdAt)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildCompactStatusBadge(status),
                        if (isCancelled && order.cancelledByDisplay != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.cancelledByDisplay!,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _error,
                            ),
                          ),
                        ],
                        if (order.hasReturn) ...[
                          const SizedBox(height: 4),
                          _buildReturnTagBadge(order.isPartiallyReturned),
                        ],
                      ],
                    ),
                  ],
                ),

                // 2. Out for Delivery OTP Banner (if active)
                if (isOutForDelivery &&
                    order.otp != null &&
                    order.otp!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _softAmber.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.key, size: 14, color: _amber),
                        const SizedBox(width: 6),
                        const Text(
                          'Delivery OTP: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          order.otp!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 3. Product Preview Row
                Row(
                  children: [
                    // Thumbnails (Single or compact overlapping group)
                    _buildThumbnailPreview(imageUrls, isCancelled),
                    const SizedBox(width: 12),
                    // Product titles
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryName,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isCancelled ? _textMuted : _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (additionalLabel != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              additionalLabel,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: _border, height: 1),
                const SizedBox(height: 10),

                // 4. Card Footer: Total Amount & "View details" Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'View details',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _amber,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: _amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Compact Status Badge ───────────────────────────────────────────
  Widget _buildCompactStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'DELIVERED':
      case 'COMPLETED':
        bg = _successBg;
        fg = _success;
        label = 'Delivered';
        icon = LucideIcons.check;
        break;
      case 'CANCELLED':
      case 'CANCELED':
      case 'REFUNDED':
        bg = _errorBg;
        fg = _error;
        label = 'Cancelled';
        icon = LucideIcons.x;
        break;
      case 'OUT_FOR_DELIVERY':
        bg = _infoBg;
        fg = _info;
        label = 'Out for delivery';
        icon = LucideIcons.truck;
        break;
      case 'PREPARING':
      case 'PROCESSING':
        bg = _infoBg;
        fg = _info;
        label = 'Preparing';
        icon = LucideIcons.package;
        break;
      case 'ACCEPTED':
      case 'CONFIRMED':
        bg = _softAmber;
        fg = const Color(0xFF8A5C10);
        label = 'Accepted';
        icon = LucideIcons.check;
        break;
      case 'PENDING':
      default:
        bg = _softAmber;
        fg = const Color(0xFF8A5C10);
        label = 'Pending';
        icon = LucideIcons.clock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTagBadge(bool isPartial) {
    const Color bg = Color(0xFFFFF7ED);
    const Color border = Color(0xFFFED7AA);
    const Color fg = Color(0xFFC2410C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_return_outlined, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            isPartial ? 'Partially Returned' : 'Returned',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Thumbnail Preview Widget ────────────────────────────────────────
  Widget _buildThumbnailPreview(List<String> images, bool isCancelled) {
    if (images.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _secondarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: const Icon(LucideIcons.package, size: 18, color: _textMuted),
      );
    }

    // Single item thumbnail
    if (images.length == 1) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _secondarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ColorFiltered(
          colorFilter: isCancelled
              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
          child: CachedNetworkImage(
            imageUrl: images.first,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: _secondarySurface,
              child: const Center(
                child: Icon(LucideIcons.image, size: 14, color: _textMuted),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: _secondarySurface,
              child: const Center(
                child: Icon(LucideIcons.package, size: 14, color: _textMuted),
              ),
            ),
          ),
        ),
      );
    }

    // Overlapping multi-item preview (up to 3 thumbnails)
    final int displayCount = images.length.clamp(1, 3);
    final double stackWidth = 44 + (displayCount - 1) * 16.0;

    return SizedBox(
      width: stackWidth,
      height: 44,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _secondarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ColorFiltered(
                  colorFilter: isCancelled
                      ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: _secondarySurface,
                      child: const Center(
                        child: Icon(LucideIcons.image, size: 14, color: _textMuted),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: _secondarySurface,
                      child: const Center(
                        child: Icon(LucideIcons.package, size: 14, color: _textMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 5: SKELETONS & EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFF0E8DC),
          highlightColor: const Color(0xFFFAF6F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 90,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _softAmber.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: _amber.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 30, color: _amber),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: _textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _errorBg,
                shape: BoxShape.circle,
                border: Border.all(color: _error.withValues(alpha: 0.2)),
              ),
              child: const Icon(LucideIcons.alertCircle, size: 28, color: _error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load orders',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(LucideIcons.rotateCw, size: 14, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
