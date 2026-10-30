// lib/models/shop_model.dart
//
// Shop model matching the ShopEmp service response schema.
//

class Shop {
  final String id;
  final String name;
  final String? description;
  final String? tagline;
  final List<String> categories;
  final String? logoUrl;
  final String? bannerUrl;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? businessInfos;
  final Map<String, dynamic>? additionalInfos;
  final bool visibleOnline;
  final List<Map<String, dynamic>> operatingHours;
  final List<Map<String, dynamic>> deliveryOptions;
  final List<Map<String, dynamic>> announcements;
  final String? createdAt;
  final String? updatedAt;
  final double? distance;

  const Shop({
    required this.id,
    required this.name,
    this.description,
    this.tagline,
    required this.categories,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.businessInfos,
    this.additionalInfos,
    this.visibleOnline = false,
    this.operatingHours = const [],
    this.deliveryOptions = const [],
    this.announcements = const [],
    this.createdAt,
    this.updatedAt,
    this.distance,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    List<String> parseCategories(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    List<Map<String, dynamic>> parseListOfMaps(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      return [];
    }

    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Shop',
      description: json['description']?.toString(),
      tagline: json['tagline']?.toString(),
      categories: parseCategories(json['categories']),
      logoUrl: json['logo_url']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      address: json['address'] is Map<String, dynamic>
          ? json['address'] as Map<String, dynamic>
          : null,
      businessInfos: json['business_infos'] is Map<String, dynamic>
          ? json['business_infos'] as Map<String, dynamic>
          : null,
      additionalInfos: json['additional_infos'] is Map<String, dynamic>
          ? json['additional_infos'] as Map<String, dynamic>
          : null,
      visibleOnline: json['visible_online'] == true,
      operatingHours: parseListOfMaps(json['operating_hours']),
      deliveryOptions: parseListOfMaps(json['delivery_options']),
      announcements: parseListOfMaps(json['announcements']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : (json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null),
    );
  }

  /// Convenience getter: city from address map
  String get city {
    if (address == null) return '';
    return address!['city']?.toString() ??
        address!['area']?.toString() ??
        '';
  }

  /// Convenience getter: short display address
  String get displayAddress {
    if (address == null) return '';
    final parts = [
      address!['street']?.toString(),
      address!['area']?.toString(),
      address!['city']?.toString(),
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Convenience getter: Return Policy
  dynamic get returnPolicy {
    if (additionalInfos == null) return null;
    return additionalInfos!['return_policy'];
  }

  /// Convenience getter: Delivery Info Message
  String? get deliveryInfoMessage {
    if (additionalInfos == null) return null;
    return additionalInfos!['delivery_info_message']?.toString();
  }

  /// Whether there's a delivery option configured
  bool get hasDelivery => deliveryOptions.isNotEmpty;

  /// Parsed delivery options configured for this shop
  List<ShopDeliveryOption> get parsedDeliveryOptions {
    if (deliveryOptions.isEmpty) return [];
    return deliveryOptions
        .map((e) => ShopDeliveryOption.fromJson(e))
        .toList();
  }

  /// Minimum delivery charge (or 0)
  double get minDeliveryCharge {
    final opts = parsedDeliveryOptions.where((o) => o.enabled && !o.isPickup).toList();
    if (opts.isEmpty) return 0.0;
    double min = double.infinity;
    for (final opt in opts) {
      if (opt.deliveryCharge < min) min = opt.deliveryCharge;
    }
    return min == double.infinity ? 0.0 : min;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tagline': tagline,
        'categories': categories,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'address': address,
        'business_infos': businessInfos,
        'additional_infos': additionalInfos,
        'visible_online': visibleOnline,
        'operating_hours': operatingHours,
        'delivery_options': deliveryOptions,
        'announcements': announcements,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'distance': distance,
      };
}

/// Calculation outcome for an order's delivery fee
class DeliveryCalculationResult {
  final double fee;
  final bool isFree;
  final bool isFreeThresholdReached;
  final double freeThreshold;
  final double amountNeededForFree;
  final bool isMinOrderReached;
  final double minOrderAmount;
  final double? distance;
  final bool isDistanceBased;
  final double originalFee;
  final String description;

  const DeliveryCalculationResult({
    required this.fee,
    required this.isFree,
    this.isFreeThresholdReached = false,
    this.freeThreshold = 0.0,
    this.amountNeededForFree = 0.0,
    this.isMinOrderReached = true,
    this.minOrderAmount = 0.0,
    this.distance,
    this.isDistanceBased = false,
    this.originalFee = 0.0,
    required this.description,
  });
}

/// Rich delivery option model matching backend delivery configurations
class ShopDeliveryOption {
  final int? id;
  final String type;
  final String title;
  final String subtitle;
  final String speed;
  final String badge;
  final bool enabled;
  final String pricingModel; // 'FLAT' or 'DISTANCE_TIERED'
  final double deliveryCharge;
  final double chargePerKm;
  final double baseDistance;
  final double extraDistanceStep;
  final double freeShippingAmount;
  final double minOrderAmount;
  final double radius;
  final String deliveryBy;
  final Map<String, dynamic> raw;

  const ShopDeliveryOption({
    this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.speed,
    required this.badge,
    this.enabled = true,
    this.pricingModel = 'FLAT',
    this.deliveryCharge = 0.0,
    this.chargePerKm = 0.0,
    this.baseDistance = 0.0,
    this.extraDistanceStep = 1.0,
    this.freeShippingAmount = 0.0,
    this.minOrderAmount = 0.0,
    this.radius = 0.0,
    this.deliveryBy = 'PARTNERS',
    this.raw = const {},
  });

  bool get isPickup {
    final t = type.toUpperCase();
    return t.contains('PICKUP') || t == 'STORE_PICKUP' || t == 'PICKUP_ONLY';
  }

  bool get isInstant {
    final t = type.toUpperCase();
    return t.contains('INSTANT') || t.contains('EXPRESS');
  }

  bool get isNationwide {
    final t = type.toUpperCase();
    return t.contains('NATIONWIDE') || t.contains('SAME_DAY') || t.contains('SAMEDAY');
  }

  bool get isStandard {
    return !isPickup && !isInstant && !isNationwide;
  }

  bool get isDistanceTiered {
    final p = pricingModel.toUpperCase();
    return p == 'DISTANCE_TIERED' || p == 'DISTANCE' || p == 'DISTANCE_BASED';
  }

  DeliveryCalculationResult calculate({
    required double subtotal,
    double? distance,
  }) {
    if (isPickup) {
      return const DeliveryCalculationResult(
        fee: 0.0,
        isFree: true,
        originalFee: 0.0,
        description: 'Store Pickup — Collect in person for free',
      );
    }

    double computedFee = deliveryCharge;
    bool distanceApplied = false;

    if (isDistanceTiered) {
      distanceApplied = true;
      if (distance != null && distance > 0) {
        if (distance > baseDistance) {
          final double extraKm = distance - baseDistance;
          final double step = extraDistanceStep > 0 ? extraDistanceStep : 1.0;
          final int steps = (extraKm / step).ceil();
          final double extraCharge = steps * (chargePerKm > 0 ? chargePerKm : 0.0);
          computedFee = deliveryCharge + extraCharge;
        } else {
          computedFee = deliveryCharge;
        }
      } else {
        computedFee = deliveryCharge;
      }
    }

    final double original = computedFee;
    bool freeUnlocked = false;
    double neededForFree = 0.0;

    if (freeShippingAmount > 0) {
      if (subtotal >= freeShippingAmount) {
        freeUnlocked = true;
        computedFee = 0.0;
      } else {
        neededForFree = freeShippingAmount - subtotal;
      }
    }

    final bool isFree = computedFee <= 0;
    final bool minOrderOk = minOrderAmount <= 0 || subtotal >= minOrderAmount;

    String desc;
    if (freeUnlocked) {
      desc = 'Free delivery unlocked on orders ≥ ₹${freeShippingAmount.toStringAsFixed(0)}!';
    } else if (isDistanceTiered && distance != null && distance > 0) {
      if (distance > baseDistance) {
        desc = 'Base ₹${deliveryCharge.toStringAsFixed(0)} (first ${baseDistance.toStringAsFixed(0)} km) + ₹${(computedFee - deliveryCharge).toStringAsFixed(0)} for ${distance.toStringAsFixed(1)} km';
      } else {
        desc = 'Base rate ₹${deliveryCharge.toStringAsFixed(0)} (within ${baseDistance.toStringAsFixed(0)} km)';
      }
    } else if (isDistanceTiered) {
      desc = 'Base rate ₹${deliveryCharge.toStringAsFixed(0)} (distance-based)';
    } else {
      desc = computedFee > 0
          ? 'Flat delivery rate'
          : 'Free delivery on all orders';
    }

    return DeliveryCalculationResult(
      fee: computedFee,
      isFree: isFree,
      isFreeThresholdReached: freeUnlocked,
      freeThreshold: freeShippingAmount,
      amountNeededForFree: neededForFree,
      isMinOrderReached: minOrderOk,
      minOrderAmount: minOrderAmount,
      distance: distance,
      isDistanceBased: distanceApplied,
      originalFee: original,
      description: desc,
    );
  }

  factory ShopDeliveryOption.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final int? optId = json['id'] is int
        ? json['id'] as int
        : (json['id'] != null ? int.tryParse(json['id'].toString()) : null);

    final String rawType = (json['type'] ?? json['key'] ?? 'STANDARD').toString().toUpperCase();

    String title;
    String subtitle;
    String badge;
    String defaultSpeed;

    if (rawType.contains('PICKUP')) {
      title = json['title']?.toString() ?? 'Store Pickup';
      subtitle = json['subtitle']?.toString() ?? 'Pick up your items directly at the store';
      badge = 'Pickup';
      defaultSpeed = 'Same Day';
    } else if (rawType.contains('INSTANT') || rawType.contains('EXPRESS')) {
      title = json['title']?.toString() ?? 'Instant Delivery';
      subtitle = json['subtitle']?.toString() ?? 'Fast priority delivery for urgent orders';
      badge = 'Instant';
      defaultSpeed = 'Within 12 Hours';
    } else if (rawType.contains('NATIONWIDE') || rawType.contains('SAME_DAY') || rawType.contains('SAMEDAY')) {
      title = json['title']?.toString() ?? 'Nationwide Delivery';
      subtitle = json['subtitle']?.toString() ?? 'Delivered across the country with shipping partners';
      badge = 'Nationwide';
      defaultSpeed = '5–7 Business Days';
    } else {
      title = json['title']?.toString() ?? 'Standard Delivery';
      subtitle = json['subtitle']?.toString() ?? 'Standard door delivery for regular orders';
      badge = 'Standard';
      defaultSpeed = '2–3 Business Days';
    }

    final speed = (json['speed'] != null && json['speed'].toString().trim().isNotEmpty)
        ? json['speed'].toString().trim()
        : defaultSpeed;

    final charge = parseDouble(json['delivery_charge'] ?? json['deliveryCharge'] ?? json['charge'] ?? 0.0);
    final chargeKm = parseDouble(json['charge_per_km'] ?? json['chargePerKm'] ?? 0.0);
    final baseDist = parseDouble(json['base_distance'] ?? json['baseDistance'] ?? 0.0);
    final stepDist = parseDouble(json['extra_distance_step'] ?? json['extraDistanceStep'] ?? 1.0, 1.0);
    final freeThresh = parseDouble(json['free_shipping_amount'] ?? json['free_threshold'] ?? json['freeThreshold'] ?? 0.0);
    final minOrder = parseDouble(json['min_order_amount'] ?? json['minOrderAmount'] ?? 0.0);
    final radius = parseDouble(json['radius'] ?? 0.0);
    final model = (json['pricing_model'] ?? json['pricingModel'] ?? 'FLAT').toString().toUpperCase();
    final delBy = (json['delivery_by'] ?? json['deliveryBy'] ?? 'PARTNERS').toString().toUpperCase();
    final enabled = json['enabled'] != false;

    return ShopDeliveryOption(
      id: optId,
      type: rawType,
      title: title,
      subtitle: subtitle,
      speed: speed,
      badge: badge,
      enabled: enabled,
      pricingModel: model,
      deliveryCharge: charge,
      chargePerKm: chargeKm,
      baseDistance: baseDist,
      extraDistanceStep: stepDist > 0 ? stepDist : 1.0,
      freeShippingAmount: freeThresh,
      minOrderAmount: minOrder,
      radius: radius,
      deliveryBy: delBy,
      raw: json,
    );
  }

  factory ShopDeliveryOption.defaultStandard({double deliveryCharge = 40.0}) {
    return ShopDeliveryOption(
      type: 'STANDARD',
      title: 'Standard Delivery',
      subtitle: 'Standard door delivery',
      speed: '2–3 Business Days',
      badge: 'Standard',
      enabled: true,
      pricingModel: 'FLAT',
      deliveryCharge: deliveryCharge,
      chargePerKm: 0.0,
      baseDistance: 0.0,
      extraDistanceStep: 1.0,
      freeShippingAmount: 0.0,
      minOrderAmount: 0.0,
      radius: 0.0,
      deliveryBy: 'PARTNERS',
      raw: const {},
    );
  }

  Map<String, dynamic> toPayload(double finalFee) => {
    if (id != null) 'id': id,
    'type': type,
    'title': title,
    'speed': speed,
    'pricing_model': pricingModel,
    'delivery_charge': finalFee,
    'is_free': finalFee <= 0,
    'delivery_by': deliveryBy,
  };
}
