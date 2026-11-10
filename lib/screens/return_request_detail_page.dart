// lib/screens/return_request_detail_page.dart
//
// Shows detailed view and real-time status of a customer's return request.
// Displays order info, items, return reasons, description, seller feedback, and timeline.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/return_request_model.dart';
import '../models/return_request_provider.dart';

class ReturnRequestDetailPage extends StatefulWidget {
  final ReturnRequestModel returnRequest;
  final ApiOrder? order;

  const ReturnRequestDetailPage({
    super.key,
    required this.returnRequest,
    this.order,
  });

  @override
  State<ReturnRequestDetailPage> createState() => _ReturnRequestDetailPageState();
}

class _ReturnRequestDetailPageState extends State<ReturnRequestDetailPage> {
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _amber = Color(0xFFD97706);
  static const Color _error = Color(0xFFDC2626);
  static const Color _success = Color(0xFF16A34A);

  late ReturnRequestModel _request;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _request = widget.returnRequest;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isRefreshing = true);
    final provider = context.read<ReturnRequestProvider>();
    final list = await provider.fetchRequestsForOrder(_request.orderId, force: true);
    if (mounted) {
      final updated = list.firstWhere(
        (r) => r.id == _request.id,
        orElse: () => _request,
      );
      setState(() {
        _request = (updated.orderUiId == null || updated.orderUiId!.trim().isEmpty) &&
                _request.orderUiId != null
            ? updated.copyWith(orderUiId: _request.orderUiId)
            : updated;
        _isRefreshing = false;
      });
    }
  }

  String _getOrderDisplay() {
    if (_request.orderUiId != null && _request.orderUiId!.trim().isNotEmpty) {
      final ui = _request.orderUiId!.trim();
      if (ui.length <= 20 && !ui.contains('-') || ui.startsWith('ORD-')) {
        return ui;
      }
    }
    if (widget.order?.uiId != null && widget.order!.uiId!.trim().isNotEmpty) {
      return widget.order!.uiId!.trim();
    }
    final raw = (_request.orderUiId != null && _request.orderUiId!.trim().isNotEmpty)
        ? _request.orderUiId!.trim()
        : _request.orderId.trim();

    if (raw.isEmpty) {
      return _request.id.isNotEmpty
          ? (_request.id.length > 8 ? _request.id.substring(0, 8).toUpperCase() : _request.id.toUpperCase())
          : 'Order';
    }

    if (raw.contains('-') || raw.length > 12) {
      final segment = raw.contains('-') ? raw.split('-').first.toUpperCase() : raw.substring(0, 8).toUpperCase();
      return 'ORD-$segment';
    }

    return raw;
  }

  String _formatDateTime(String? raw, [String? fallbackDate]) {
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
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $ampm';
    } catch (_) {
      return dateStr.contains('T') ? dateStr.split('T').first : dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _request.status.toUpperCase();
    final isPending = status == 'PENDING';
    final isCompleted = status == 'COMPLETED';
    final isAccepted = status == 'ACCEPTED' || isCompleted;
    final isRejected = status == 'REJECTED';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Return Request Details',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                  )
                : const Icon(LucideIcons.refreshCw, color: _textSecondary, size: 18),
            onPressed: _isRefreshing ? null : _refreshDetails,
          ),
        ],
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDetails,
        color: _amber,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── Section 1: Status Hero Banner ────────────────────────
            _buildStatusHeroBanner(isPending, isAccepted, isRejected),
            const SizedBox(height: 16),

            // ── Section 2: Seller Admin Notes (if any) ───────────────
            if (_request.adminNotes != null && _request.adminNotes!.trim().isNotEmpty) ...[
              _buildAdminNotesCard(_request.adminNotes!),
              const SizedBox(height: 16),
            ],

            // ── Section 3: Request & Order Metadata ──────────────────
            _buildMetadataCard(),
            const SizedBox(height: 20),

            // ── Section 4: Return Items List ─────────────────────────
            const Text(
              'Items to Return',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._request.items.map((item) => _buildItemCard(item)),
            const SizedBox(height: 16),

            // ── Section 5: Customer Description ──────────────────────
            const Text(
              'Customer Description',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Text(
                _request.description.isNotEmpty
                    ? _request.description
                    : 'No description provided.',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 6: Status Timeline / History ─────────────────
            const Text(
              'Request Timeline',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimelineCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeroBanner(bool isPending, bool isAccepted, bool isRejected) {
    Color bg;
    Color borderCol;
    Color fg;
    IconData icon;
    String title;
    String subtitle;

    if (isAccepted) {
      bg = const Color(0xFFF0FDF4);
      borderCol = const Color(0xFFBBF7D0);
      fg = _success;
      icon = LucideIcons.checkCircle2;
      title = _request.isCompleted ? 'Return Completed' : 'Return Request Accepted';
      subtitle = _request.isCompleted
          ? 'Your return and refund have been processed successfully.'
          : 'The merchant has approved your return request.';
    } else if (isRejected) {
      bg = const Color(0xFFFEF2F2);
      borderCol = const Color(0xFFFECACA);
      fg = _error;
      icon = LucideIcons.xCircle;
      title = 'Return Request Rejected';
      subtitle = 'The merchant reviewed and rejected this request.';
    } else {
      bg = const Color(0xFFFFFBEB);
      borderCol = const Color(0xFFFDE68A);
      fg = _amber;
      icon = LucideIcons.clock;
      title = 'Pending Merchant Review';
      subtitle = 'Your return request has been submitted and is awaiting review.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderCol),
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.messageSquare, size: 15, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Seller Response / Notes:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: Color(0xFF1E3A8A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final orderDisplay = _getOrderDisplay();
    double refundAmount = _request.totalRefundAmount;
    if (refundAmount == 0 && widget.order != null) {
      if (_request.items.isEmpty) {
        refundAmount = widget.order!.totalAmount;
      } else {
        for (final retItem in _request.items) {
          final match = widget.order!.items.cast<ApiOrderItem?>().firstWhere(
            (oi) => (oi != null && oi.productId.isNotEmpty && oi.productId == retItem.productId) ||
                    (oi != null && oi.orderItemId != null && oi.orderItemId == retItem.orderItemId) ||
                    (oi != null && oi.productName != null && oi.productName!.toLowerCase() == retItem.productName.toLowerCase()),
            orElse: () => null,
          );
          if (match != null) {
            refundAmount += match.unitPrice * (retItem.quantity > 0 ? retItem.quantity : 1);
          }
        }
        if (refundAmount == 0) refundAmount = widget.order!.totalAmount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildInfoRow('Request ID', _request.id.substring(0, _request.id.length > 8 ? 8 : _request.id.length).toUpperCase()),
          const Divider(color: _border, height: 16),
          _buildInfoRow('Order ID', '#$orderDisplay'),
          const Divider(color: _border, height: 16),
          _buildInfoRow('Submitted On', _formatDateTime(_request.createdAt, widget.order?.createdAt)),
          const Divider(color: _border, height: 16),
          _buildInfoRow('Total Refund Value', '₹${refundAmount.toStringAsFixed(2)}', isBold: true, valueColor: _amber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? _textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ReturnItemDetail item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.package, size: 20, color: Color(0xFF64748B)),
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
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    if (item.variantName != null && item.variantName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.variantName!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Qty: ${item.quantity.toInt()} ${item.unit ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Refund: ₹${(item.totalAmount > 0 ? item.totalAmount : item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.reason != null && item.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.helpCircle, size: 12, color: _textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Reason: ${item.reason!}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final history = _request.statusHistory;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildTimelineStep(
            title: 'Return Request Submitted',
            subtitle: _formatDateTime(_request.createdAt),
            isDone: true,
            isCurrent: _request.isPending,
            color: _amber,
          ),
          if (_request.isAccepted || _request.isCompleted) ...[
            _buildTimelineStep(
              title: _request.isCompleted ? 'Return Completed & Refunded' : 'Request Approved by Merchant',
              subtitle: _formatDateTime(_request.updatedAt),
              isDone: true,
              isCurrent: true,
              color: _success,
            ),
          ] else if (_request.isRejected) ...[
            _buildTimelineStep(
              title: 'Request Rejected by Merchant',
              subtitle: _formatDateTime(_request.updatedAt),
              isDone: true,
              isCurrent: true,
              color: _error,
            ),
          ] else ...[
            _buildTimelineStep(
              title: 'Merchant Review',
              subtitle: 'Awaiting decision',
              isDone: false,
              isCurrent: false,
              color: _textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

