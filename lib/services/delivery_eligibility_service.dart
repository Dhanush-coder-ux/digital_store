// lib/services/delivery_eligibility_service.dart
//
// Shared delivery eligibility and pricing service for Shop Detail and Cart pages.
// Evaluates enabled delivery options against customer distance and cart subtotal,
// returning rich eligibility results for customer-facing display.
//

import 'dart:math' as math;
import '../models/shop_model.dart';

/// Result of evaluating a single delivery option for a customer.
class DeliveryEligibilityResult {
  final ShopDeliveryOption option;
  final bool isEligible;
  final String? ineligibilityReason; // null if eligible
  final DeliveryCalculationResult? calc; // null if not eligible
  final double? customerDistance; // km

  const DeliveryEligibilityResult({
    required this.option,
    required this.isEligible,
    this.ineligibilityReason,
    this.calc,
    this.customerDistance,
  });

  /// Customer-facing delivery fee label (e.g. "FREE", "₹110", "₹0")
  String get feeLabel {
    if (option.isPickup) return 'Free';
    final c = calc;
    if (c == null) return '';
    return c.isFree ? 'FREE' : '₹${c.fee.toStringAsFixed(0)}';
  }

  /// Customer-facing delivery time/speed label
  String get speedLabel => option.speed.isNotEmpty ? option.speed : _defaultSpeed;

  String get _defaultSpeed {
    if (option.isPickup) return 'Same Day';
    if (option.isInstant) return 'Within 12 Hours';
    if (option.isNationwide) return '5–7 Business Days';
    return '2–3 Business Days';
  }

  /// Emoji icon for display
  String get emoji {
    if (option.isPickup) return '🏬';
    if (option.isInstant) return '⚡';
    if (option.isNationwide) return '🌐';
    return '🚚';
  }
}

class DeliveryEligibilityService {
  const DeliveryEligibilityService();

  // ── Deduplication ────────────────────────────────────────────────────

  /// Filter disabled options, filter by shopId if specified,
  /// then keep one record per delivery type.
  /// Tie-breaking: prefer lower delivery charge; if equal, prefer higher id (most recent).
  List<ShopDeliveryOption> deduplicateOptions(
    List<ShopDeliveryOption> options, {
    String? targetShopId,
  }) {
    final Map<String, ShopDeliveryOption> uniqueMap = {};
    for (final opt in options) {
      if (!opt.enabled) continue;
      // Filter by shop ID if available and specified
      final rawShopId = opt.raw['shop_id']?.toString() ?? opt.raw['shopId']?.toString();
      if (targetShopId != null &&
          targetShopId.isNotEmpty &&
          rawShopId != null &&
          rawShopId.isNotEmpty &&
          rawShopId != targetShopId) {
        continue;
      }
      final key = opt.type.toUpperCase();
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = opt;
      } else {
        final existing = uniqueMap[key]!;
        final newCharge = opt.deliveryCharge;
        final existCharge = existing.deliveryCharge;
        if (newCharge < existCharge ||
            (newCharge == existCharge && (opt.id ?? 0) > (existing.id ?? 0))) {
          uniqueMap[key] = opt;
        }
      }
    }
    return uniqueMap.values.toList();
  }

  // ── Distance Calculation ─────────────────────────────────────────────

  /// Haversine distance in kilometres between two coordinates.
  double calculateDistanceKm(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // ── Eligibility Evaluation ───────────────────────────────────────────

  /// Evaluate all deduplicated enabled options against the customer's situation.
  ///
  /// [options] can be raw or already deduplicated.
  /// [customerDistance] is the distance in km between customer and shop (null if unknown).
  /// [subtotal] is the current cart subtotal.
  List<DeliveryEligibilityResult> evaluateOptions({
    required List<ShopDeliveryOption> options,
    double? customerDistance,
    double subtotal = 0.0,
    bool alreadyDeduplicated = false,
    String? targetShopId,
  }) {
    final deduplicated = alreadyDeduplicated
        ? options
        : deduplicateOptions(options, targetShopId: targetShopId);

    return deduplicated.map((opt) {
      return _evaluateSingle(opt, customerDistance, subtotal);
    }).toList();
  }

  DeliveryEligibilityResult _evaluateSingle(
    ShopDeliveryOption opt,
    double? customerDistance,
    double subtotal,
  ) {
    // Pickup: check configured pickup radius if > 0
    if (opt.isPickup) {
      if (opt.radius > 0 && customerDistance != null && customerDistance > opt.radius) {
        return DeliveryEligibilityResult(
          option: opt,
          isEligible: false,
          ineligibilityReason:
              'Outside pickup radius (${opt.radius.toStringAsFixed(0)} km limit)',
          customerDistance: customerDistance,
          calc: const DeliveryCalculationResult(
            fee: 0.0,
            isFree: true,
            originalFee: 0.0,
            description: 'Store Pickup — Outside pickup radius',
          ),
        );
      }
      return DeliveryEligibilityResult(
        option: opt,
        isEligible: true,
        customerDistance: customerDistance,
        calc: const DeliveryCalculationResult(
          fee: 0.0,
          isFree: true,
          originalFee: 0.0,
          description: 'Store Pickup — Free',
        ),
      );
    }

    // Nationwide — always eligible if enabled, no local radius check
    if (opt.isNationwide) {
      final calc = opt.calculate(subtotal: subtotal, distance: customerDistance);
      return DeliveryEligibilityResult(
        option: opt,
        isEligible: true,
        customerDistance: customerDistance,
        calc: calc,
      );
    }

    // Standard / Instant: radius check (only if radius > 0 AND distance is known)
    // Note: radius == 0 means unlimited / no maximum radius configured
    if (opt.radius > 0 && customerDistance != null) {
      if (customerDistance > opt.radius) {
        return DeliveryEligibilityResult(
          option: opt,
          isEligible: false,
          ineligibilityReason:
              'Outside delivery radius (${opt.radius.toStringAsFixed(0)} km limit)',
          customerDistance: customerDistance,
        );
      }
    }

    final calc = opt.calculate(subtotal: subtotal, distance: customerDistance);

    return DeliveryEligibilityResult(
      option: opt,
      isEligible: true,
      customerDistance: customerDistance,
      calc: calc,
    );
  }

  // ── Display Helpers ──────────────────────────────────────────────────

  /// Format distance for display. E.g. "2.5 km away", "850 m away"
  static String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m away';
    }
    final rounded = double.parse(km.toStringAsFixed(1));
    if (rounded == rounded.truncateToDouble()) {
      return '${rounded.toInt()} km away';
    }
    return '$rounded km away';
  }

  /// Build a concise customer-facing delivery summary line for shop detail page.
  static String buildShopDetailSummary(DeliveryEligibilityResult result) {
    final opt = result.option;
    final calc = result.calc;
    final dist = result.customerDistance;

    if (opt.isPickup) {
      return 'Store pickup · ${result.speedLabel}';
    }

    if (opt.isNationwide) {
      return 'Nationwide shipping · ${result.speedLabel}';
    }

    final distStr = dist != null && dist > 0 ? ' · ${formatDistance(dist)}' : '';

    if (calc == null) return '${opt.title}$distStr';

    if (calc.isFree) {
      return 'Free delivery$distStr';
    }

    return '${result.feeLabel} delivery fee$distStr';
  }
}
