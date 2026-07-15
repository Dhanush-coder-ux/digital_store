// lib/services/api_config.dart
//
// Central configuration for all backend service base URLs.
// All requests go through the API Gateway at port 8900.
// For Android emulator use 10.0.2.2. For physical device use your machine's LAN IP.
// For emulator/web, 127.0.0.1 works if adb reverse is set up.
//
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseIp {
    // Hardcoding to your host's actual LAN IP so it works on your physical Android device over Wi-Fi
    return '10.167.188.101';
  }
  // static String get gatewayBase => 'http://$baseIp:8900/api';
  static String get gatewayBase => 'https://marketplace.debuggers.co.in/api';

  // ── ShopEmp endpoints ──────────────────────────────────────────────
  /// List all shops: GET /api/shops?q=&limit=&offset=
  static String get allShops => '$gatewayBase/shops';

  /// Get shop by ID: GET /api/shops/by/{shopId}
  static String shopById(String shopId) => '$gatewayBase/shops/by/$shopId';

  /// Get operating hours for a shop: GET /api/shops/{shopId}/operating-hours
  static String shopOperatingHours(String shopId) =>
      '$gatewayBase/shops/$shopId/operating-hours';

  /// Get delivery options for a shop: GET /api/shops/{shopId}/delivery
  static String shopDeliveryOptions(String shopId) =>
      '$gatewayBase/shops/$shopId/delivery';

  /// Get announcements for a shop: GET /api/shops/{shopId}/announcements
  static String shopAnnouncements(String shopId) =>
      '$gatewayBase/shops/$shopId/announcements';

  // ── Inventory / Products ───────────────────────────────────────────
  /// Get all products for a shop: GET /api/inventories/inventories/by/shop/{shopId}
  static String productsByShop(String shopId) =>
      '$gatewayBase/inventories/inventories/by/shop/$shopId';

  /// Get single product by ID: GET /api/inventories/inventories/by/id/{shopId}/{productId}
  static String productById(String shopId, String productId) =>
      '$gatewayBase/inventories/inventories/by/id/$shopId/$productId';

  // ── Cart endpoints (Order Service) ────────────────────────────────
  static String get cartBase => '$gatewayBase/cart';

  /// POST /api/cart/init — creates a new cart session, returns session_id
  static String get cartInit => '$cartBase/init';

  /// POST /api/cart/add — adds item to cart session
  static String get cartAdd => '$cartBase/add';

  /// POST /api/cart/remove — removes item from cart session
  static String get cartRemove => '$cartBase/remove';

  /// POST /api/cart/cancel — cancels entire cart session
  static String get cartCancel => '$cartBase/cancel';

  /// GET /api/cart/{sessionId} — fetches enriched cart items
  static String cartGet(String sessionId) => '$cartBase/$sessionId';

  // ── Order endpoints ────────────────────────────────────────────────
  static String get orderBase => '$gatewayBase/orders';

  // ── Customer endpoints ─────────────────────────────────────────────
  static String get customerBase => '$gatewayBase/customers';
  static String get customerCreate => customerBase;

  /// POST /api/orders — place a new order
  static String get orderCreate => orderBase;

  /// GET /api/orders/{shopId}/{customerId}/... (not used in customer flow directly)
  static String ordersByShop(String shopId) => '$orderBase/$shopId';
}
