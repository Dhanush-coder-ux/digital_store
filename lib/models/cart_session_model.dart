// lib/models/cart_session_model.dart
//
// CartSessionItem model matching the Cart Service response schema.
//

class CartSessionItem {
  final String productId;
  final String shopId;
  final String? variantId;
  final String? batchId;
  final List<Map<String, dynamic>>? serialnoInfos;
  final double qty;
  final String? unit;
  final Map<String, dynamic>? itemInfo;

  const CartSessionItem({
    required this.productId,
    required this.shopId,
    this.variantId,
    this.batchId,
    this.serialnoInfos,
    this.qty = 1,
    this.unit,
    this.itemInfo,
  });

  factory CartSessionItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 1.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 1.0;
    }

    return CartSessionItem(
      productId: json['product_id']?.toString() ?? json['product']?['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? json['product']?['shop_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      batchId: json['batch_id']?.toString(),
      serialnoInfos: json['serialno_infos'] is List
          ? (json['serialno_infos'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : null,
      qty: parseDouble(json['qty'] ?? json['quantity']),
      unit: json['unit']?.toString(),
      itemInfo: json['item_info'] is Map<String, dynamic>
          ? json['item_info'] as Map<String, dynamic>
          : json['product'] is Map<String, dynamic>
              ? json['product'] as Map<String, dynamic>
              : null,
    );
  }

  /// Product name from enriched item info
  String get productName {
    final product = itemInfo?['product'] ?? itemInfo;
    if (product is Map && product['name'] != null) {
      return product['name'].toString();
    }
    return 'Product';
  }

  /// Product image URL from enriched item info
  String? get productImage {
    final product = itemInfo?['product'] ?? itemInfo;
    if (product is Map) {
      final imgs = product['image_url'];
      if (imgs is List && imgs.isNotEmpty) return imgs.first.toString();
    }
    return null;
  }

  /// Selling price from enriched item info
  double get sellingPrice {
    final product = itemInfo?['product'] ?? itemInfo;
    if (product is Map) {
      // If variant has price, use it
      if (variantId != null) {
        final variants = product['variants'];
        Map? vMap;
        if (variants is Map && variants[variantId] is Map) {
          vMap = variants[variantId] as Map;
        } else if (variants is List) {
          for (final e in variants) {
            if (e is Map && e['id']?.toString() == variantId) {
              vMap = e;
              break;
            }
          }
        }
        if (vMap != null) {
          final vPricing = vMap['pricing_infos'];
          if (vPricing is Map) {
            final p = vPricing['online_sell_price'] ?? vPricing['sell_price'];
            if (p != null && (double.tryParse(p.toString()) ?? 0) > 0) {
              return double.tryParse(p.toString()) ?? 0;
            }
          }
          if (vMap['batch_infos'] is List && (vMap['batch_infos'] as List).isNotEmpty) {
            for (final b in (vMap['batch_infos'] as List)) {
              if (b is Map && b['pricing_infos'] is Map) {
                final bp = b['pricing_infos'] as Map;
                final p = bp['online_sell_price'] ?? bp['sell_price'];
                if (p != null && (double.tryParse(p.toString()) ?? 0) > 0) {
                  return double.tryParse(p.toString()) ?? 0;
                }
              }
            }
          }
        }
      }
      
      // If batch has price, use it
      if (batchId != null) {
        final batches = product['batch_infos'] ?? product['batches'];
        if (batches is List) {
          for (final b in batches) {
            if (b is Map && b['id']?.toString() == batchId) {
              if (b['pricing_infos'] is Map) {
                final bp = b['pricing_infos'] as Map;
                final p = bp['online_sell_price'] ?? bp['sell_price'];
                if (p != null && (double.tryParse(p.toString()) ?? 0) > 0) {
                  return double.tryParse(p.toString()) ?? 0;
                }
              }
            }
          }
        }
      }
      // Base product price
      final basePricing = product['pricing_infos'];
      if (basePricing is Map) {
        final p = basePricing['online_sell_price'] ?? basePricing['sell_price'];
        if (p != null && (double.tryParse(p.toString()) ?? 0) > 0) {
          return double.tryParse(p.toString()) ?? 0;
        }
      }
      return double.tryParse(product['selling_price']?.toString() ?? '0') ?? 0;
    }
    return 0;
  }

  /// Variant name
  String? get variantName {
    if (variantId == null) return null;
    final product = itemInfo?['product'] ?? itemInfo;
    if (product is Map) {
      final variants = product['variants'];
      if (variants is Map) {
        final v = variants[variantId];
        if (v is Map) return v['name']?.toString();
      } else if (variants is List) {
        for (final e in variants) {
          if (e is Map && e['id']?.toString() == variantId) {
            return e['name']?.toString();
          }
        }
      }
    }
    return null;
  }

  /// Batch name
  String? get batchName {
    if (batchId == null) return null;
    final product = itemInfo?['product'] ?? itemInfo;
    if (product is Map) {
      final batches = product['batch_infos'] ?? product['batches'];
      if (batches is List) {
        for (final b in batches) {
          if (b is Map && b['id']?.toString() == batchId) {
            return b['name']?.toString();
          }
        }
      }
    }
    return null;
  }

  /// Serial name
  String? get serialName {
    if (serialnoInfos != null && serialnoInfos!.isNotEmpty) {
      return serialnoInfos!
          .map((e) => e['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    return null;
  }

  /// Line total
  double get lineTotal => sellingPrice * qty;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'shop_id': shopId,
        'variant_id': variantId,
        'batch_id': batchId,
        'serialno_infos': serialnoInfos,
        'qty': qty,
        'unit': unit,
        'item_info': itemInfo,
      };
}
