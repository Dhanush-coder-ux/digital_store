// lib/models/order_model.dart
//
// Order model matching the Order Service response schema.
// CreateOrderPayload maps to backend's CreateOrderSchema:
//   shop_id, session_id (cart session), status (enum), origin (enum)
//

class ApiOrder {
  final String id;
  final String? uiId;
  final String shopId;
  final String? customerId;
  final String status;
  final String? description;
  final double totalAmount;
  final List<ApiOrderItem> items;
  final Map<String, dynamic>? calculationInfos;
  final Map<String, dynamic>? paymentInfos;
  final Map<String, dynamic>? additionalInfos;
  final Map<String, dynamic>? chargesInfos;
  final Map<String, dynamic>? deliveryAddress;
  final String? customerName;
  final String? customerPhone;
  final String? addressId;
  final String? fullAddress;
  final String? city;
  final String? pincode;
  final String? state;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final String? otp;

  const ApiOrder({
    required this.id,
    this.uiId,
    required this.shopId,
    this.customerId,
    required this.status,
    this.description,
    required this.totalAmount,
    this.items = const [],
    this.calculationInfos,
    this.paymentInfos,
    this.additionalInfos,
    this.chargesInfos,
    this.deliveryAddress,
    this.customerName,
    this.customerPhone,
    this.addressId,
    this.fullAddress,
    this.city,
    this.pincode,
    this.state,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.otp,
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
      final itemInfos = json['item_infos'];
      if (itemInfos is Map<String, dynamic>) {
        total = parseDouble(itemInfos['total_order_amount'] ?? 0);
      }
    }
    if (total == 0) {
      total = parseDouble(json['total_amount'] ?? json['total'] ?? 0);
    }

    final additionalInfos = json['additional_infos'] is Map<String, dynamic>
        ? json['additional_infos'] as Map<String, dynamic>
        : null;

    final chargesInfos = json['charges_infos'] is Map<String, dynamic>
        ? json['charges_infos'] as Map<String, dynamic>
        : null;

    // Delivery address map can be in additional_infos, calculation_infos, or top-level
    Map<String, dynamic>? deliveryAddressMap;
    if (json['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = json['delivery_address'] as Map<String, dynamic>;
    } else if (additionalInfos?['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = additionalInfos!['delivery_address'] as Map<String, dynamic>;
    } else if (json['calculation_infos'] is Map &&
        json['calculation_infos']['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = json['calculation_infos']['delivery_address'] as Map<String, dynamic>;
    }

    final String? addressId = json['address_id']?.toString() ??
        deliveryAddressMap?['address_id']?.toString() ??
        deliveryAddressMap?['id']?.toString() ??
        additionalInfos?['address_id']?.toString();

    final String? fullAddress = json['full_address']?.toString() ??
        json['address']?.toString() ??
        deliveryAddressMap?['full_address']?.toString() ??
        deliveryAddressMap?['address']?.toString() ??
        additionalInfos?['full_address']?.toString() ??
        (json['delivery_address'] is String ? json['delivery_address'].toString() : null) ??
        (additionalInfos?['delivery_address'] is String ? additionalInfos!['delivery_address'].toString() : null);

    final String? city = json['city']?.toString() ??
        deliveryAddressMap?['city']?.toString() ??
        additionalInfos?['city']?.toString();

    final String? pincode = json['pincode']?.toString() ??
        deliveryAddressMap?['pincode']?.toString() ??
        additionalInfos?['pincode']?.toString();

    final String? state = json['state']?.toString() ??
        deliveryAddressMap?['state']?.toString() ??
        additionalInfos?['state']?.toString();

    final customerMap = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : null;

    final String? customerName = json['customer_name']?.toString() ??
        json['name']?.toString() ??
        additionalInfos?['customer_name']?.toString() ??
        additionalInfos?['name']?.toString() ??
        deliveryAddressMap?['name']?.toString() ??
        customerMap?['name']?.toString();

    final String? customerPhone = json['customer_phone']?.toString() ??
        json['phone']?.toString() ??
        additionalInfos?['customer_phone']?.toString() ??
        additionalInfos?['phone']?.toString() ??
        deliveryAddressMap?['phone']?.toString() ??
        customerMap?['phone']?.toString();

    final String? note = json['note']?.toString() ??
        additionalInfos?['note']?.toString();

    return ApiOrder(
      id: json['id']?.toString() ?? '',
      uiId: json['ui_id']?.toString(),
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
      additionalInfos: additionalInfos,
      chargesInfos: chargesInfos,
      deliveryAddress: deliveryAddressMap,
      customerName: customerName,
      customerPhone: customerPhone,
      addressId: addressId,
      fullAddress: fullAddress,
      city: city,
      pincode: pincode,
      state: state,
      note: note,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      otp: json['otp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'status': status,
        'total_amount': totalAmount,
        'items': items.map((e) => e.toJson()).toList(),
        if (additionalInfos != null) 'additional_infos': additionalInfos,
        if (chargesInfos != null) 'charges_infos': chargesInfos,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
        if (addressId != null) 'address_id': addressId,
        if (fullAddress != null) 'full_address': fullAddress,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        if (state != null) 'state': state,
        if (note != null) 'note': note,
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
  final String? imageUrl;

  const ApiOrderItem({
    required this.productId,
    this.variantId,
    this.batchId,
    required this.qty,
    this.unit,
    required this.unitPrice,
    required this.lineTotal,
    this.productName,
    this.imageUrl,
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    String? extractImage() {
      dynamic img = json['image_url'] ?? json['images'] ?? json['image'] ?? json['product_image'];
      if (img == null && json['product'] is Map) {
        img = json['product']['image_url'] ?? json['product']['images'] ?? json['product']['image'];
      }
      if (img == null && json['item_info'] is Map) {
        img = json['item_info']['image_url'] ?? json['item_info']['images'] ?? json['item_info']['image'];
        if (img == null && json['item_info']['product'] is Map) {
          img = json['item_info']['product']['image_url'] ?? json['item_info']['product']['images'] ?? json['item_info']['product']['image'];
        }
      }
      if (img is List && img.isNotEmpty) {
        final str = img.first?.toString() ?? '';
        return str.isNotEmpty ? str : null;
      }
      if (img is String && img.trim().isNotEmpty) {
        return img;
      }
      return null;
    }

    return ApiOrderItem(
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      batchId: json['batch_id']?.toString(),
      qty: parseDouble(json['qty'] ?? json['quantity']),
      unit: json['unit']?.toString(),
      unitPrice: parseDouble(json['unit_price'] ?? json['selling_price'] ?? json['sell_price'] ?? 0),
      lineTotal: parseDouble(json['line_total'] ?? json['total_amount'] ?? 0),
      productName: json['product_name']?.toString() ??
          json['name']?.toString(),
      imageUrl: extractImage(),
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
  final double? latitude;
  final double? longitude;
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
    this.latitude,
    this.longitude,
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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        if (state != null) 'state': state,
      };
}
