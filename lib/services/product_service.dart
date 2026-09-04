// lib/services/product_service.dart
//
// HTTP layer for the Inventory Service — product endpoints.
// Uses ApiClient for authenticated/standardized requests.
//

import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import 'api_config.dart';
import '../models/product_model.dart';

class ProductService {
  final ApiClient _client;

  const ProductService(this._client);

  // ── Fetch Products By Shop ─────────────────────────────────────────

  /// Returns all products for the given [shopId].
  Future<List<ApiProduct>> fetchProductsByShop(
    String shopId, {
    String q = '',
    int limit = 100,
    int offset = 1,
  }) async {
    try {
      final body = await _client.get(
        ApiConfig.productsByShop(shopId),
        queryParams: {
          if (q.isNotEmpty) 'q': q,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        requiresAuth: true,
      );
      return _parseProductList(body);
    } on NotFoundException {
      return []; // No products yet — treat as empty
    }
  }

  // ── Fetch Single Product ───────────────────────────────────────────

  Future<ApiProduct> fetchProductById(String shopId, String productId) async {
    final body = await _client.get(
      ApiConfig.productById(shopId, productId),
      requiresAuth: true,
    );
    return _parseSingleProduct(body);
  }

  // ── Parsers ────────────────────────────────────────────────────────

  List<ApiProduct> _parseProductList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => ApiProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (body is Map) {
      final data = body['data'] ?? body['datas'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ApiProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map) return [ApiProduct.fromJson(Map<String, dynamic>.from(data))];
    }
    return [];
  }

  ApiProduct _parseSingleProduct(dynamic body) {
    if (body is Map) {
      final data = body['data'] ?? body['datas'];
      if (data is Map) return ApiProduct.fromJson(Map<String, dynamic>.from(data));
      return ApiProduct.fromJson(Map<String, dynamic>.from(body));
    }
    throw Exception('Unexpected response format for product.');
  }
}
