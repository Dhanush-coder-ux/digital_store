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
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
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

  /// Whether there's a delivery option configured
  bool get hasDelivery => deliveryOptions.isNotEmpty;

  /// Minimum delivery charge (or 0)
  double get minDeliveryCharge {
    if (deliveryOptions.isEmpty) return 0;
    double min = double.infinity;
    for (final opt in deliveryOptions) {
      final charge = double.tryParse(opt['charge']?.toString() ?? '') ?? 0;
      if (charge < min) min = charge;
    }
    return min == double.infinity ? 0 : min;
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
