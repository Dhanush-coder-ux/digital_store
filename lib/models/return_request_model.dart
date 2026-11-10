// lib/models/return_request_model.dart
//
// Models for customer return requests matching backend Hyperlocal-Order-Service schemas.
//

class CustomerReturnItemPayload {
  final String? orderItemId;
  final String? productId;
  final double quantity;
  final String? unit;
  final String? reason;
  final String? productName;
  final double? price;
  final double? totalAmount;

  const CustomerReturnItemPayload({
    this.orderItemId,
    this.productId,
    required this.quantity,
    this.unit,
    this.reason,
    this.productName,
    this.price,
    this.totalAmount,
  });

  Map<String, dynamic> toJson() => {
        if (orderItemId != null && orderItemId!.isNotEmpty)
          'order_item_id': orderItemId,
        if (productId != null && productId!.isNotEmpty)
          'product_id': productId,
        'quantity': quantity,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

class CreateReturnRequestPayload {
  final String orderId;
  final String? orderUiId;
  final String? shopId;
  final List<CustomerReturnItemPayload> items;
  final String description;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerId;
  final Map<String, dynamic>? paymentInfos;
  final double? refundAmount;

  const CreateReturnRequestPayload({
    required this.orderId,
    this.orderUiId,
    this.shopId,
    required this.items,
    required this.description,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerId,
    this.paymentInfos,
    this.refundAmount,
  });

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        if (orderUiId != null && orderUiId!.isNotEmpty) 'order_ui_id': orderUiId,
        if (shopId != null && shopId!.isNotEmpty) 'shop_id': shopId,
        'items': items.map((i) => i.toJson()).toList(),
        'description': description.trim(),
        'payment_infos': paymentInfos ?? const {
          'method': 'ORIGINAL_PAYMENT',
          'status': 'PENDING_REFUND',
        },
        if (refundAmount != null && refundAmount! > 0)
          'refund_amount': refundAmount,
        if (customerName != null && customerName!.isNotEmpty)
          'customer_name': customerName,
        if (customerPhone != null && customerPhone!.isNotEmpty)
          'customer_phone': customerPhone,
        if (customerEmail != null && customerEmail!.isNotEmpty)
          'customer_email': customerEmail,
        if (customerId != null && customerId!.isNotEmpty)
          'customer_id': customerId,
      };
}

class ReturnItemDetail {
  final String orderItemId;
  final String productId;
  final String productName;
  final String? variantName;
  final double quantity;
  final double price;
  final double totalAmount;
  final String? unit;
  final String? reason;

  const ReturnItemDetail({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    this.unit,
    this.reason,
  });

  factory ReturnItemDetail.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return ReturnItemDetail(
      orderItemId: json['order_item_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['name']?.toString() ?? 'Item',
      variantName: json['variant_name']?.toString(),
      quantity: parseDouble(json['quantity'] ?? json['qty'] ?? 1),
      price: parseDouble(json['price'] ?? json['unit_price'] ?? 0),
      totalAmount: parseDouble(json['total_amount'] ?? 0),
      unit: json['unit']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

class ReturnStatusHistoryItem {
  final String status;
  final String? updatedBy;
  final String? timestamp;
  final String? notes;

  const ReturnStatusHistoryItem({
    required this.status,
    this.updatedBy,
    this.timestamp,
    this.notes,
  });

  factory ReturnStatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReturnStatusHistoryItem(
      status: (json['status'] ?? 'PENDING').toString(),
      updatedBy: json['updated_by']?.toString(),
      timestamp: json['timestamp']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class ReturnRequestModel {
  final String id;
  final String orderId;
  final String? orderUiId;
  final String shopId;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final List<ReturnItemDetail> items;
  final String description;
  final String status; // PENDING, ACCEPTED, REJECTED
  final String? adminNotes;
  final List<ReturnStatusHistoryItem> statusHistory;
  final String? createdAt;
  final String? updatedAt;

  const ReturnRequestModel({
    required this.id,
    required this.orderId,
    this.orderUiId,
    required this.shopId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.items = const [],
    required this.description,
    required this.status,
    this.adminNotes,
    this.statusHistory = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  double get totalRefundAmount =>
      items.fold(0.0, (sum, itm) => sum + (itm.totalAmount > 0 ? itm.totalAmount : (itm.price * itm.quantity)));

  int get totalQuantity =>
      items.fold(0, (sum, itm) => sum + itm.quantity.toInt());

  ReturnRequestModel copyWith({
    String? id,
    String? orderId,
    String? orderUiId,
    String? shopId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<ReturnItemDetail>? items,
    String? description,
    String? status,
    String? adminNotes,
    List<ReturnStatusHistoryItem>? statusHistory,
    String? createdAt,
    String? updatedAt,
  }) {
    return ReturnRequestModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderUiId: orderUiId ?? this.orderUiId,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      description: description ?? this.description,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReturnRequestModel.fromJson(Map<String, dynamic> json) {
    List<ReturnItemDetail> parseItems(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => ReturnItemDetail.fromJson(e))
            .toList();
      }
      return [];
    }

    List<ReturnStatusHistoryItem> parseHistory(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => ReturnStatusHistoryItem.fromJson(e))
            .toList();
      }
      return [];
    }

    // Robust order UI ID extraction
    final rawOrderUiId = json['order_ui_id'] ??
        json['order_uiid'] ??
        json['orderUiId'] ??
        json['ui_id'] ??
        json['order_number'] ??
        (json['order'] is Map ? (json['order']['ui_id'] ?? json['order']['uiid'] ?? json['order']['order_ui_id']) : null);
    final String? parsedOrderUiId = (rawOrderUiId != null && rawOrderUiId.toString().trim().isNotEmpty)
        ? rawOrderUiId.toString().trim()
        : null;

    final rawOrderId = json['order_id'] ?? json['orderId'] ?? (json['order'] is Map ? json['order']['id'] : null);
    final String parsedOrderId = rawOrderId?.toString().trim() ?? '';

    return ReturnRequestModel(
      id: json['id']?.toString() ?? '',
      orderId: parsedOrderId,
      orderUiId: parsedOrderUiId,
      shopId: json['shop_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString(),
      items: parseItems(json['items']),
      description: json['description']?.toString() ?? '',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      adminNotes: json['admin_notes']?.toString(),
      statusHistory: parseHistory(json['status_history']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

