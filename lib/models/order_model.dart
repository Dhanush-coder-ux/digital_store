// lib/models/order_model.dart
//
// Order model matching the Order Service response schema.
// CreateOrderPayload maps to backend's CreateOrderSchema:
//   shop_id, session_id (cart session), status (enum), origin (enum)
//

class ApiOrder {
  final String id;
  final String shopId;
  final String? customerId;
  final String status;
  final String? description;
  final double totalAmount;
  final List<ApiOrderItem> items;
  final Map<String, dynamic>? calculationInfos;
  final Map<String, dynamic>? paymentInfos;
  final String? createdAt;
  final String? updatedAt;

  const ApiOrder({
    required this.id,
    required this.shopId,
    this.customerId,
    required this.status,
    this.description,
    required this.totalAmount,
    this.items = const [],
    this.calculationInfos,
    this.paymentInfos,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    List<ApiOrderItem> parseItems(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => ApiOrderItem.fromJson(e))
            .toList();
      }
      return [];
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    // Calculate total from calculation_infos if available
    double total = 0;
    final calcInfos = json['calculation_infos'];
    if (calcInfos is Map<String, dynamic>) {
      total = parseDouble(calcInfos['total'] ?? calcInfos['grand_total'] ?? 0);
    }
    if (total == 0) {
      total = parseDouble(json['total_amount'] ?? json['total'] ?? 0);
    }

    return ApiOrder(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      description: json['description']?.toString(),
      totalAmount: total,
      items: parseItems(json['items']),
      calculationInfos: json['calculation_infos'] is Map<String, dynamic>
          ? json['calculation_infos'] as Map<String, dynamic>
          : null,
      paymentInfos: json['payment_infos'] is Map<String, dynamic>
          ? json['payment_infos'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'status': status,
        'total_amount': totalAmount,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class ApiOrderItem {
  final String productId;
  final String? variantId;
  final String? batchId;
  final double qty;
  final String? unit;
  final double unitPrice;
  final double lineTotal;
  final String? productName;

  const ApiOrderItem({
    required this.productId,
    this.variantId,
    this.batchId,
    required this.qty,
    this.unit,
    required this.unitPrice,
    required this.lineTotal,
    this.productName,
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return ApiOrderItem(
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      batchId: json['batch_id']?.toString(),
      qty: parseDouble(json['qty'] ?? json['quantity']),
      unit: json['unit']?.toString(),
      unitPrice: parseDouble(json['unit_price'] ?? json['selling_price'] ?? 0),
      lineTotal: parseDouble(json['line_total'] ?? 0),
      productName: json['product_name']?.toString() ??
          json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'variant_id': variantId,
        'batch_id': batchId,
        'qty': qty,
        'unit': unit,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };
}

/// Payload for creating an order.
/// Maps to backend's CreateOrderSchema:
/// {shop_id, session_id, status, origin, calculation_infos, payment_infos, ...}
class CreateOrderPayload {
  final String shopId;

  /// The cart session_id from the cart init step
  final String sessionId;

  final String? customerId;

  /// Order status enum value — must be a valid OrderStatusEnum string
  final String status;

  /// Order origin — must be a valid OrderOriginEnum string
  final String origin;

  final Map<String, dynamic> calculationInfos;
  final Map<String, dynamic> chargesInfos;
  final Map<String, dynamic> paymentInfos;
  final Map<String, dynamic>? additionalInfos;
  
  final String? userId;
  final String? name;
  final String? phone;
  final String? addressId;
  final String? fullAddress;
  final String? city;
  final String? pincode;
  final String? state;

  const CreateOrderPayload({
    required this.shopId,
    required this.sessionId,
    this.customerId,
    this.status = 'PENDING',
    this.origin = 'ONLINE',
    this.calculationInfos = const {},
    this.chargesInfos = const {},
    this.paymentInfos = const {},
    this.additionalInfos,
    this.userId,
    this.name,
    this.phone,
    this.addressId,
    this.fullAddress,
    this.city,
    this.pincode,
    this.state,
  });

  Map<String, dynamic> toJson() => {
        'shop_id': shopId,
        'session_id': sessionId,
        'status': status,
        'origin': origin,
        'calculation_infos': calculationInfos,
        'charges_infos': chargesInfos,
        'payment_infos': paymentInfos,
        if (customerId != null) 'customer_id': customerId,
        if (additionalInfos != null) 'additional_infos': additionalInfos,
        if (userId != null) 'user_id': userId,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (addressId != null) 'address_id': addressId,
        if (fullAddress != null) 'full_address': fullAddress,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        if (state != null) 'state': state,
      };
}
