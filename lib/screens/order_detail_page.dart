// lib/screens/order_detail_page.dart
//
// Premium, light-themed Order Details screen.
// Provides complete order tracking, item breakdown, delivery info,
// price summary, and interactive state management.
//

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/order_model.dart';
import '../models/shop_model.dart';
import '../models/shop_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/product_provider.dart';
import '../models/product_model.dart';
import '../models/profile_provider.dart';
import '../models/user_order_provider.dart';
import '../models/return_request_model.dart';
import '../models/return_request_provider.dart';
import '../core/models/address_model.dart';
import '../theme/app_theme.dart';
import 'cart_page.dart';
import 'api_shop_details_page.dart';
import 'return_request_page.dart';
import 'return_request_detail_page.dart';

class _OrderAddressDetails {
  final String? recipientName;
  final String? recipientPhone;
  final String fullAddress;
  final String? tag;
  final String? note;
  final bool isPickup;

  const _OrderAddressDetails({
    this.recipientName,
    this.recipientPhone,
    required this.fullAddress,
    this.tag,
    this.note,
    this.isPickup = false,
  });
}

class OrderDetailPage extends StatefulWidget {
  final ApiOrder order;
  final Shop? shop;

  const OrderDetailPage({
    super.key,
    required this.order,
    this.shop,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
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

  late ApiOrder _order;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final returns = _order.returnRequests;
      if (returns != null && returns.isNotEmpty) {
        context.read<ReturnRequestProvider>().seedFromOrder(_order);
      }
      _refreshOrder();
    });
  }

  Future<void> _refreshOrder() async {
    if (_order.id.isEmpty || _order.id == 'N/A') return;
    try {
      final userOrderProv = context.read<UserOrderProvider>();
      await userOrderProv.fetchOrderDetail(_order.shopId, _order.id);
      if (mounted && userOrderProv.selectedOrder != null) {
        setState(() {
          _order = userOrderProv.selectedOrder!;
        });
      }
      if (mounted) {
        final returns = _order.returnRequests;
        if (returns != null && returns.isNotEmpty) {
          context.read<ReturnRequestProvider>().seedFromOrder(_order);
        }
        await context.read<ReturnRequestProvider>().fetchRequestsForOrder(
          _order.id,
          shopId: _order.shopId,
          force: true,
        );
      }
    } catch (_) {}
  }

  // ── Helper: Normalized Status Check ────────────────────────────────
  String get _normalizedStatus => _order.status.toUpperCase().trim();

  bool get _isDelivered =>
      _normalizedStatus == 'DELIVERED' || _normalizedStatus == 'COMPLETED';

  bool get _isCancelled =>
      _normalizedStatus == 'CANCELLED' ||
      _normalizedStatus == 'CANCELED' ||
      _normalizedStatus == 'REFUNDED';

  bool get _isOutForDelivery => _normalizedStatus == 'OUT_FOR_DELIVERY';

  bool get _isPreparing =>
      _normalizedStatus == 'PREPARING' || _normalizedStatus == 'PROCESSING';

  bool get _isAccepted =>
      _normalizedStatus == 'ACCEPTED' || _normalizedStatus == 'CONFIRMED';

  bool get _isPending => _normalizedStatus == 'PENDING';

  int get _currentStageIndex {
    if (_isDelivered) return 4;
    if (_isOutForDelivery) return 3;
    if (_isPreparing) return 2;
    if (_isAccepted) return 1;
    return 0; // Pending or placed
  }

  // ── Helper: Date Formatting ────────────────────────────────────────
  String _formatDateTime(String? raw) {
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
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $ampm';
    } catch (_) {
      return raw.contains('T') ? raw.split('T').first : raw;
    }
  }

  // ── Helper: Copy to Clipboard ──────────────────────────────────────
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
          style: const TextStyle(fontFamily: 'Outfit', color: Colors.white),
        ),
        backgroundColor: _textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Helper: Shop Lookup ────────────────────────────────────────────
  Shop? _resolveShop(BuildContext context) {
    if (widget.shop != null) return widget.shop;
    final shops = context.watch<ShopProvider>().shops;
    try {
      return shops.firstWhere((s) => s.id == _order.shopId);
    } catch (_) {
      return null;
    }
  }

  // ── Helper: Calculation Values ─────────────────────────────────────
  double get _subtotal {
    final calc = _order.calculationInfos;
    if (calc != null && calc['subtotal'] != null) {
      return double.tryParse(calc['subtotal'].toString()) ?? 0.0;
    }
    if (_order.items.isNotEmpty) {
      return _order.items.fold(0.0, (sum, i) => sum + i.lineTotal);
    }
    return _order.totalAmount;
  }

  double get _deliveryFee {
    final calc = _order.calculationInfos;
    if (calc != null) {
      final fee = calc['delivery_fee'] ?? calc['delivery_charge'];
      if (fee != null) return double.tryParse(fee.toString()) ?? 0.0;
    }
    return 0.0;
  }

  double get _discount {
    final calc = _order.calculationInfos;
    if (calc != null && calc['discount'] != null) {
      return double.tryParse(calc['discount'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  String get _paymentMethod {
    final pay = _order.paymentInfos;
    if (pay != null && pay.isNotEmpty) {
      if (pay.containsKey('method')) return pay['method'].toString();
      for (final key in pay.keys) {
        final upper = key.toUpperCase();
        if (upper.contains('CASH') || upper.contains('COD')) {
          return 'Cash on Delivery';
        }
        if (upper.contains('UPI')) return 'UPI';
        if (upper.contains('CARD')) return 'Credit / Debit Card';
      }
      return pay.keys.first.toString();
    }
    return 'Cash on Delivery';
  }

  _OrderAddressDetails _resolveAddressDetails(BuildContext context) {
    final calc = _order.calculationInfos;
    final additional = _order.additionalInfos;
    final deliveryMap = _order.deliveryAddress;
    ProfileProvider? profileProv;
    try {
      profileProv = context.read<ProfileProvider>();
    } catch (_) {}

    final bool isPickup = _deliveryType.toUpperCase().contains('PICKUP') ||
        additional?['delivery_type']?.toString().toUpperCase().contains('PICKUP') == true;

    if (isPickup) {
      final shop = _resolveShop(context);
      final shopAddr = shop?.displayAddress ?? '';

      return _OrderAddressDetails(
        recipientName: _order.customerName ??
            additional?['customer_name']?.toString() ??
            additional?['name']?.toString() ??
            profileProv?.userName,
        recipientPhone: _order.customerPhone ??
            additional?['customer_phone']?.toString() ??
            additional?['phone']?.toString() ??
            profileProv?.defaultAddress?.phone,
        fullAddress: shopAddr.isNotEmpty
            ? shopAddr
            : (shop?.name != null ? '${shop!.name} (Store Counter)' : 'Store Counter Pickup'),
        tag: 'STORE PICKUP',
        note: _order.note ?? additional?['note']?.toString(),
        isPickup: true,
      );
    }

    // 1. Recipient info
    String? recipientName = _order.customerName;
    recipientName ??= deliveryMap?['name']?.toString();
    recipientName ??= deliveryMap?['customer_name']?.toString();
    recipientName ??= additional?['customer_name']?.toString();
    recipientName ??= additional?['name']?.toString();
    recipientName ??= (profileProv != null && profileProv.userName.trim().isNotEmpty)
        ? profileProv.userName.trim()
        : null;

    String? recipientPhone = _order.customerPhone;
    recipientPhone ??= deliveryMap?['phone']?.toString();
    recipientPhone ??= deliveryMap?['customer_phone']?.toString();
    recipientPhone ??= additional?['customer_phone']?.toString();
    recipientPhone ??= additional?['phone']?.toString();
    recipientPhone ??= (profileProv?.defaultAddress?.phone != null &&
            profileProv!.defaultAddress!.phone.trim().isNotEmpty)
        ? profileProv.defaultAddress!.phone.trim()
        : null;

    final String? note = _order.note ?? additional?['note']?.toString();

    // 2. Identify Address Model or Tag
    final String? addrId = _order.addressId ??
        deliveryMap?['address_id']?.toString() ??
        deliveryMap?['id']?.toString() ??
        additional?['address_id']?.toString();

    AddressModel? matchedAddress;
    if (addrId != null && profileProv != null) {
      for (final a in profileProv.addresses) {
        if (a.addressId == addrId) {
          matchedAddress = a;
          break;
        }
      }
    }

    String? tag = deliveryMap?['title']?.toString() ??
        deliveryMap?['label']?.toString() ??
        additional?['delivery_address']?['title']?.toString();
    if (tag == null && matchedAddress != null) {
      tag = matchedAddress.isDefault ? 'HOME (DEFAULT)' : 'SAVED ADDRESS';
    }

    // 3. Resolve Full Address Text
    String? resolvedAddress;

    // Check order fullAddress field
    if (_order.fullAddress != null && _order.fullAddress!.trim().isNotEmpty) {
      resolvedAddress = _order.fullAddress!.trim();
      final extraParts = <String>[];
      if (_order.city != null &&
          _order.city!.trim().isNotEmpty &&
          !resolvedAddress.toLowerCase().contains(_order.city!.toLowerCase())) {
        extraParts.add(_order.city!.trim());
      }
      if (_order.state != null &&
          _order.state!.trim().isNotEmpty &&
          !resolvedAddress.toLowerCase().contains(_order.state!.toLowerCase())) {
        extraParts.add(_order.state!.trim());
      }
      if (_order.pincode != null &&
          _order.pincode!.trim().isNotEmpty &&
          !resolvedAddress.contains(_order.pincode!.trim())) {
        extraParts.add(_order.pincode!.trim());
      }
      if (extraParts.isNotEmpty) {
        resolvedAddress = '$resolvedAddress, ${extraParts.join(", ")}';
      }
    }

    // Check deliveryAddress map on _order
    if (resolvedAddress == null && deliveryMap != null) {
      final street = deliveryMap['full_address'] ?? deliveryMap['address'];
      final city = deliveryMap['city'];
      final state = deliveryMap['state'];
      final pin = deliveryMap['pincode'];
      final parts = [street, city, state, pin]
          .where((p) => p != null && p.toString().trim().isNotEmpty)
          .map((p) => p.toString().trim())
          .toList();
      if (parts.isNotEmpty) resolvedAddress = parts.join(', ');
    }

    // Check additionalInfos
    if (resolvedAddress == null && additional != null) {
      final da = additional['delivery_address'];
      if (da is String && da.trim().isNotEmpty) {
        resolvedAddress = da.trim();
      } else if (da is Map) {
        final street = da['full_address'] ?? da['address'];
        final city = da['city'];
        final state = da['state'];
        final pin = da['pincode'];
        final parts = [street, city, state, pin]
            .where((p) => p != null && p.toString().trim().isNotEmpty)
            .map((p) => p.toString().trim())
            .toList();
        if (parts.isNotEmpty) resolvedAddress = parts.join(', ');
      }
      if (resolvedAddress == null && additional['full_address'] != null) {
        resolvedAddress = additional['full_address'].toString().trim();
      }
    }

    // Check matchedAddress from ProfileProvider
    if (resolvedAddress == null && matchedAddress != null) {
      final parts = [
        matchedAddress.fullAddress,
        matchedAddress.city,
        matchedAddress.state,
        matchedAddress.pincode,
      ].where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) resolvedAddress = parts.join(', ');
    }

    // Check calculationInfos
    if (resolvedAddress == null && calc != null) {
      final da = calc['delivery_address'];
      if (da is String && da.trim().isNotEmpty) {
        resolvedAddress = da.trim();
      } else if (da is Map) {
        final street = da['full_address'] ?? da['address'];
        final city = da['city'];
        final state = da['state'];
        final pin = da['pincode'];
        final parts = [street, city, state, pin]
            .where((p) => p != null && p.toString().trim().isNotEmpty)
            .map((p) => p.toString().trim())
            .toList();
        if (parts.isNotEmpty) resolvedAddress = parts.join(', ');
      }
      if (resolvedAddress == null && calc['full_address'] != null) {
        resolvedAddress = calc['full_address'].toString().trim();
      }
    }

    // Check description
    if (resolvedAddress == null &&
        _order.description != null &&
        _order.description!.trim().isNotEmpty) {
      resolvedAddress = _order.description!.trim();
    }

    // Fallback to default address from ProfileProvider
    if (resolvedAddress == null && profileProv?.defaultAddress != null) {
      final def = profileProv!.defaultAddress!;
      final parts = [
        def.fullAddress,
        def.city,
        def.state,
        def.pincode,
      ].where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        resolvedAddress = parts.join(', ');
        tag ??= 'DEFAULT ADDRESS';
      }
    }

    resolvedAddress ??= 'Registered Delivery Address';

    return _OrderAddressDetails(
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      fullAddress: resolvedAddress,
      tag: tag,
      note: note,
      isPickup: false,
    );
  }

  String get _deliveryAddress => _resolveAddressDetails(context).fullAddress;

  String get _deliveryType {
    final calc = _order.calculationInfos;
    if (calc != null) {
      if (calc['delivery_option_name'] != null) {
        return calc['delivery_option_name'].toString();
      }
      if (calc['delivery_type'] != null) {
        final dt = calc['delivery_type'].toString().toUpperCase();
        if (dt.contains('PICKUP')) return 'Store Pickup';
        if (dt.contains('EXPRESS')) return 'Express Delivery';
        return 'Standard Delivery';
      }
    }
    return 'Standard Home Delivery';
  }

  bool _hasOrderReturn(BuildContext context) {
    if (_order.hasReturn) return true;
    final reqs = context.watch<ReturnRequestProvider>().getRequestsForOrder(_order.id);
    return reqs.any((r) =>
        ApiOrder.acceptedReturnStatuses.contains(r.status.toUpperCase().trim()));
  }

  double _itemReturnQty(BuildContext context, ApiOrderItem item) {
    final directOrOrder = _order.itemReturnedQty(item);
    final reqs = context.watch<ReturnRequestProvider>().getRequestsForOrder(_order.id);
    double provQty = 0.0;
    for (final r in reqs) {
      if (!ApiOrder.acceptedReturnStatuses.contains(r.status.toUpperCase().trim())) {
        continue;
      }
      for (final ri in r.items) {
        final matchId = item.orderItemId != null &&
            item.orderItemId!.isNotEmpty &&
            ri.orderItemId == item.orderItemId;
        final matchProd = item.productId.isNotEmpty && ri.productId == item.productId;
        final matchName = item.productName != null &&
            ri.productName.trim().toLowerCase() ==
                item.productName!.trim().toLowerCase();
        if (matchId || matchProd || matchName) {
          provQty += ri.quantity;
        }
      }
    }
    return directOrOrder > provQty ? directOrOrder : provQty;
  }

  bool _isOrderItemReturned(BuildContext context, ApiOrderItem item) {
    return item.isReturned || _itemReturnQty(context, item) > 0;
  }

  bool _isOrderPartiallyReturned(BuildContext context) {
    if (!_hasOrderReturn(context)) return false;
    final st = _normalizedStatus;
    if (st == 'RETURNED' || st == 'REFUNDED' || _order.items.isEmpty) return false;
    return !_order.items.every((item) {
      final itemSt = (item.itemStatus ?? '').toUpperCase().trim();
      if (itemSt == 'RETURNED' || itemSt == 'REFUNDED') return true;
      return _itemReturnQty(context, item) >= item.qty && item.qty > 0;
    });
  }

  Widget _buildReturnTagBadge({bool isPartial = false, String? customLabel}) {
    const Color bg = Color(0xFFFFF7ED);
    const Color border = Color(0xFFFED7AA);
    const Color fg = Color(0xFFC2410C);
    final label = customLabel ?? (isPartial ? 'Partially Returned' : 'Returned');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.rotateCcw, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final shop = _resolveShop(context);
    final displayId = _order.uiId ?? _order.id;

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
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.copy, color: _textSecondary, size: 19),
            tooltip: 'Copy Order ID',
            onPressed: () => _copyToClipboard(displayId, 'Order ID'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Order Header Card
              _buildHeaderCard(displayId, shop),
              const SizedBox(height: 16),

              // 2. Out for Delivery OTP Banner (if applicable)
              if (_isOutForDelivery && _order.otp != null && _order.otp!.isNotEmpty) ...[
                _buildOtpBanner(_order.otp!),
                const SizedBox(height: 16),
              ],

              // 3. Order Lifecycle / Tracking Card
              _buildTrackingCard(),
              const SizedBox(height: 16),

              // 4. Items Ordered Card
              _buildItemsCard(),
              const SizedBox(height: 16),

              // 5. Delivery Information Card
              _buildDeliveryInfoCard(shop),
              const SizedBox(height: 16),

              // 6. Payment & Price Breakdown Card
              _buildPaymentBreakdownCard(),
              const SizedBox(height: 24),

              // 7. Order Action Buttons
              _buildActionButtons(shop),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 1: HEADER CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeaderCard(String displayId, Shop? shop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #$displayId',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _copyToClipboard(displayId, 'Order ID'),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.copy,
                              size: 14,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed on ${_formatDateTime(_order.createdAt)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
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
                  _buildStatusBadge(),
                  if (_hasOrderReturn(context)) ...[
                    const SizedBox(height: 6),
                    _buildReturnTagBadge(isPartial: _isOrderPartiallyReturned(context)),
                  ],
                ],
              ),
            ],
          ),
          if (shop != null) ...[
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ApiShopDetailsPage(shop: shop),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      size: 16,
                      color: _amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Tap to view store',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: _textMuted,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Status Badge ───────────────────────────────────────────────────
  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (_isDelivered) {
      bg = _successBg;
      fg = _success;
      label = 'Delivered';
      icon = LucideIcons.checkCircle2;
    } else if (_isCancelled) {
      bg = _errorBg;
      fg = _error;
      label = 'Cancelled';
      icon = LucideIcons.xCircle;
    } else if (_isOutForDelivery) {
      bg = _infoBg;
      fg = _info;
      label = 'Out for Delivery';
      icon = LucideIcons.truck;
    } else if (_isPreparing) {
      bg = _infoBg;
      fg = _info;
      label = 'Preparing';
      icon = LucideIcons.package;
    } else if (_isAccepted) {
      bg = _softAmber;
      fg = const Color(0xFF8A5C10);
      label = 'Accepted';
      icon = LucideIcons.check;
    } else {
      bg = _softAmber;
      fg = const Color(0xFF8A5C10);
      label = 'Pending';
      icon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 2: DELIVERY OTP BANNER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOtpBanner(String otp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softAmber.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.key, size: 18, color: _amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Verification Code',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share with partner: $otp',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 16, color: _textSecondary),
            tooltip: 'Copy OTP',
            onPressed: () => _copyToClipboard(otp, 'Delivery OTP'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 3: ORDER LIFECYCLE / TRACKING TIMELINE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTrackingCard() {
    if (_isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _errorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _error.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.xCircle, size: 20, color: _error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _error,
                    ),
                  ),
                  if (_order.cancelledByDisplay != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _error.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _order.cancelledByDisplay!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'This order has been cancelled. If any payment was deducted, it will be refunded to your source account within 3–5 business days.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      height: 1.4,
                      color: _textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stages = [
      _TrackingStage(
        title: 'Order Placed',
        subtitle: 'Received on ${_formatDateTime(_order.createdAt)}',
      ),
      const _TrackingStage(
        title: 'Accepted by Shop',
        subtitle: 'The shop confirmed your items',
      ),
      const _TrackingStage(
        title: 'Preparing Order',
        subtitle: 'Your items are being packed',
      ),
      const _TrackingStage(
        title: 'Out for Delivery',
        subtitle: 'Delivery partner is on the way',
      ),
      const _TrackingStage(
        title: 'Delivered',
        subtitle: 'Package handed over to customer',
      ),
    ];

    final currentIndex = _currentStageIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.navigation, size: 16, color: _amber),
              const SizedBox(width: 8),
              const Text(
                'Order Tracking',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${currentIndex + 1} of ${stages.length}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < stages.length; i++) ...[
            _buildTimelineStep(
              stage: stages[i],
              index: i,
              currentIndex: currentIndex,
              isLast: i == stages.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required _TrackingStage stage,
    required int index,
    required int currentIndex,
    required bool isLast,
  }) {
    final bool isCompleted = index < currentIndex;
    final bool isCurrent = index == currentIndex;

    Color iconBg;
    Color iconColor;
    Widget iconWidget;

    if (isCompleted) {
      iconBg = _successBg;
      iconColor = _success;
      iconWidget = Icon(LucideIcons.check, size: 12, color: iconColor);
    } else if (isCurrent) {
      iconBg = _amber;
      iconColor = Colors.white;
      iconWidget = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
    } else {
      iconBg = _secondarySurface;
      iconColor = _border;
      iconWidget = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: _textMuted.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator & connecting line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? _amber
                          : (isCompleted ? _success : _border),
                      width: 1.5,
                    ),
                  ),
                  child: Center(child: iconWidget),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted ? _success : _border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Stage details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: isCurrent
                          ? _textPrimary
                          : (isCompleted ? _textPrimary : _textMuted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: isCurrent ? _textSecondary : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 4: ITEMS ORDERED
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildItemsCard() {
    final cachedProducts =
        context.watch<ProductProvider>().allCachedProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shoppingBag, size: 16, color: _amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Items Ordered',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_order.items.length} ${_order.items.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No item records available for this order.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _order.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: _border, height: 20),
              itemBuilder: (context, index) {
                final item = _order.items[index];
                // Resolve image fallback from cached catalog if missing on item
                final imageUrl = item.imageUrl ??
                    cachedProducts
                        .where((p) => p.id == item.productId)
                        .firstOrNull
                        ?.primaryImage;

                final bool itemReturned = _isOrderItemReturned(context, item);
                final double itemRetQty = _itemReturnQty(context, item);
                final double gstRate = item.effectiveGstRate;
                final bool hasItemGst = gstRate > 0;
                final String? retLabel = !itemReturned
                    ? null
                    : (itemRetQty > 0 && itemRetQty < item.qty
                        ? 'Returned (${itemRetQty.toStringAsFixed(itemRetQty.truncateToDouble() == itemRetQty ? 0 : 1)}/${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 1)})'
                        : 'Returned');

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item thumbnail
                    _buildItemThumbnail(imageUrl),
                    const SizedBox(width: 12),
                    // Item info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? 'Product',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (itemReturned) ...[
                            const SizedBox(height: 4),
                            _buildReturnTagBadge(customLabel: retLabel),
                          ],
                          if (item.unit != null && item.unit!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.unit!,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 1)} × ₹${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                          if (hasItemGst) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Base: ₹${item.lineBasePrice.toStringAsFixed(2)} • GST (${gstRate.toStringAsFixed(gstRate % 1 == 0 ? 0 : 1)}%): ₹${item.lineGstAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Line total
                    Text(
                      '₹${item.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildItemThumbnail(String? url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: _secondarySurface,
                child: const Center(
                  child: Icon(LucideIcons.image, size: 16, color: _textMuted),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: _secondarySurface,
                child: const Center(
                  child: Icon(LucideIcons.package, size: 16, color: _textMuted),
                ),
              ),
            )
          : const Center(
              child: Icon(LucideIcons.package, size: 16, color: _textMuted),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 5: DELIVERY INFORMATION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDeliveryInfoCard(Shop? shop) {
    final details = _resolveAddressDetails(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _softAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      details.isPickup ? LucideIcons.store : LucideIcons.truck,
                      size: 16,
                      color: _amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    details.isPickup ? 'Pickup Information' : 'Delivery Information',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              if (details.tag != null && details.tag!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _softAmber,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    details.tag!.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _amber,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Optional: Recipient Box (Name & Phone)
          if ((details.recipientName != null && details.recipientName!.trim().isNotEmpty) ||
              (details.recipientPhone != null && details.recipientPhone!.trim().isNotEmpty)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _secondarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(LucideIcons.user, size: 16, color: _amber),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (details.recipientName != null && details.recipientName!.trim().isNotEmpty)
                          Text(
                            details.recipientName!.trim(),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        if (details.recipientPhone != null && details.recipientPhone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(LucideIcons.phone, size: 11, color: _textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                details.recipientPhone!.trim(),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (details.recipientPhone != null && details.recipientPhone!.trim().isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 14, color: _textSecondary),
                      tooltip: 'Copy Phone',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _copyToClipboard(details.recipientPhone!.trim(), 'Phone Number'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _secondarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: _amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.isPickup ? 'Pickup Address' : 'Delivery Address',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      details.fullAddress,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 14, color: _textSecondary),
                tooltip: 'Copy Address',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _copyToClipboard(details.fullAddress, 'Address'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),

          // Method Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _secondarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.packageCheck,
                  size: 16,
                  color: _amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Method',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _deliveryType,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Delivery Note (if present)
          if (details.note != null && details.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    size: 16,
                    color: _amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Note / Instructions',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details.note!.trim(),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 6: PAYMENT & PRICE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPaymentBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.receipt, size: 16, color: _amber),
              const SizedBox(width: 8),
              const Text(
                'Payment & Breakdown',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Payment method row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.creditCard, size: 14, color: _textSecondary),
                  const SizedBox(width: 6),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                _paymentMethod,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 10),
          if (_order.totalGstAmount > 0) ...[
            _buildPriceRow(
              'Items Base Price',
              '₹${_order.baseSubtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              _order.gstPercentLabel.isNotEmpty
                  ? 'Total GST (${_order.gstPercentLabel})'
                  : 'Total GST',
              '₹${_order.totalGstAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'CGST: ₹${_order.cgstAmount.toStringAsFixed(2)} • SGST: ₹${_order.sgstAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: _textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Subtotal
          _buildPriceRow('Items Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          // Delivery Charge
          _buildPriceRow(
            'Delivery Fee',
            _deliveryFee > 0 ? '₹${_deliveryFee.toStringAsFixed(2)}' : 'FREE',
            valueColor: _deliveryFee > 0 ? _textPrimary : _success,
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Discount Applied',
              '-₹${_discount.toStringAsFixed(2)}',
              valueColor: _success,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Text(
                '₹${_order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? _textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION 7: ORDER ACTIONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildActionButtons(Shop? shop) {
    return Column(
      children: [
        // Cancel Order (only eligible if order is PENDING)
        if (_isPending) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelOrderDialog(shop),
              icon: const Icon(LucideIcons.xCircle, size: 16, color: _error),
              label: const Text(
                'Cancel Order',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: _errorBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Return Product Action / Current Return Status (only eligible if delivered and not cancelled/rejected)
        if (_isDelivered && !_isCancelled && _normalizedStatus != 'REJECTED') ...[
          Consumer<ReturnRequestProvider>(
            builder: (context, returnProv, _) {
              final activeRequest = returnProv.getLatestRequestForOrder(_order.id);
              if (activeRequest != null) {
                // An active or completed return request already exists - show status
                return _buildReturnStatusBanner(activeRequest, shop);
              }

              // Eligible for return request - present return action
              return SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReturnRequestPage(
                          order: _order,
                          shop: shop,
                        ),
                      ),
                    );
                    _refreshOrder();
                  },
                  icon: const Icon(LucideIcons.rotateCcw, size: 16, color: _amber),
                  label: const Text(
                    'Return Items',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _amber,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCD34D), width: 1.5),
                    backgroundColor: const Color(0xFFFFFBEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Reorder (for delivered or cancelled orders)
        if (_isDelivered || _isCancelled) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isReordering ? null : () => _handleReorder(shop),
              icon: _isReordering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(LucideIcons.repeat, size: 16, color: Colors.white),
              label: Text(
                _isReordering ? 'Adding to cart...' : 'Reorder Items',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Contact Shop / Need Help
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showContactShopDialog(shop),
            icon: const Icon(LucideIcons.helpCircle, size: 16, color: _textPrimary),
            label: const Text(
              'Need Help With This Order?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnStatusBanner(ReturnRequestModel request, Shop? shop) {
    Color bg;
    Color borderCol;
    Color fg;
    IconData icon;
    String statusTitle;

    if (request.isAccepted) {
      bg = const Color(0xFFF0FDF4);
      borderCol = const Color(0xFFBBF7D0);
      fg = _success;
      icon = LucideIcons.checkCircle2;
      statusTitle = 'Return Request: ACCEPTED';
    } else if (request.isRejected) {
      bg = const Color(0xFFFEF2F2);
      borderCol = const Color(0xFFFECACA);
      fg = _error;
      icon = LucideIcons.xCircle;
      statusTitle = 'Return Request: REJECTED';
    } else {
      bg = const Color(0xFFFFFBEB);
      borderCol = const Color(0xFFFDE68A);
      fg = _amber;
      icon = LucideIcons.clock;
      statusTitle = 'Return Request: PENDING REVIEW';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.items.length} item${request.items.length == 1 ? '' : 's'} requested for return.',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
          if (request.adminNotes != null && request.adminNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Seller Note: ${request.adminNotes}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: fg,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReturnRequestDetailPage(
                      returnRequest: request,
                      order: _order,
                    ),
                  ),
                );
              },
              icon: Icon(LucideIcons.arrowUpRight, size: 14, color: fg),
              label: Text(
                'View Return Details',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderCol),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action: Cancel Confirmation Dialog ──────────────────────────────
  void _showCancelOrderDialog(Shop? shop) {
    bool isCancelling = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cancel Order?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel order #${_order.uiId ?? _order.id}? This will notify ${shop?.name ?? 'the shop'} immediately.',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCancelling ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Keep Order',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isCancelling
                  ? null
                  : () async {
                      setDialogState(() => isCancelling = true);
                      final userOrderProv = context.read<UserOrderProvider>();
                      final cartProv = context.read<ApiCartProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final updated = await userOrderProv.cancelOrder(
                          orderId: _order.id,
                          shopId: _order.shopId,
                        );
                        final newStatus = updated?.status ?? 'CANCELED';
                        cartProv.updateOrderStatusLocally(_order.id, newStatus);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (mounted) {
                          final mergedAdd = Map<String, dynamic>.from(
                            _order.additionalInfos ?? const {},
                          )
                            ..['cancelled_by_source'] = 'DIGITAL_STORE'
                            ..['cancelled_by'] = 'Customer'
                            ..['cancelled_by_label'] = 'Cancelled by Customer';
                          setState(() {
                            _order = (updated ??
                                    _order.copyWith(
                                      status: newStatus,
                                      updatedAt: DateTime.now().toIso8601String(),
                                      otp: null,
                                    ))
                                .copyWith(additionalInfos: mergedAdd);
                          });
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Order cancelled successfully.',
                              style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
                            ),
                            backgroundColor: _error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        final msg = e.toString().replaceFirst('Exception: ', '').trim();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              msg.isNotEmpty
                                  ? 'Failed to cancel order: $msg'
                                  : 'Failed to cancel order. Please try again.',
                              style: const TextStyle(fontFamily: 'Outfit', color: Colors.white),
                            ),
                            backgroundColor: _error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Yes, Cancel',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action: Reorder Items ───────────────────────────────────────────
  Future<void> _handleReorder(Shop? shop) async {
    if (_order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No items available to reorder.',
            style: TextStyle(fontFamily: 'Outfit', color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isReordering = true);

    try {
      final cartProvider = context.read<ApiCartProvider>();
      final cachedProducts =
          context.read<ProductProvider>().allCachedProducts;

      // Ensure cart session is initialized with this order's shop
      await cartProvider.initCart(_order.shopId);

      int addedCount = 0;
      for (final item in _order.items) {
        // Resolve product model from cache or synthesize from order item
        ApiProduct? product =
            cachedProducts.where((p) => p.id == item.productId).firstOrNull;

        product ??= ApiProduct(
          id: item.productId,
          shopId: _order.shopId,
          name: item.productName ?? 'Product',
          sellingPrice: item.unitPrice,
          imageUrls: item.imageUrl != null ? [item.imageUrl!] : [],
        );

        await cartProvider.addItem(
          product: product,
          shopId: _order.shopId,
          qty: item.qty,
          variantId: item.variantId,
          batchId: item.batchId,
        );
        addedCount++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$addedCount item(s) added to your cart!',
            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white),
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add items to cart: $e',
            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white),
          ),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  // ── Action: Contact Shop Dialog ─────────────────────────────────────
  void _showContactShopDialog(Shop? shop) {
    final phone = shop?.businessInfos?['phone']?.toString() ??
        shop?.businessInfos?['mobile']?.toString() ??
        'Store Support';

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Store & Support Details',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quote Order #${_order.uiId ?? _order.id} for quick assistance.',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.store, color: _amber, size: 20),
                ),
                title: Text(
                  shop?.name ?? 'Store',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                subtitle: Text(
                  shop?.description ?? 'Partner Merchant',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.phone, color: _amber, size: 20),
                ),
                title: Text(
                  phone,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    _copyToClipboard(phone, 'Phone number');
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text(
                    'Copy',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      color: _amber,
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
}

class _TrackingStage {
  final String title;
  final String subtitle;

  const _TrackingStage({required this.title, required this.subtitle});
}
