// test/delivery_eligibility_test.dart
//
// Tests for Smart Delivery Information feature covering all 17 scenarios:
// 1. Standard Delivery enabled, customer within base distance.
// 2. Standard Delivery enabled, customer beyond base distance but within maximum radius.
// 3. Customer outside maximum delivery radius.
// 4. Flat-charge Standard Delivery.
// 5. Free delivery above configured order threshold.
// 6. Cart below minimum order amount.
// 7. Instant Delivery disabled.
// 8. Nationwide Delivery disabled.
// 9. Store Pickup enabled with configured pickup radius.
// 10. Missing customer address or coordinates.
// 11. Duplicate enabled delivery records for same shop and type.
// 12. Conflicting duplicate configurations.
// 13. API loading and failure fallback.
// 14. Customer changes delivery address.
// 15. Cart subtotal changes and delivery recalculation.
// 16. Multiple shops in cart / shop filtering.
// 17. Checkout payload and displayed delivery fee consistency.
//

import 'package:flutter_test/flutter_test.dart';
import 'package:digital_app/models/shop_model.dart';
import 'package:digital_app/services/delivery_eligibility_service.dart';

void main() {
  const service = DeliveryEligibilityService();

  group('Smart Delivery Information - Acceptance Scenarios', () {
    // ── Scenario 1: Standard Delivery within base distance ─────────────────
    test('Scenario 1: Standard Delivery within base distance charges base fee', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 1,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'extra_distance_step': 1.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      // Customer at 5 km (within 10 km base distance)
      final res5 = service.evaluateOptions(
        options: [option],
        customerDistance: 5.0,
        subtotal: 200.0,
      );
      expect(res5.first.isEligible, isTrue);
      expect(res5.first.calc!.fee, equals(100.0));

      // Customer at 10 km (exactly at base distance)
      final res10 = service.evaluateOptions(
        options: [option],
        customerDistance: 10.0,
        subtotal: 200.0,
      );
      expect(res10.first.isEligible, isTrue);
      expect(res10.first.calc!.fee, equals(100.0));
    });

    // ── Scenario 2: Beyond base distance but within maximum radius ─────────
    test('Scenario 2: Beyond base distance but within maximum radius adds extra charge', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 1,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'extra_distance_step': 1.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      // Customer at 11 km: 1 km extra -> 1 step -> 100 + 10 = 110
      final res11 = service.evaluateOptions(
        options: [option],
        customerDistance: 11.0,
        subtotal: 200.0,
      );
      expect(res11.first.isEligible, isTrue);
      expect(res11.first.calc!.fee, equals(110.0));

      // Customer at 12 km: 2 km extra -> 2 steps -> 100 + 20 = 120
      final res12 = service.evaluateOptions(
        options: [option],
        customerDistance: 12.0,
        subtotal: 200.0,
      );
      expect(res12.first.isEligible, isTrue);
      expect(res12.first.calc!.fee, equals(120.0));

      // Customer at 11.2 km: 1.2 km extra -> ceil(1.2/1.0) = 2 steps -> 120
      final res11_2 = service.evaluateOptions(
        options: [option],
        customerDistance: 11.2,
        subtotal: 200.0,
      );
      expect(res11_2.first.isEligible, isTrue);
      expect(res11_2.first.calc!.fee, equals(120.0));
    });

    // ── Scenario 3: Customer outside the maximum delivery radius ───────────
    test('Scenario 3: Customer outside maximum delivery radius is ineligible', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 1,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'extra_distance_step': 1.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      final res16 = service.evaluateOptions(
        options: [option],
        customerDistance: 16.0,
        subtotal: 200.0,
      );
      expect(res16.first.isEligible, isFalse);
      expect(res16.first.ineligibilityReason, contains('Outside delivery radius'));
    });

    // ── Scenario 4: Flat-charge Standard Delivery ───────────────────────────
    test('Scenario 4: Flat-charge Standard Delivery does not vary with distance within radius', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 2,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'FLAT',
        'delivery_charge': 80.0,
        'radius': 15.0,
        'speed': '2–3 Business Days',
        'enabled': true,
      });

      // At 5 km: flat 80
      final res5 = service.evaluateOptions(
        options: [option],
        customerDistance: 5.0,
        subtotal: 100.0,
      );
      expect(res5.first.isEligible, isTrue);
      expect(res5.first.calc!.fee, equals(80.0));

      // At 14 km: still flat 80
      final res14 = service.evaluateOptions(
        options: [option],
        customerDistance: 14.0,
        subtotal: 100.0,
      );
      expect(res14.first.isEligible, isTrue);
      expect(res14.first.calc!.fee, equals(80.0));

      // At 16 km: outside radius -> ineligible
      final res16 = service.evaluateOptions(
        options: [option],
        customerDistance: 16.0,
        subtotal: 100.0,
      );
      expect(res16.first.isEligible, isFalse);
    });

    // ── Scenario 5: Free delivery above configured threshold ───────────────
    test('Scenario 5: Free delivery applies when subtotal reaches free_shipping_amount', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 3,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'FLAT',
        'delivery_charge': 100.0,
        'free_shipping_amount': 500.0,
        'enabled': true,
      });

      // Subtotal 400: fee is 100
      final res400 = service.evaluateOptions(
        options: [option],
        customerDistance: 5.0,
        subtotal: 400.0,
      );
      expect(res400.first.calc!.fee, equals(100.0));
      expect(res400.first.calc!.isFree, isFalse);

      // Subtotal 500: fee is 0 (Free unlocked)
      final res500 = service.evaluateOptions(
        options: [option],
        customerDistance: 5.0,
        subtotal: 500.0,
      );
      expect(res500.first.calc!.fee, equals(0.0));
      expect(res500.first.calc!.isFree, isTrue);
      expect(res500.first.calc!.isFreeThresholdReached, isTrue);
    });

    // ── Scenario 6: Cart below minimum order amount ─────────────────────────
    test('Scenario 6: Cart below minimum order amount marks isMinOrderReached false', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 4,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'min_order_amount': 300.0,
        'delivery_charge': 50.0,
        'enabled': true,
      });

      final resBelow = service.evaluateOptions(
        options: [option],
        customerDistance: 3.0,
        subtotal: 150.0,
      );
      expect(resBelow.first.calc!.isMinOrderReached, isFalse);
      expect(resBelow.first.calc!.minOrderAmount, equals(300.0));

      final resAbove = service.evaluateOptions(
        options: [option],
        customerDistance: 3.0,
        subtotal: 350.0,
      );
      expect(resAbove.first.calc!.isMinOrderReached, isTrue);
    });

    // ── Scenario 7: Instant Delivery disabled ──────────────────────────────
    test('Scenario 7: Disabled Instant Delivery is filtered out by deduplicateOptions', () {
      final options = [
        ShopDeliveryOption.fromJson({
          'id': 10,
          'shop_id': 'shop-1',
          'type': 'INSTANT',
          'enabled': false,
        }),
        ShopDeliveryOption.fromJson({
          'id': 11,
          'shop_id': 'shop-1',
          'type': 'STANDARD',
          'enabled': true,
        }),
      ];

      final deduplicated = service.deduplicateOptions(options);
      expect(deduplicated.length, equals(1));
      expect(deduplicated.first.type, equals('STANDARD'));
    });

    // ── Scenario 8: Nationwide Delivery disabled vs enabled ────────────────
    test('Scenario 8: Nationwide delivery disabled is filtered; enabled has no local radius check', () {
      final disabled = ShopDeliveryOption.fromJson({
        'id': 20,
        'shop_id': 'shop-1',
        'type': 'NATIONWIDE',
        'enabled': false,
      });
      expect(service.deduplicateOptions([disabled]), isEmpty);

      final enabledNationwide = ShopDeliveryOption.fromJson({
        'id': 21,
        'shop_id': 'shop-1',
        'type': 'NATIONWIDE',
        'speed': '5–7 Business Days',
        'delivery_charge': 150.0,
        'radius': 0.0,
        'enabled': true,
      });
      // Even with 50 km distance, nationwide remains eligible
      final res = service.evaluateOptions(
        options: [enabledNationwide],
        customerDistance: 50.0,
      );
      expect(res.first.isEligible, isTrue);
      expect(res.first.calc!.fee, equals(150.0));
    });

    // ── Scenario 9: Store Pickup with configured pickup radius ─────────────
    test('Scenario 9: Store Pickup respects configured pickup radius', () {
      final pickup = ShopDeliveryOption.fromJson({
        'id': 30,
        'shop_id': 'shop-1',
        'type': 'PICKUP_ONLY',
        'radius': 5.0, // 5 km pickup limit
        'speed': 'Same Day',
        'enabled': true,
      });

      // Customer within 5 km
      final resWithin = service.evaluateOptions(
        options: [pickup],
        customerDistance: 3.5,
      );
      expect(resWithin.first.isEligible, isTrue);
      expect(resWithin.first.feeLabel, equals('Free'));

      // Customer beyond 5 km
      final resOutside = service.evaluateOptions(
        options: [pickup],
        customerDistance: 8.0,
      );
      expect(resOutside.first.isEligible, isFalse);
      expect(resOutside.first.ineligibilityReason, contains('Outside pickup radius'));
    });

    // ── Scenario 10: Missing customer address or coordinates ───────────────
    test('Scenario 10: Missing coordinates does not falsely claim distance fees', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 40,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      // When distance is null, evaluateOptions returns base fee without crash
      final res = service.evaluateOptions(
        options: [option],
        customerDistance: null,
      );
      expect(res.first.isEligible, isTrue);
      expect(res.first.customerDistance, isNull);
    });

    // ── Scenario 11: Duplicate enabled records for same shop and type ──────
    test('Scenario 11: Duplicate enabled records are deduplicated to single option', () {
      final duplicates = [
        ShopDeliveryOption.fromJson({
          'id': 81,
          'shop_id': 'shop-1',
          'type': 'INSTANT',
          'speed': 'Within 12 hours',
          'delivery_charge': 50.0,
          'enabled': true,
        }),
        ShopDeliveryOption.fromJson({
          'id': 82,
          'shop_id': 'shop-1',
          'type': 'INSTANT',
          'speed': 'Within 12 hours',
          'delivery_charge': 50.0,
          'enabled': true,
        }),
      ];

      final deduped = service.deduplicateOptions(duplicates);
      expect(deduped.length, equals(1));
    });

    // ── Scenario 12: Conflicting duplicate configurations ──────────────────
    test('Scenario 12: Conflicting duplicate records authoritatively select lower fee or higher id', () {
      final conflicting = [
        ShopDeliveryOption.fromJson({
          'id': 81,
          'shop_id': 'shop-1',
          'type': 'INSTANT',
          'delivery_charge': 50.0,
          'enabled': true,
        }),
        ShopDeliveryOption.fromJson({
          'id': 82,
          'shop_id': 'shop-1',
          'type': 'INSTANT',
          'delivery_charge': 0.0, // lower fee
          'enabled': true,
        }),
      ];

      final deduped = service.deduplicateOptions(conflicting);
      expect(deduped.length, equals(1));
      // Prefers lower delivery charge (0.0 over 50.0)
      expect(deduped.first.id, equals(82));
      expect(deduped.first.deliveryCharge, equals(0.0));
    });

    // ── Scenario 13: API loading and failure fallback ───────────────────────
    test('Scenario 13: Empty API options fallback to defaultStandard', () {
      final fallback = ShopDeliveryOption.defaultStandard(deliveryCharge: 40.0);
      expect(fallback.enabled, isTrue);
      expect(fallback.deliveryCharge, equals(40.0));
      expect(fallback.type, equals('STANDARD'));
    });

    // ── Scenario 14: Customer changes delivery address ─────────────────────
    test('Scenario 14: Address change dynamically re-evaluates fee and eligibility', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 1,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'extra_distance_step': 1.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      // Address A: 5 km away
      var res = service.evaluateOptions(options: [option], customerDistance: 5.0);
      expect(res.first.calc!.fee, equals(100.0));

      // Address changed to B: 12 km away
      res = service.evaluateOptions(options: [option], customerDistance: 12.0);
      expect(res.first.calc!.fee, equals(120.0));

      // Address changed to C: 20 km away (out of service)
      res = service.evaluateOptions(options: [option], customerDistance: 20.0);
      expect(res.first.isEligible, isFalse);
    });

    // ── Scenario 15: Cart subtotal changes recalculate fee ─────────────────
    test('Scenario 15: Subtotal change recalculates fee (free delivery threshold)', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 1,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'FLAT',
        'delivery_charge': 100.0,
        'free_shipping_amount': 500.0,
        'enabled': true,
      });

      // Initial cart: ₹300 -> fee ₹100
      var res = service.evaluateOptions(options: [option], subtotal: 300.0);
      expect(res.first.calc!.fee, equals(100.0));

      // Add item: cart becomes ₹550 -> fee drops to ₹0
      res = service.evaluateOptions(options: [option], subtotal: 550.0);
      expect(res.first.calc!.fee, equals(0.0));
      expect(res.first.calc!.isFree, isTrue);
    });

    // ── Scenario 16: Multiple shops filtering ──────────────────────────────
    test('Scenario 16: deduplicateOptions filters by targetShopId when provided', () {
      final mixed = [
        ShopDeliveryOption.fromJson({
          'id': 1,
          'shop_id': 'shop-A',
          'type': 'STANDARD',
          'delivery_charge': 40.0,
          'enabled': true,
        }),
        ShopDeliveryOption.fromJson({
          'id': 2,
          'shop_id': 'shop-B',
          'type': 'STANDARD',
          'delivery_charge': 60.0,
          'enabled': true,
        }),
      ];

      final shopAOptions = service.deduplicateOptions(mixed, targetShopId: 'shop-A');
      expect(shopAOptions.length, equals(1));
      expect(shopAOptions.first.deliveryCharge, equals(40.0));

      final shopBOptions = service.deduplicateOptions(mixed, targetShopId: 'shop-B');
      expect(shopBOptions.length, equals(1));
      expect(shopBOptions.first.deliveryCharge, equals(60.0));
    });

    // ── Scenario 17: Checkout payload matches displayed fee ────────────────
    test('Scenario 17: Checkout payload delivery_charge matches calculated fee', () {
      final option = ShopDeliveryOption.fromJson({
        'id': 99,
        'shop_id': 'shop-1',
        'type': 'STANDARD',
        'pricing_model': 'DISTANCE_BASED',
        'delivery_charge': 100.0,
        'base_distance': 10.0,
        'extra_distance_step': 1.0,
        'charge_per_km': 10.0,
        'radius': 15.0,
        'enabled': true,
      });

      final res = service.evaluateOptions(
        options: [option],
        customerDistance: 12.0,
      );
      final fee = res.first.calc!.fee; // 120.0
      final payload = option.toPayload(fee);

      expect(payload['delivery_charge'], equals(120.0));
      expect(payload['is_free'], isFalse);
      expect(payload['type'], equals('STANDARD'));
    });

    // ── Distance formatting helper test ────────────────────────────────────
    test('formatDistance helper formats km and meters cleanly', () {
      expect(DeliveryEligibilityService.formatDistance(0.5), equals('500 m away'));
      expect(DeliveryEligibilityService.formatDistance(2.0), equals('2 km away'));
      expect(DeliveryEligibilityService.formatDistance(2.5), equals('2.5 km away'));
    });

    // ── Haversine calculation test ─────────────────────────────────────────
    test('calculateDistanceKm computes accurate distance between coords', () {
      // Distance between Bangalore (12.9716, 77.5946) and Mysore (12.2958, 76.6394) is ~128 km
      final dist = service.calculateDistanceKm(12.9716, 77.5946, 12.2958, 76.6394);
      expect(dist, greaterThan(125.0));
      expect(dist, lessThan(135.0));
    });
  });
}

