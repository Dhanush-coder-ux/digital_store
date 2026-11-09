// lib/screens/return_request_page.dart
//
// Screen allowing customer to select items from an eligible delivered order,
// specify return quantities and reasons, add description, and submit a return request.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';
import '../models/return_request_model.dart';
import '../models/return_request_provider.dart';
import '../models/profile_provider.dart';
import '../core/auth/auth_provider.dart';
import 'return_request_detail_page.dart';

class ReturnRequestPage extends StatefulWidget {
  final ApiOrder order;
  final Shop? shop;

  const ReturnRequestPage({
    super.key,
    required this.order,
    this.shop,
  });

  @override
  State<ReturnRequestPage> createState() => _ReturnRequestPageState();
}

class _ReturnRequestPageState extends State<ReturnRequestPage> {
  // Theme constants
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _amber = Color(0xFFD97706);
  static const Color _error = Color(0xFFDC2626);
  static const Color _success = Color(0xFF16A34A);

  static const List<String> _suggestedReasons = [
    'Product damaged',
    'Defective product',
    'Wrong product received',
    'Missing parts or accessories',
    'Product not as described',
    'Incorrect size or variant',
    'Other',
  ];

  // Selection state per item index:
  // selected, returnQty, reason
  final Map<int, bool> _selectedMap = {};
  final Map<int, double> _qtyMap = {};
  final Map<int, String> _reasonMap = {};

  final TextEditingController _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Default select first item
    for (int i = 0; i < widget.order.items.length; i++) {
      _selectedMap[i] = i == 0;
      _qtyMap[i] = widget.order.items[i].qty > 0 ? 1.0 : 1.0;
      _reasonMap[i] = _suggestedReasons.first;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  int get _selectedCount =>
      _selectedMap.values.where((selected) => selected).length;

  double get _totalEstimatedRefund {
    double total = 0;
    for (int i = 0; i < widget.order.items.length; i++) {
      if (_selectedMap[i] == true) {
        final item = widget.order.items[i];
        final qty = _qtyMap[i] ?? 1.0;
        total += item.unitPrice * qty;
      }
    }
    return total;
  }

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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product to return.'),
          backgroundColor: _error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final returnProvider = context.read<ReturnRequestProvider>();

    final customerName = (profile.userName.isNotEmpty ? profile.userName : null) ??
        widget.order.customerName ??
        'Customer';
    final customerPhone = (auth.mobile != null && auth.mobile!.isNotEmpty ? auth.mobile : null) ??
        widget.order.customerPhone ??
        '';
    final customerEmail = auth.email ?? '';
    final customerId = auth.userId ?? widget.order.customerId ?? '';

    final List<CustomerReturnItemPayload> returnItems = [];

    for (int i = 0; i < widget.order.items.length; i++) {
      if (_selectedMap[i] == true) {
        final itm = widget.order.items[i];
        final qty = _qtyMap[i] ?? 1.0;
        final reason = _reasonMap[i] ?? _suggestedReasons.first;

        returnItems.add(
          CustomerReturnItemPayload(
            orderItemId: itm.orderItemId ?? itm.productId,
            productId: itm.productId,
            quantity: qty,
            unit: itm.unit,
            reason: reason,
          ),
        );
      }
    }

    final payload = CreateReturnRequestPayload(
      orderId: widget.order.id,
      shopId: widget.order.shopId,
      items: returnItems,
      description: _descController.text.trim(),
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerId: customerId,
      paymentInfos: widget.order.paymentInfos ?? const {
        'method': 'ORIGINAL_PAYMENT',
        'status': 'PENDING_REFUND',
      },
    );

    final result = await returnProvider.submitReturnRequest(payload);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Return request submitted successfully!')),
            ],
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Return Request Detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReturnRequestDetailPage(
            returnRequest: result,
            order: widget.order,
          ),
        ),
      );
    } else {
      final err = returnProvider.error ?? 'Failed to submit return request.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnProvider = context.watch<ReturnRequestProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    final displayOrderId = widget.order.uiId ?? widget.order.id;
    final customerName = (profile.userName.isNotEmpty ? profile.userName : null) ??
        widget.order.customerName ??
        'Customer';
    final customerPhone = (auth.mobile != null && auth.mobile!.isNotEmpty ? auth.mobile : null) ??
        widget.order.customerPhone ??
        '—';
    final customerEmail = auth.email ?? '—';

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
          'Request Return',
          style: TextStyle(
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── Section 1: Order Information Card ─────────────────────
            _buildOrderInfoCard(displayOrderId),
            const SizedBox(height: 20),

            // ── Section 2: Product Selection ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Products to Return',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  '$_selectedCount of ${widget.order.items.length} selected',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...widget.order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildProductItemCard(index, item);
            }),
            const SizedBox(height: 20),

            // ── Section 3: Additional Description ─────────────────────
            const Text(
              'Reason & Description',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    maxLength: 500,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Please explain why you want to return these items. (e.g. Broken seal upon delivery, defective part)...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Detailed description is required.';
                      }
                      if (val.trim().length < 5) {
                        return 'Please provide at least 5 characters.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 4: Customer Details ───────────────────────────
            const Text(
              'Customer Contact Information',
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
              child: Column(
                children: [
                  _buildCustomerInfoRow(LucideIcons.user, 'Name', customerName),
                  const Divider(color: _border, height: 16),
                  _buildCustomerInfoRow(LucideIcons.phone, 'Phone', customerPhone),
                  const Divider(color: _border, height: 16),
                  _buildCustomerInfoRow(LucideIcons.mail, 'Email', customerEmail),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 5: Refund & Submission Summary ────────────────
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // ── Submit Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (returnProvider.isSubmitting || _selectedCount == 0)
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  disabledBackgroundColor: const Color(0xFFFDE68A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: returnProvider.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.rotateCcw, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Submit Return Request',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(String orderId) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.package, size: 18, color: _amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(widget.order.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.check, size: 12, color: _success),
                    SizedBox(width: 4),
                    Text(
                      'Delivered',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.shop != null) ...[
            const SizedBox(height: 10),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.store, size: 14, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.shop!.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItemCard(int index, ApiOrderItem item) {
    final isSelected = _selectedMap[index] ?? false;
    final currentQty = _qtyMap[index] ?? 1.0;
    final maxQty = item.qty > 0 ? item.qty : 1.0;
    final currentReason = _reasonMap[index] ?? _suggestedReasons.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _amber : _border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  activeColor: _amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedMap[index] = val ?? false;
                    });
                  },
                ),
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFF1F5F9),
                    child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              LucideIcons.package,
                              size: 24,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : const Icon(
                            LucideIcons.package,
                            size: 24,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Product',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ordered: ${maxQty.toInt()} ${item.unit ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sub-controls if item is selected
          if (isSelected) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13),
                  bottomRight: Radius.circular(13),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Return Quantity:',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          _buildQtyButton(
                            icon: LucideIcons.minus,
                            onTap: currentQty > 1
                                ? () {
                                    setState(() {
                                      _qtyMap[index] = currentQty - 1;
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '${currentQty.toInt()}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          _buildQtyButton(
                            icon: LucideIcons.plus,
                            onTap: currentQty < maxQty
                                ? () {
                                    setState(() {
                                      _qtyMap[index] = currentQty + 1;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Return Reason Dropdown
                  const Text(
                    'Return Reason:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentReason,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                        onChanged: (newReason) {
                          if (newReason != null) {
                            setState(() {
                              _reasonMap[index] = newReason;
                            });
                          }
                        },
                        items: _suggestedReasons.map((reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                      ),
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

  Widget _buildQtyButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _surface : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? _border : const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? _textPrimary : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items Selected:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
              Text(
                '$_selectedCount item${_selectedCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Refund Value:',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Text(
                '₹${_totalEstimatedRefund.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

