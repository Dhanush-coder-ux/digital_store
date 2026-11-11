// lib/screens/my_return_requests_page.dart
//
// Screen listing all return requests for the authenticated customer.
// Shows request ID, order ID, items, status badges, and allows tracking.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/return_request_model.dart';
import '../models/return_request_provider.dart';
import '../models/user_order_provider.dart';
import '../core/auth/auth_provider.dart';
import '../l10n/app_translations.dart';
import 'return_request_detail_page.dart';

class MyReturnRequestsPage extends StatefulWidget {
  const MyReturnRequestsPage({super.key});

  @override
  State<MyReturnRequestsPage> createState() => _MyReturnRequestsPageState();
}

class _MyReturnRequestsPageState extends State<MyReturnRequestsPage> {
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _amber = Color(0xFFD97706);
  static const Color _error = Color(0xFFDC2626);
  static const Color _success = Color(0xFF16A34A);

  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<UserOrderProvider>();
    final returnProvider = context.read<ReturnRequestProvider>();

    if (auth.userId == null || auth.userId!.isEmpty) return;

    await Future.wait([
      if (orderProvider.orders.isEmpty)
        orderProvider.fetchUserOrders(auth.userId!, limit: 50, force: true),
      returnProvider.fetchUserReturnRequests(
        orderProvider.orders.map((o) => o.id).toList(),
        userId: auth.userId,
        orders: orderProvider.orders,
        force: true,
      ),
    ]);

    if (mounted && orderProvider.orders.isNotEmpty && returnProvider.allUserRequests.isEmpty) {
      await returnProvider.fetchUserReturnRequests(
        orderProvider.orders.map((o) => o.id).toList(),
        userId: auth.userId,
        orders: orderProvider.orders,
        force: true,
      );
    }
  }

  String _formatDate(String? raw, [String? fallbackDate]) {
    final dateStr = (raw != null && raw.trim().isNotEmpty) ? raw : fallbackDate;
    if (dateStr == null || dateStr.trim().isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return dateStr.contains('T') ? dateStr.split('T').first : dateStr;
    }
  }

  String _getOrderDisplayId(ReturnRequestModel req, List<ApiOrder> orders) {
    // 1. If req has orderUiId and it's not a raw 36-char UUID, use it directly
    if (req.orderUiId != null && req.orderUiId!.trim().isNotEmpty) {
      final ui = req.orderUiId!.trim();
      if (ui.length <= 20 && !ui.contains('-') || ui.startsWith('ORD-')) {
        return ui;
      }
    }

    // 2. Try looking up in orders list by orderId
    if (req.orderId.isNotEmpty) {
      final match = orders.cast<ApiOrder?>().firstWhere(
        (o) => o != null && (o.id == req.orderId || o.uiId == req.orderId),
        orElse: () => null,
      );
      if (match != null && match.uiId != null && match.uiId!.trim().isNotEmpty) {
        return match.uiId!.trim();
      }
    }

    // 3. Fallback: Format clean short ID from orderUiId or orderId
    final raw = (req.orderUiId != null && req.orderUiId!.trim().isNotEmpty)
        ? req.orderUiId!.trim()
        : req.orderId.trim();

    if (raw.isEmpty) {
      if (req.id.isNotEmpty) {
        final shortId = req.id.length > 8 ? req.id.substring(0, 8).toUpperCase() : req.id.toUpperCase();
        return shortId;
      }
      return 'Order';
    }

    // If it's a long UUID, format cleanly to ORD-XXXXXXXX
    if (raw.contains('-') || raw.length > 12) {
      final segment = raw.contains('-') ? raw.split('-').first.toUpperCase() : raw.substring(0, 8).toUpperCase();
      return 'ORD-$segment';
    }

    return raw;
  }

  double _getCardRefundAmount(ReturnRequestModel req, ApiOrder? matchingOrder) {
    if (req.totalRefundAmount > 0) return req.totalRefundAmount;
    if (matchingOrder == null) return 0.0;
    if (req.items.isEmpty) return matchingOrder.totalAmount;

    double calculated = 0.0;
    for (final retItem in req.items) {
      final match = matchingOrder.items.cast<ApiOrderItem?>().firstWhere(
        (oi) => (oi != null && oi.productId.isNotEmpty && oi.productId == retItem.productId) ||
                (oi != null && oi.orderItemId != null && oi.orderItemId == retItem.orderItemId) ||
                (oi != null && oi.productName != null && oi.productName!.toLowerCase() == retItem.productName.toLowerCase()),
        orElse: () => null,
      );
      if (match != null) {
        calculated += match.unitPrice * (retItem.quantity > 0 ? retItem.quantity : 1);
      }
    }
    return calculated > 0 ? calculated : matchingOrder.totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    final returnProvider = context.watch<ReturnRequestProvider>();
    final orderProvider = context.watch<UserOrderProvider>();
    final allRequests = returnProvider.allUserRequests;
    final orders = orderProvider.orders;

    final filtered = allRequests.where((r) {
      if (_statusFilter == 'ALL') return true;
      return r.status.toUpperCase() == _statusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('my_return_requests'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: _amber,
        child: Column(
          children: [
            // Filter Pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', context.tr('all')),
                    const SizedBox(width: 8),
                    _buildFilterChip('PENDING', context.tr('pending')),
                    const SizedBox(width: 8),
                    _buildFilterChip('ACCEPTED', context.tr('accepted')),
                    const SizedBox(width: 8),
                    _buildFilterChip('REJECTED', context.tr('rejected')),
                  ],
                ),
              ),
            ),
            const Divider(color: _border, height: 1),

            Expanded(
              child: returnProvider.isLoading && allRequests.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final request = filtered[index];
                            return _buildReturnCard(request, orders);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _amber : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReturnCard(ReturnRequestModel req, List<ApiOrder> orders) {
    final orderDisplay = _getOrderDisplayId(req, orders);
    final matchingOrder = orders.cast<ApiOrder?>().firstWhere(
      (o) => o != null && (o.id == req.orderId || o.uiId == req.orderId),
      orElse: () => null,
    );
    final displayRefund = _getCardRefundAmount(req, matchingOrder);

    final isPending = req.isPending;
    final isAccepted = req.isAccepted;
    final isRejected = req.isRejected;

    Color badgeBg;
    Color badgeBorder;
    Color badgeFg;
    String badgeText;
    IconData badgeIcon;

    if (isAccepted) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeBorder = const Color(0xFF86EFAC);
      badgeFg = _success;
      badgeText = 'Accepted';
      badgeIcon = LucideIcons.check;
    } else if (isRejected) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeBorder = const Color(0xFFFCA5A5);
      badgeFg = _error;
      badgeText = 'Rejected';
      badgeIcon = LucideIcons.x;
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeBorder = const Color(0xFFFCD34D);
      badgeFg = _amber;
      badgeText = 'Pending Review';
      badgeIcon = LucideIcons.clock;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReturnRequestDetailPage(
                returnRequest: req,
                order: matchingOrder,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order ID + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.package, size: 16, color: _amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Order #$orderDisplay',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 11, color: badgeFg),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items summary
              Text(
                '${req.items.length} item${req.items.length == 1 ? '' : 's'} requested for return (${req.items.map((i) => i.productName).join(', ')})',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: _textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 8),

              // Bottom Row: Date + Refund Amount + Arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requested: ${_formatDate(req.createdAt, matchingOrder?.createdAt)}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${displayRefund.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.chevronRight, size: 16, color: _textSecondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.rotateCcw, size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Return Requests Found',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Eligible delivered orders can be returned from the Order Details page.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

