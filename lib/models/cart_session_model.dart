// lib/models/cart_session_model.dart
//
// Models for the backend cart session (Order Service, Redis-backed).
//

class CartSessionItem {
  final String productId;
  final String shopId;
  final String? variantId;
  final String? batchId;
  final List<Map<String, dynamic>>? serialnoInfos;
  final double qty;
  final String? unit;
  final Map<String, dynamic>? itemInfo; // enriched product info from inventory

  const CartSessionItem({
    required this.productId,
    required this.shopId,
    this.variantId,
    this.batchId,
    this.serialnoInfos,
    required this.qty,
    this.unit,
    this.itemInfo,
  });

  factory CartSessionItem.fromJson(Map<String, dynamic> json) {
    return CartSessionItem(
      productId: json['product_id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      batchId: json['batch_id']?.toString(),
      serialnoInfos: json['serialno_infos'] is List
          ? (json['serialno_infos'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString(),
      itemInfo: json['item_info'] is Map
          ? Map<String, dynamic>.from(json['item_info'] as Map)
          : null,
    );
  }

  /// Product name from enriched item info
  String get productName {
    final product = itemInfo?['product'];
    if (product is Map<String, dynamic>) {
      return product['name']?.toString() ?? 'Unknown Product';
    }
    return itemInfo?['name']?.toString() ?? 'Unknown Product';
  }

  /// Product image from enriched item info
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
        if (variants is Map && variants[variantId] is Map) {
          final vPricing = variants[variantId]['pricing_infos'];
          if (vPricing is Map && vPricing['sell_price'] != null) {
            return double.tryParse(vPricing['sell_price'].toString()) ?? 0;
          }
        } else if (variants is List) {
          final v = variants.firstWhere((e) => e is Map && e['id'] == variantId, orElse: () => null);
          if (v != null && v['pricing_infos'] is Map && v['pricing_infos']['sell_price'] != null) {
            return double.tryParse(v['pricing_infos']['sell_price'].toString()) ?? 0;
          }
        }
      }
      
      // If batch has price, use it
      if (batchId != null) {
        final batches = product['batch_infos'] ?? product['batches'];
        if (batches is List) {
          final b = batches.firstWhere((e) => e is Map && e['id'] == batchId, orElse: () => null);
          if (b != null && b['pricing_infos'] is Map && b['pricing_infos']['sell_price'] != null) {
            return double.tryParse(b['pricing_infos']['sell_price'].toString()) ?? 0;
          }
        }
      }
      // Base product price
      final basePricing = product['pricing_infos'];
      if (basePricing is Map && basePricing['sell_price'] != null) {
        return double.tryParse(basePricing['sell_price'].toString()) ?? 0;
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
        final v = variants.firstWhere((e) => e is Map && e['id'] == variantId, orElse: () => null);
        if (v != null) return v['name']?.toString();
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
        final b = batches.firstWhere((e) => e is Map && e['id'] == batchId, orElse: () => null);
        if (b != null) return b['name']?.toString();
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
