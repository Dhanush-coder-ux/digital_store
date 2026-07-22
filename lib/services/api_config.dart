// lib/services/api_config.dart
//
// Central configuration for all backend service base URLs.
// All requests go through the API Gateway.
//

class ApiConfig {
  static String get baseIp => '10.167.188.101';

  static String get gatewayBase => 'http://$baseIp:8000/api';
//   static String get gatewayBase => 'https://marketplace.debuggers.co.in/api';

  // ═══════════════════════════════════════════════════════════════════
  // AUTHENTICATION ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════

  /// GET /api/auth/login-url?service=&version=
  static String get authLoginUrl => '$gatewayBase/auth/login-url?entity_name=HYPERLOCAL&entity_type=app';

  /// GET /api/auth/callback?token_id=&service=&version=
  static String get authCallback => '$gatewayBase/auth/callback';

  /// POST /api/auth/refresh  body: {refresh_token, version}
  static String get authRefresh => '$gatewayBase/auth/refresh';

  /// POST /api/auth/revoke  body: {token}
  static String get authRevoke => '$gatewayBase/auth/revoke';

  // ═══════════════════════════════════════════════════════════════════
  // DIGITALSTORE USER ENDPOINTS (OpenAPI: DigiStore.json)
  // ═══════════════════════════════════════════════════════════════════

  static String get _dsBase => '$gatewayBase/digitalstore';

  // ── Profile ─────────────────────────────────────────────────────

  /// POST /api/digitalstore/users/profile
  static String get profileCreate => '$_dsBase/users/profile';

  /// GET /api/digitalstore/users/profile/{user_id}
  static String profileGet(String userId) => '$_dsBase/users/profile/$userId';

  /// PUT /api/digitalstore/users/profile/{user_id}
  static String profileUpdate(String userId) => '$_dsBase/users/profile/$userId';

  // ── Address ─────────────────────────────────────────────────────

  /// GET /api/digitalstore/users/{user_id}/address/{address_id}
  static String userAddress(String userId, String addressId) =>
      '$_dsBase/users/$userId/address/$addressId';

  // ── Search History ──────────────────────────────────────────────

  /// POST /api/digitalstore/users/search
  static String get searchHistoryAdd => '$_dsBase/users/search';

  /// GET /api/digitalstore/users/search/{user_id}?limit=&offset=
  static String searchHistoryGet(String userId) =>
      '$_dsBase/users/search/$userId';

  /// DELETE /api/digitalstore/users/search/{user_id}
  static String searchHistoryClear(String userId) =>
      '$_dsBase/users/search/$userId';

  // ── Favorite Products ───────────────────────────────────────────

  /// POST /api/digitalstore/users/favorites/product
  static String get favoriteProductAdd => '$_dsBase/users/favorites/product';

  /// DELETE /api/digitalstore/users/favorites/product/{user_id}/{product_id}
  static String favoriteProductRemove(String userId, String productId) =>
      '$_dsBase/users/favorites/product/$userId/$productId';

  /// GET /api/digitalstore/users/favorites/products/{user_id}?limit=&offset=
  static String favoriteProductsGet(String userId) =>
      '$_dsBase/users/favorites/products/$userId';

  // ── Favorite Shops ──────────────────────────────────────────────

  /// POST /api/digitalstore/users/favorites/shop
  static String get favoriteShopAdd => '$_dsBase/users/favorites/shop';

  /// DELETE /api/digitalstore/users/favorites/shop/{user_id}/{shop_id}
  static String favoriteShopRemove(String userId, String shopId) =>
      '$_dsBase/users/favorites/shop/$userId/$shopId';

  /// GET /api/digitalstore/users/favorites/shops/{user_id}?limit=&offset=
  static String favoriteShopsGet(String userId) =>
      '$_dsBase/users/favorites/shops/$userId';

  // ── Reviews ─────────────────────────────────────────────────────

  /// POST /api/digitalstore/users/reviews
  static String get reviewCreate => '$_dsBase/users/reviews';

  /// GET /api/digitalstore/users/reviews/shop/{shop_id}?limit=&offset=
  static String shopReviewsGet(String shopId) =>
      '$_dsBase/users/reviews/shop/$shopId';

  /// GET /api/digitalstore/users/reviews/user/{user_id}?limit=&offset=
  static String userReviewsGet(String userId) =>
      '$_dsBase/users/reviews/user/$userId';

  // ── User Orders (DigitalStore) ──────────────────────────────────

  /// POST /api/digitalstore/users/orders
  static String get userOrderLink => '$_dsBase/users/orders';

  /// GET /api/digitalstore/users/orders/{user_id}?limit=&offset=
  static String userOrdersGet(String userId) =>
      '$_dsBase/users/orders/$userId';

  /// POST /api/digitalstore/users/orders/bulk  body: [order_id, ...]
  static String get userOrdersBulk => '$_dsBase/users/orders/bulk';

  // ═══════════════════════════════════════════════════════════════════
  // DIGITALSTORE AGGREGATED ENDPOINTS (Shops, Products, Orders, Cart)
  // ═══════════════════════════════════════════════════════════════════

  // ── Shops (aggregated) ──────────────────────────────────────────

  /// GET /api/digitalstore/shops?q=&limit=&offset=
  static String get dsShops => '$_dsBase/shops';

  /// GET /api/digitalstore/shops/{shop_id}
  static String dsShopById(String shopId) => '$_dsBase/shops/$shopId';

  // ── Products (aggregated) ───────────────────────────────────────

  /// GET /api/digitalstore/products?q=&limit=&offset=
  static String get dsProducts => '$_dsBase/products';

  /// GET /api/digitalstore/products/{shop_id}/{id}
  static String dsProductById(String shopId, String id) =>
      '$_dsBase/products/$shopId/$id';

  // ── Orders (aggregated) ─────────────────────────────────────────

  /// GET /api/digitalstore/orders/by/user/{user_id}?limit=&offset=
  static String dsOrdersByUser(String userId) =>
      '$_dsBase/orders/by/user/$userId';

  /// GET /api/digitalstore/orders/{shop_id}/{id}
  static String dsOrderById(String shopId, String id) =>
      '$_dsBase/orders/$shopId/$id';

  // ── Cart (aggregated) ───────────────────────────────────────────

  /// POST /api/digitalstore/cart/init
  static String get dsCartInit => '$_dsBase/cart/init';

  /// POST /api/digitalstore/cart/add
  static String get dsCartAdd => '$_dsBase/cart/add';

  /// POST /api/digitalstore/cart/remove
  static String get dsCartRemove => '$_dsBase/cart/remove';

  /// POST /api/digitalstore/cart/cancel
  static String get dsCartCancel => '$_dsBase/cart/cancel';

  /// GET /api/digitalstore/cart/{session_id}
  static String dsCartGet(String sessionId) => '$_dsBase/cart/$sessionId';

  // ═══════════════════════════════════════════════════════════════════
  // DIRECT GATEWAY ENDPOINTS (existing, kept for backward compat)
  // ═══════════════════════════════════════════════════════════════════

  // ── ShopEmp endpoints ──────────────────────────────────────────
  static String get allShops => '$gatewayBase/shops';
  static String shopById(String shopId) => '$gatewayBase/shops/by/$shopId';
  static String shopOperatingHours(String shopId) =>
      '$gatewayBase/shops/$shopId/operating-hours';
  static String shopDeliveryOptions(String shopId) =>
      '$gatewayBase/shops/$shopId/delivery';
  static String shopAnnouncements(String shopId) =>
      '$gatewayBase/shops/$shopId/announcements';

  // ── Inventory / Products ───────────────────────────────────────
  static String productsByShop(String shopId) =>
      '$_dsBase/products/$shopId';
  static String productById(String shopId, String productId) =>
      '$_dsBase/products/$shopId/$productId';

  // ── Cart endpoints (Order Service) ────────────────────────────
  static String get cartBase => '$gatewayBase/cart';
  static String get cartInit => '$cartBase/init';
  static String get cartAdd => '$cartBase/add';
  static String get cartRemove => '$cartBase/remove';
  static String get cartCancel => '$cartBase/cancel';
  static String cartGet(String sessionId) => '$cartBase/$sessionId';

  // ── Order endpoints ────────────────────────────────────────────
  static String get orderBase => '$gatewayBase/orders';
  static String get orderCreate => orderBase;
  static String ordersByShop(String shopId) => '$orderBase/$shopId';

  // ── Customer endpoints ─────────────────────────────────────────
  static String get customerBase => '$gatewayBase/customers';
  static String get customerCreate => customerBase;
  static String customerByShop(String shopId) => '$customerBase/by/shop/$shopId';
}
