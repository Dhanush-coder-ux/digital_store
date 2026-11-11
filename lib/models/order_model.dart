// lib/models/order_model.dart
//
// Order model matching the Order Service response schema.
// CreateOrderPayload maps to backend's CreateOrderSchema:
//   shop_id, session_id (cart session), status (enum), origin (enum)
//

/// Parses a GST percentage from dynamic API/product values (e.g. "18%", 18, 0.18 -> 18.0).
double parseGstRateValue(dynamic rawGst) {
  if (rawGst == null) return 0.0;
  if (rawGst is num) {
    final v = rawGst.toDouble();
    if (v <= 0) return 0.0;
    return v <= 1.0 ? double.parse((v * 100.0).toStringAsFixed(2)) : v;
  }
  final cleaned = rawGst.toString().replaceAll('%', '').trim();
  final parsed = double.tryParse(cleaned);
  if (parsed == null || parsed <= 0) return 0.0;
  return parsed <= 1.0 && !rawGst.toString().contains('%')
      ? double.parse((parsed * 100.0).toStringAsFixed(2))
      : parsed;
}

/// Calculates base price & GST split from an inclusive unit selling price.
({double gstRate, double unitGst, double unitBasePrice}) calculateInclusiveTaxSplit(
  double unitPrice,
  double gstRate,
) {
  if (gstRate <= 0 || unitPrice <= 0) {
    return (gstRate: 0.0, unitGst: 0.0, unitBasePrice: double.parse(unitPrice.toStringAsFixed(2)));
  }
  final unitGst = double.parse((unitPrice * (gstRate / 100.0)).toStringAsFixed(2));
  final unitBasePrice = double.parse((unitPrice - unitGst).clamp(0.0, double.infinity).toStringAsFixed(2));
  return (gstRate: gstRate, unitGst: unitGst, unitBasePrice: unitBasePrice);
}

class ApiOrder {
  static const Set<String> acceptedReturnStatuses = {
    'ACCEPTED',
    'APPROVED',
    'COMPLETED',
    'RETURNED',
  };

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
  final List<dynamic> returnRequests;
  final List<dynamic> returns;

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
    this.returnRequests = const [],
    this.returns = const [],
  });

  ApiOrder copyWith({
    String? status,
    String? updatedAt,
    String? otp,
    List<dynamic>? returnRequests,
    List<dynamic>? returns,
    Map<String, dynamic>? calculationInfos,
    Map<String, dynamic>? additionalInfos,
  }) {
    return ApiOrder(
      id: id,
      uiId: uiId,
      shopId: shopId,
      customerId: customerId,
      status: status ?? this.status,
      description: description,
      totalAmount: totalAmount,
      items: items,
      calculationInfos: calculationInfos ?? this.calculationInfos,
      paymentInfos: paymentInfos,
      additionalInfos: additionalInfos ?? this.additionalInfos,
      chargesInfos: chargesInfos,
      deliveryAddress: deliveryAddress,
      customerName: customerName,
      customerPhone: customerPhone,
      addressId: addressId,
      fullAddress: fullAddress,
      city: city,
      pincode: pincode,
      state: state,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otp: otp ?? this.otp,
      returnRequests: returnRequests ?? this.returnRequests,
      returns: returns ?? this.returns,
    );
  }

  /// Items inclusive subtotal (selling price * qty).
  double get itemsSubtotal {
    final calcSub = calculationInfos?['subtotal'];
    if (calcSub != null) {
      final v = double.tryParse(calcSub.toString());
      if (v != null && v > 0) return v;
    }
    if (items.isNotEmpty) {
      return double.parse(items.fold(0.0, (s, i) => s + i.lineTotal).toStringAsFixed(2));
    }
    return totalAmount;
  }

  /// Total GST across items (prefers persisted calculationInfos.gst_amount when > 0).
  double get totalGstAmount {
    final raw = calculationInfos?['gst_amount'] ??
        calculationInfos?['total_tax'] ??
        calculationInfos?['tax_amount'];
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null && parsed > 0) {
        return double.parse(parsed.toStringAsFixed(2));
      }
    }
    return double.parse(items.fold(0.0, (s, i) => s + i.lineGstAmount).toStringAsFixed(2));
  }

  /// Total pre-tax base amount across items (excluding GST).
  double get baseSubtotal {
    final gstTotal = totalGstAmount;
    final rawTaxable = calculationInfos?['taxable_amount'] ?? calculationInfos?['base_subtotal'];
    if (rawTaxable != null) {
      final parsed = double.tryParse(rawTaxable.toString());
      if (parsed != null && parsed > 0) {
        if (gstTotal <= 0 || (parsed - itemsSubtotal).abs() >= 0.01) {
          return double.parse(parsed.toStringAsFixed(2));
        }
      }
    }
    if (items.isNotEmpty) {
      return double.parse(items.fold(0.0, (s, i) => s + i.lineBasePrice).toStringAsFixed(2));
    }
    return double.parse((itemsSubtotal - gstTotal).clamp(0.0, double.infinity).toStringAsFixed(2));
  }

  double get cgstAmount {
    final raw = calculationInfos?['cgst'];
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null && parsed > 0) return double.parse(parsed.toStringAsFixed(2));
    }
    return double.parse((totalGstAmount / 2.0).toStringAsFixed(2));
  }

  double get sgstAmount {
    final raw = calculationInfos?['sgst'];
    if (raw != null) {
      final parsed = double.tryParse(raw.toString());
      if (parsed != null && parsed > 0) return double.parse(parsed.toStringAsFixed(2));
    }
    return double.parse((totalGstAmount - cgstAmount).clamp(0.0, double.infinity).toStringAsFixed(2));
  }

  String get gstPercentLabel {
    final rates = items
        .map((i) => i.effectiveGstRate)
        .where((r) => r > 0)
        .toSet()
        .toList()
      ..sort();
    if (rates.isNotEmpty) {
      return rates.map((r) => '${r.toStringAsFixed(r % 1 == 0 ? 0 : 1)}%').join(', ');
    }
    final groups = calculationInfos?['tax_groups'];
    if (groups is List && groups.isNotEmpty) {
      final labels = groups
          .whereType<Map>()
          .map((g) => g['gstRate'])
          .where((r) => r != null)
          .map((r) => '$r%')
          .toList();
      if (labels.isNotEmpty) return labels.join(', ');
    }
    return '';
  }

  bool get isCancelledOrRejected {
    final st = status.toUpperCase().trim();
    return st == 'CANCELLED' ||
        st == 'CANCELED' ||
        st == 'REFUNDED' ||
        st == 'REJECTED';
  }

  String? get cancelledBySource {
    final direct = additionalInfos?['cancelled_by_source'] ??
        additionalInfos?['canceled_by_source'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim().toUpperCase();
    }
    final hist = additionalInfos?['status_history'];
    if (hist is List) {
      for (final entry in hist.reversed) {
        if (entry is! Map) continue;
        final toSt = (entry['to_status']?.toString() ?? '').toUpperCase().trim();
        if (toSt == 'CANCELED' || toSt == 'CANCELLED' || toSt == 'REJECTED') {
          final src =
              entry['cancelled_by_source'] ?? entry['canceled_by_source'];
          if (src != null && src.toString().trim().isNotEmpty) {
            return src.toString().trim().toUpperCase();
          }
        }
      }
    }
    return null;
  }

  String? get cancelledByDisplay {
    if (!isCancelledOrRejected) return null;
    final src = cancelledBySource ?? '';
    final rawLabel =
        (additionalInfos?['cancelled_by_label'] ?? '').toString().trim();
    final rawActor = (additionalInfos?['cancelled_by'] ?? '').toString().trim();

    if (src.contains('DIGITAL') ||
        src.contains('CUSTOMER') ||
        rawActor.toUpperCase() == 'CUSTOMER') {
      return 'Cancelled by Customer';
    }
    if (src.contains('INVENTQ') ||
        rawActor.toUpperCase().contains('INVENTQ')) {
      return 'Cancelled manually by InventQ';
    }
    if (rawLabel.isNotEmpty) return rawLabel;
    final legacy = additionalInfos?['canceled_by']?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) {
      return 'Cancelled manually by InventQ';
    }
    return null;
  }

  bool get hasAcceptedReturnRequest => returnRequests.any((rr) =>
      rr is Map &&
      acceptedReturnStatuses.contains(
        (rr['status']?.toString() ?? '').toUpperCase().trim(),
      ));

  bool get hasReturn {
    final st = status.toUpperCase().trim();
    return st == 'RETURNED' ||
        st == 'REFUNDED' ||
        returns.isNotEmpty ||
        hasAcceptedReturnRequest ||
        items.any((i) => i.isReturned);
  }

  double itemReturnedQty(ApiOrderItem item) {
    double reqQty = 0.0;
    for (final rr in returnRequests) {
      if (rr is! Map) continue;
      final st = (rr['status']?.toString() ?? '').toUpperCase().trim();
      if (!acceptedReturnStatuses.contains(st)) continue;
      final rItems = rr['items'];
      if (rItems is! List) continue;
      for (final ri in rItems) {
        if (ri is! Map) continue;
        final matchId = item.orderItemId != null &&
            item.orderItemId!.isNotEmpty &&
            ri['order_item_id']?.toString() == item.orderItemId;
        final matchProd = item.productId.isNotEmpty &&
            ri['product_id']?.toString() == item.productId;
        final matchName = item.productName != null &&
            ri['product_name']?.toString().trim().toLowerCase() ==
                item.productName!.trim().toLowerCase();
        if (matchId || matchProd || matchName) {
          reqQty += double.tryParse(ri['quantity']?.toString() ?? '0') ?? 0.0;
        }
      }
    }
    return item.returnedQuantity > reqQty ? item.returnedQuantity : reqQty;
  }

  bool isItemReturned(ApiOrderItem item) => item.isReturned || itemReturnedQty(item) > 0;

  bool get isPartiallyReturned {
    if (!hasReturn) return false;
    final st = status.toUpperCase().trim();
    if (st == 'RETURNED' || st == 'REFUNDED' || items.isEmpty) return false;
    return !items.every((item) {
      final itemSt = (item.itemStatus ?? '').toUpperCase().trim();
      if (itemSt == 'RETURNED' || itemSt == 'REFUNDED') return true;
      final retQty = itemReturnedQty(item);
      return retQty >= item.qty && item.qty > 0;
    });
  }

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

    String? firstNonEmptyString(List<dynamic> candidates) {
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
      }
      return null;
    }

    final onlineDetails = json['online_details'] is Map<String, dynamic>
        ? json['online_details'] as Map<String, dynamic>
        : null;

    // Delivery address map can be in additional_infos, calculation_infos, online_details, or top-level
    Map<String, dynamic>? deliveryAddressMap;
    if (json['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = json['delivery_address'] as Map<String, dynamic>;
    } else if (additionalInfos?['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = additionalInfos!['delivery_address'] as Map<String, dynamic>;
    } else if (json['calculation_infos'] is Map &&
        json['calculation_infos']['delivery_address'] is Map<String, dynamic>) {
      deliveryAddressMap = json['calculation_infos']['delivery_address'] as Map<String, dynamic>;
    } else if (onlineDetails != null &&
        (onlineDetails['full_address'] != null || onlineDetails['address_id'] != null)) {
      deliveryAddressMap = onlineDetails;
    }

    final String? addressId = firstNonEmptyString([
      json['address_id'],
      deliveryAddressMap?['address_id'],
      deliveryAddressMap?['id'],
      onlineDetails?['address_id'],
      additionalInfos?['address_id'],
    ]);

    final String? fullAddress = firstNonEmptyString([
      json['full_address'],
      json['address'],
      deliveryAddressMap?['full_address'],
      deliveryAddressMap?['address'],
      onlineDetails?['full_address'],
      additionalInfos?['full_address'],
      if (json['delivery_address'] is String) json['delivery_address'],
      if (additionalInfos?['delivery_address'] is String) additionalInfos!['delivery_address'],
    ]);

    final String? city = firstNonEmptyString([
      json['city'],
      deliveryAddressMap?['city'],
      onlineDetails?['city'],
      additionalInfos?['city'],
    ]);

    final String? pincode = firstNonEmptyString([
      json['pincode'],
      deliveryAddressMap?['pincode'],
      onlineDetails?['pincode'],
      additionalInfos?['pincode'],
    ]);

    final String? state = firstNonEmptyString([
      json['state'],
      deliveryAddressMap?['state'],
      onlineDetails?['state'],
      additionalInfos?['state'],
    ]);

    final customerMap = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : null;

    final String? customerName = firstNonEmptyString([
      json['customer_name'],
      json['name'],
      onlineDetails?['customer_name'],
      onlineDetails?['name'],
      additionalInfos?['customer_name'],
      additionalInfos?['name'],
      deliveryAddressMap?['name'],
      customerMap?['customer_name'],
      customerMap?['name'],
    ]);

    final String? customerPhone = firstNonEmptyString([
      json['customer_phone'],
      json['phone'],
      json['user_phone'],
      onlineDetails?['customer_phone'],
      onlineDetails?['phone'],
      additionalInfos?['customer_phone'],
      additionalInfos?['phone'],
      deliveryAddressMap?['phone'],
      customerMap?['mobile_number'],
      customerMap?['phone'],
    ]);

    final String? note = json['note']?.toString() ??
        additionalInfos?['note']?.toString();

    final parsedItems = parseItems(json['items']);
    final calcMap = json['calculation_infos'] is Map<String, dynamic>
        ? json['calculation_infos'] as Map<String, dynamic>
        : null;
    final calcItems = calcMap?['items'] is List ? (calcMap!['items'] as List) : const [];
    final hydratedItems = parsedItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      if (item.gstRate != null && item.taxablePrice != null && item.gstAmount != null) {
        return item;
      }
      Map? calcMatch;
      for (final ci in calcItems) {
        if (ci is! Map) continue;
        final idMatch = item.orderItemId != null &&
            ci['order_item_id']?.toString() == item.orderItemId;
        final prodMatch = item.productId.isNotEmpty &&
            (ci['product_id']?.toString() == item.productId ||
                ci['inventoryId']?.toString() == item.productId);
        if (idMatch || prodMatch) {
          calcMatch = ci;
          break;
        }
      }
      if (calcMatch == null && idx < calcItems.length && calcItems[idx] is Map) {
        calcMatch = calcItems[idx] as Map;
      }
      if (calcMatch == null) return item;
      final cRate = parseGstRateValue(calcMatch['gst_rate'] ?? calcMatch['gst']);
      final cGstAmt = calcMatch['gst_amount'] != null
          ? parseDouble(calcMatch['gst_amount'])
          : null;
      final cTaxableTotal = calcMatch['taxable_value'] != null
          ? parseDouble(calcMatch['taxable_value'])
          : null;
      final unitTaxable = (cTaxableTotal != null && item.qty > 0)
          ? double.parse((cTaxableTotal / item.qty).toStringAsFixed(2))
          : null;
      return item.copyWith(
        gstRate: item.gstRate ?? (cRate > 0 ? cRate : null),
        gst: item.gst ?? (cRate > 0 ? '${cRate.toStringAsFixed(cRate % 1 == 0 ? 0 : 1)}%' : null),
        taxablePrice: item.taxablePrice ?? unitTaxable,
        gstAmount: item.gstAmount ?? cGstAmt,
      );
    }).toList();

    return ApiOrder(
      id: json['id']?.toString() ?? '',
      uiId: json['ui_id']?.toString(),
      shopId: json['shop_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      description: json['description']?.toString(),
      totalAmount: total,
      items: hydratedItems,
      calculationInfos: calcMap,
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
      returnRequests: (json['return_requests'] ?? json['returnRequests']) is List
          ? ((json['return_requests'] ?? json['returnRequests']) as List)
          : const [],
      returns: json['returns'] is List ? (json['returns'] as List) : const [],
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
        'return_requests': returnRequests,
        'returns': returns,
      };
}

class ApiOrderItem {
  final String? orderItemId;
  final String productId;
  final String? variantId;
  final String? batchId;
  final double qty;
  final String? unit;
  final double unitPrice;
  final double lineTotal;
  final String? productName;
  final String? imageUrl;
  final String? gst;
  final double? gstRate;
  final double? taxablePrice;
  final double? gstAmount;
  final double returnedQuantity;
  final String? itemStatus;
  final List<dynamic> returns;

  const ApiOrderItem({
    this.orderItemId,
    required this.productId,
    this.variantId,
    this.batchId,
    required this.qty,
    this.unit,
    required this.unitPrice,
    required this.lineTotal,
    this.productName,
    this.imageUrl,
    this.gst,
    this.gstRate,
    this.taxablePrice,
    this.gstAmount,
    this.returnedQuantity = 0.0,
    this.itemStatus,
    this.returns = const [],
  });

  ApiOrderItem copyWith({
    String? imageUrl,
    String? gst,
    double? gstRate,
    double? taxablePrice,
    double? gstAmount,
    double? returnedQuantity,
    String? itemStatus,
    List<dynamic>? returns,
  }) {
    return ApiOrderItem(
      orderItemId: orderItemId,
      productId: productId,
      variantId: variantId,
      batchId: batchId,
      qty: qty,
      unit: unit,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      productName: productName,
      imageUrl: imageUrl ?? this.imageUrl,
      gst: gst ?? this.gst,
      gstRate: gstRate ?? this.gstRate,
      taxablePrice: taxablePrice ?? this.taxablePrice,
      gstAmount: gstAmount ?? this.gstAmount,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      itemStatus: itemStatus ?? this.itemStatus,
      returns: returns ?? this.returns,
    );
  }

  double get effectiveGstRate {
    if (gstRate != null && gstRate! > 0) return gstRate!;
    final parsed = parseGstRateValue(gst);
    if (parsed > 0) return parsed;
    if (gstAmount != null && gstAmount! > 0 && lineTotal > 0) {
      return double.parse(((gstAmount! / lineTotal) * 100.0).toStringAsFixed(2));
    }
    return 0.0;
  }

  double get effectiveUnitBasePrice {
    if (taxablePrice != null && taxablePrice! > 0) {
      return double.parse(taxablePrice!.toStringAsFixed(2));
    }
    if (gstAmount != null && gstAmount! > 0 && qty > 0) {
      return double.parse(((lineTotal - gstAmount!) / qty).clamp(0.0, double.infinity).toStringAsFixed(2));
    }
    return calculateInclusiveTaxSplit(unitPrice, effectiveGstRate).unitBasePrice;
  }

  double get effectiveUnitGst {
    if (gstAmount != null && gstAmount! > 0 && qty > 0) {
      return double.parse((gstAmount! / qty).toStringAsFixed(2));
    }
    return calculateInclusiveTaxSplit(unitPrice, effectiveGstRate).unitGst;
  }

  double get lineGstAmount {
    if (gstAmount != null && gstAmount! > 0) {
      return double.parse(gstAmount!.toStringAsFixed(2));
    }
    return double.parse((effectiveUnitGst * qty).toStringAsFixed(2));
  }

  double get lineBasePrice {
    if (taxablePrice != null && taxablePrice! > 0) {
      return double.parse((taxablePrice! * qty).toStringAsFixed(2));
    }
    if (gstAmount != null && gstAmount! > 0) {
      return double.parse((lineTotal - gstAmount!).clamp(0.0, double.infinity).toStringAsFixed(2));
    }
    return double.parse((effectiveUnitBasePrice * qty).toStringAsFixed(2));
  }

  bool get isReturned {
    final st = (itemStatus ?? '').toUpperCase().trim();
    return returnedQuantity > 0 ||
        st == 'RETURNED' ||
        st == 'REFUNDED' ||
        returns.isNotEmpty;
  }

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

    final qty = parseDouble(json['qty'] ?? json['quantity']);
    final unitPrice = parseDouble(json['unit_price'] ?? json['selling_price'] ?? json['sell_price'] ?? 0);
    final lineTotalRaw = parseDouble(json['line_total'] ?? json['total_amount'] ?? 0);
    final lineTotal = lineTotalRaw > 0 ? lineTotalRaw : unitPrice * qty;

    final rawGstVal = json['gst'] ??
        (json['product'] is Map ? json['product']['gst'] : null) ??
        (json['item_info'] is Map ? json['item_info']['gst'] : null);
    final parsedRate = json['gst_rate'] != null
        ? parseGstRateValue(json['gst_rate'])
        : parseGstRateValue(rawGstVal);

    final rawTaxable = json['taxable_price'];
    final double? taxablePrice = rawTaxable != null ? parseDouble(rawTaxable) : null;
    final rawGstAmt = json['gst_amount'];
    final double? gstAmount = rawGstAmt != null ? parseDouble(rawGstAmt) : null;

    return ApiOrderItem(
      orderItemId: json['id']?.toString() ?? json['order_item_id']?.toString(),
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      batchId: json['batch_id']?.toString(),
      qty: qty,
      unit: json['unit']?.toString(),
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      productName: json['product_name']?.toString() ??
          json['name']?.toString(),
      imageUrl: extractImage(),
      gst: rawGstVal?.toString(),
      gstRate: parsedRate > 0 ? parsedRate : null,
      taxablePrice: (taxablePrice != null && taxablePrice > 0) ? taxablePrice : null,
      gstAmount: (gstAmount != null && gstAmount > 0) ? gstAmount : null,
      returnedQuantity: parseDouble(json['returned_quantity']),
      itemStatus: json['status']?.toString(),
      returns: json['returns'] is List ? (json['returns'] as List) : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (orderItemId != null) 'order_item_id': orderItemId,
        'product_id': productId,
        'variant_id': variantId,
        'batch_id': batchId,
        'qty': qty,
        'unit': unit,
        'unit_price': unitPrice,
        'line_total': lineTotal,
        if (gst != null) 'gst': gst,
        if (gstRate != null) 'gst_rate': gstRate,
        if (taxablePrice != null) 'taxable_price': taxablePrice,
        if (gstAmount != null) 'gst_amount': gstAmount,
        if (returnedQuantity > 0) 'returned_quantity': returnedQuantity,
        if (itemStatus != null) 'status': itemStatus,
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
