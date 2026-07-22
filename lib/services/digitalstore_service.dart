// lib/services/digitalstore_service.dart
//
// Complete service layer for all DigitalStore User API endpoints.
// Uses ApiClient for authenticated requests.
// Maps to OpenAPI DigiStore.json specification.
//

import '../core/network/api_client.dart';
import '../core/models/user_profile_model.dart';
import '../core/models/address_model.dart';
import '../core/models/search_history_model.dart';
import '../core/models/review_model.dart';
import '../core/models/user_order_model.dart';
import 'api_config.dart';

class DigitalStoreService {
  final ApiClient _client;

  const DigitalStoreService(this._client);

  // ═══════════════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/profile
  Future<Map<String, dynamic>> createProfile(UserProfile profile) async {
    final body = await _client.post(
      ApiConfig.profileCreate,
      body: profile.toJson(),
    );
    return body is Map<String, dynamic> ? body : {};
  }

  /// GET /digitalstore/users/profile/{user_id}
  Future<UserProfile> getProfile(String userId) async {
    final body = await _client.get(ApiConfig.profileGet(userId));
    if (body is Map<String, dynamic>) {
      return UserProfile.fromJson(body);
    }
    throw Exception('Invalid profile response');
  }

  /// PUT /digitalstore/users/profile/{user_id}
  Future<Map<String, dynamic>> updateProfile(
    String userId,
    UpdateUserProfile update,
  ) async {
    final body = await _client.put(
      ApiConfig.profileUpdate(userId),
      body: update.toJson(),
    );
    return body is Map<String, dynamic> ? body : {};
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADDRESS
  // ═══════════════════════════════════════════════════════════════════

  /// GET /digitalstore/users/{user_id}/address/{address_id}
  Future<AddressModel> getAddress(String userId, String addressId) async {
    final body = await _client.get(
      ApiConfig.userAddress(userId, addressId),
    );
    if (body is Map<String, dynamic>) {
      return AddressModel.fromJson(body);
    }
    throw Exception('Invalid address response');
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH HISTORY
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/search
  Future<void> addSearchHistory(String userId, String searchTerm) async {
    await _client.post(
      ApiConfig.searchHistoryAdd,
      body: {'user_id': userId, 'search_term': searchTerm},
    );
  }

  /// GET /digitalstore/users/search/{user_id}?limit=&offset=
  Future<List<SearchHistoryEntry>> getSearchHistory(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.searchHistoryGet(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => SearchHistoryEntry.fromJson(e))
          .toList();
    }
    return [];
  }

  /// DELETE /digitalstore/users/search/{user_id}
  Future<void> clearSearchHistory(String userId) async {
    await _client.delete(ApiConfig.searchHistoryClear(userId));
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITE PRODUCTS
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/favorites/product
  Future<void> favoriteProduct(String userId, String productId) async {
    await _client.post(
      ApiConfig.favoriteProductAdd,
      body: {'user_id': userId, 'product_id': productId},
    );
  }

  /// DELETE /digitalstore/users/favorites/product/{user_id}/{product_id}
  Future<void> unfavoriteProduct(String userId, String productId) async {
    await _client.delete(
      ApiConfig.favoriteProductRemove(userId, productId),
    );
  }

  /// GET /digitalstore/users/favorites/products/{user_id}?limit=&offset=
  /// Returns a list of product_id strings.
  Future<List<String>> getFavoriteProducts(
    String userId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.favoriteProductsGet(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════
  // FAVORITE SHOPS
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/favorites/shop
  Future<void> favoriteShop(String userId, String shopId) async {
    await _client.post(
      ApiConfig.favoriteShopAdd,
      body: {'user_id': userId, 'shop_id': shopId},
    );
  }

  /// DELETE /digitalstore/users/favorites/shop/{user_id}/{shop_id}
  Future<void> unfavoriteShop(String userId, String shopId) async {
    await _client.delete(
      ApiConfig.favoriteShopRemove(userId, shopId),
    );
  }

  /// GET /digitalstore/users/favorites/shops/{user_id}?limit=&offset=
  /// Returns a list of shop_id strings.
  Future<List<String>> getFavoriteShops(
    String userId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.favoriteShopsGet(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body.map((e) => e.toString()).toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/reviews
  Future<void> submitReview(ShopReview review) async {
    await _client.post(
      ApiConfig.reviewCreate,
      body: review.toJson(),
    );
  }

  /// GET /digitalstore/users/reviews/shop/{shop_id}?limit=&offset=
  Future<List<ShopReview>> getShopReviews(
    String shopId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.shopReviewsGet(shopId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => ShopReview.fromJson(e))
          .toList();
    }
    return [];
  }

  /// GET /digitalstore/users/reviews/user/{user_id}?limit=&offset=
  Future<List<ShopReview>> getUserReviews(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.userReviewsGet(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => ShopReview.fromJson(e))
          .toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════
  // USER ORDERS
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/users/orders
  Future<void> linkOrderPayment(UserOrderLink orderLink) async {
    await _client.post(
      ApiConfig.userOrderLink,
      body: orderLink.toJson(),
    );
  }

  /// GET /digitalstore/users/orders/{user_id}?limit=&offset=
  Future<List<UserOrderLink>> getUserOrders(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final body = await _client.get(
      ApiConfig.userOrdersGet(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => UserOrderLink.fromJson(e))
          .toList();
    }
    return [];
  }

  /// POST /digitalstore/users/orders/bulk  body: [order_id, ...]
  Future<List<UserOrderLink>> getBulkOrders(List<String> orderIds) async {
    final body = await _client.post(
      ApiConfig.userOrdersBulk,
      body: orderIds,
    );
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => UserOrderLink.fromJson(e))
          .toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════
  // AGGREGATED — SHOPS (via DigitalStore proxy)
  // ═══════════════════════════════════════════════════════════════════

  /// GET /digitalstore/shops?q=&limit=&offset=
  Future<dynamic> fetchShops({
    String query = '',
    int limit = 10,
    int offset = 1,
  }) async {
    return await _client.get(
      ApiConfig.dsShops,
      queryParams: {
        if (query.isNotEmpty) 'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// GET /digitalstore/shops/{shop_id}
  Future<dynamic> fetchShopById(String shopId) async {
    return await _client.get(ApiConfig.dsShopById(shopId));
  }

  // ═══════════════════════════════════════════════════════════════════
  // AGGREGATED — PRODUCTS (via DigitalStore proxy)
  // ═══════════════════════════════════════════════════════════════════

  /// GET /digitalstore/products?q=&limit=&offset=&shop_id=
  Future<dynamic> fetchProducts({
    String? shopId,
    String query = '',
    int limit = 10,
    int offset = 1,
  }) async {
    return await _client.get(
      ApiConfig.dsProducts,
      queryParams: {
        if (shopId != null && shopId.isNotEmpty) 'shop_id': shopId,
        if (query.isNotEmpty) 'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// GET /digitalstore/products/{shop_id}/{id}
  Future<dynamic> fetchProductById(String shopId, String id) async {
    return await _client.get(ApiConfig.dsProductById(shopId, id));
  }

  // ═══════════════════════════════════════════════════════════════════
  // AGGREGATED — ORDERS
  // ═══════════════════════════════════════════════════════════════════

  /// GET /digitalstore/orders/by/user/{user_id}?limit=&offset=
  Future<dynamic> fetchUserOrders(
    String userId, {
    int limit = 10,
    int offset = 1,
  }) async {
    return await _client.get(
      ApiConfig.dsOrdersByUser(userId),
      queryParams: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
  }

  /// GET /digitalstore/orders/{shop_id}/{id}
  Future<dynamic> fetchOrderById(String shopId, String id) async {
    return await _client.get(ApiConfig.dsOrderById(shopId, id));
  }

  // ═══════════════════════════════════════════════════════════════════
  // AGGREGATED — CART
  // ═══════════════════════════════════════════════════════════════════

  /// POST /digitalstore/cart/init
  Future<dynamic> initCart() async {
    return await _client.post(ApiConfig.dsCartInit);
  }

  /// POST /digitalstore/cart/add
  Future<dynamic> addCartItem(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.dsCartAdd, body: data);
  }

  /// POST /digitalstore/cart/remove
  Future<dynamic> removeCartItem(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.dsCartRemove, body: data);
  }

  /// POST /digitalstore/cart/cancel
  Future<dynamic> cancelCart(Map<String, dynamic> data) async {
    return await _client.post(ApiConfig.dsCartCancel, body: data);
  }

  /// GET /digitalstore/cart/{session_id}
  Future<dynamic> getCart(String sessionId) async {
    return await _client.get(ApiConfig.dsCartGet(sessionId));
  }
}
