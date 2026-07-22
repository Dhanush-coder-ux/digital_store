// lib/models/product_model.dart
//
// Product+Inventory model matching the Inventory Service response schema.
//

class ApiProduct {
  final String id;
  final String shopId;
  final String name;
  final String? description;
  final String? category;
  final double sellingPrice;
  final double? mrp;
  final double? costPrice;
  final String? unit;
  final List<String> imageUrls;
  final Map<String, dynamic>? typeInfos;     // has_variant, has_batch, has_serialno
  final Map<String, dynamic>? inventoryInfo; // quantity, reserved, available
  final List<Map<String, dynamic>> variants;
  final List<Map<String, dynamic>> batches;
  final bool isActive;
  final bool visibleOnline;
  final String? barcode;
  final String? sku;
  final Map<String, dynamic>? customFields;
  final String? createdAt;

  const ApiProduct({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    this.category,
    required this.sellingPrice,
    this.mrp,
    this.costPrice,
    this.unit,
    this.imageUrls = const [],
    this.typeInfos,
    this.inventoryInfo,
    this.variants = const [],
    this.batches = const [],
    this.isActive = true,
    this.visibleOnline = false,
    this.barcode,
    this.sku,
    this.customFields,
    this.createdAt,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    List<String> parseImageUrls(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    List<Map<String, dynamic>> parseListOfMaps(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    // The inventory service nests product info and inventory info separately
    // Handle both flat and nested structures
    final productData = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : json;
    final inventoryData = json['inventory'] is Map<String, dynamic>
        ? json['inventory'] as Map<String, dynamic>
        : null;

    // 1. Handle Variants Map or List
    List<Map<String, dynamic>> parsedVariants = [];
    if (productData['variants'] is Map) {
      final vMap = productData['variants'] as Map;
      parsedVariants = vMap.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (productData['variants'] is List) {
      parsedVariants = parseListOfMaps(productData['variants']);
    }

    // 2. Handle Batches
    List<Map<String, dynamic>> parsedBatches = parseListOfMaps(productData['batch_infos'] ?? productData['batches']);

    // 3. Extract Selling Price
    double extractedSellingPrice = parseDouble(productData['selling_price'] ?? productData['price']);
    double extractedQty = 0;

    final topPricing = productData['pricing_infos'] is Map ? productData['pricing_infos'] as Map : {};
    if (topPricing.containsKey('sell_price')) {
      extractedSellingPrice = parseDouble(topPricing['sell_price']);
    }

    final topStock = productData['stock_infos'] is Map ? productData['stock_infos'] as Map : {};
    if (topStock.containsKey('available_stocks')) {
      extractedQty = parseDouble(topStock['available_stocks']);
    }

    // If price/qty not found at top level, check batches
    if ((extractedSellingPrice == 0 || extractedQty == 0) && parsedBatches.isNotEmpty) {
      final b = parsedBatches.first;
      final bPricing = b['pricing_infos'] is Map ? b['pricing_infos'] as Map : {};
      final bStock = b['stock_infos'] is Map ? b['stock_infos'] as Map : {};
      if (extractedSellingPrice == 0 && bPricing.containsKey('sell_price')) {
        extractedSellingPrice = parseDouble(bPricing['sell_price']);
      }
      if (extractedQty == 0 && bStock.containsKey('available_stocks')) {
        extractedQty = parseDouble(bStock['available_stocks']);
      }
    }

    // If price/qty still not found, check variants
    if ((extractedSellingPrice == 0 || extractedQty == 0) && parsedVariants.isNotEmpty) {
      final v = parsedVariants.first;
      final vPricing = v['pricing_infos'] is Map ? v['pricing_infos'] as Map : {};
      final vStock = v['stock_infos'] is Map ? v['stock_infos'] as Map : {};
      if (extractedSellingPrice == 0 && vPricing.containsKey('sell_price')) {
        extractedSellingPrice = parseDouble(vPricing['sell_price']);
      }
      if (extractedQty == 0 && vStock.containsKey('available_stocks')) {
        extractedQty = parseDouble(vStock['available_stocks']);
      }
    }

    // 4. Extract Category and Unit names
    String? categoryName = productData['category']?.toString();
    if (productData['category_infos'] is Map && (productData['category_infos'] as Map).containsKey('name')) {
      categoryName = productData['category_infos']['name'];
    }

    String? unitName = productData['unit']?.toString();
    if (productData['unit_infos'] is Map && (productData['unit_infos'] as Map).containsKey('name')) {
      unitName = productData['unit_infos']['name'];
    }

    // 5. Build final map for inventory
    Map<String, dynamic> computedInventoryInfo = {'available': extractedQty};
    if (inventoryData != null) {
      computedInventoryInfo.addAll(inventoryData);
    } else if (json['inventory_info'] is Map) {
      computedInventoryInfo.addAll(json['inventory_info'] as Map<String, dynamic>);
    }
    if (computedInventoryInfo['available'] == null) {
      computedInventoryInfo['available'] = extractedQty;
    }

    return ApiProduct(
      id: productData['id']?.toString() ?? json['id']?.toString() ?? '',
      shopId: productData['shop_id']?.toString() ??
          json['shop_id']?.toString() ??
          '',
      name: productData['name']?.toString() ?? 'Unknown Product',
      description: productData['description']?.toString(),
      category: categoryName,
      sellingPrice: extractedSellingPrice,
      mrp: productData['mrp'] != null ? parseDouble(productData['mrp']) : null,
      costPrice: productData['cost_price'] != null
          ? parseDouble(productData['cost_price'])
          : null,
      unit: unitName,
      imageUrls: parseImageUrls(productData['image_url'] ?? productData['images']),
      typeInfos: productData['type_infos'] is Map
          ? Map<String, dynamic>.from(productData['type_infos'] as Map)
          : null,
      inventoryInfo: computedInventoryInfo,
      variants: parsedVariants,
      batches: parsedBatches,
      isActive: productData['is_active'] != false,
      visibleOnline: productData['visible_online'] == true,
      barcode: productData['barcode']?.toString(),
      sku: productData['sku']?.toString(),
      customFields: productData['custom_fields'] is Map
          ? Map<String, dynamic>.from(productData['custom_fields'] as Map)
          : null,
      createdAt: productData['created_at']?.toString(),
    );
  }

  /// Primary image URL or null
  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Has variant options
  bool get hasVariant => typeInfos?['has_variant'] == true;

  /// Has batch tracking
  bool get hasBatch => typeInfos?['has_batch'] == true;

  /// Has serial number tracking
  bool get hasSerialNo => typeInfos?['has_serialno'] == true;

  /// Available quantity from inventory
  double get availableQty {
    if (inventoryInfo == null) return 0;
    return double.tryParse(
            inventoryInfo!['available']?.toString() ??
            inventoryInfo!['quantity']?.toString() ?? '0') ??
        0;
  }

  /// Whether product is in stock
  bool get isInStock => availableQty > 0;

  /// Display price (selling price if available, else fallback to mrp)
  double get displayPrice => sellingPrice > 0 ? sellingPrice : (mrp ?? 0);

  /// Discount percentage
  double? get discountPercent {
    if (mrp == null || mrp == 0 || sellingPrice >= mrp!) return null;
    return ((mrp! - sellingPrice) / mrp! * 100);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'name': name,
        'description': description,
        'category': category,
        'selling_price': sellingPrice,
        'mrp': mrp,
        'unit': unit,
        'image_url': imageUrls,
        'type_infos': typeInfos,
        'is_active': isActive,
        'visible_online': visibleOnline,
        'barcode': barcode,
        'sku': sku,
      };
}
