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
  Future<List<ApiProduct>> fetchProductsByShop(String shopId) async {
    try {
      final body = await _client.get(
        ApiConfig.productsByShop(shopId),
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
          .whereType<Map<String, dynamic>>()
          .map((e) => ApiProduct.fromJson(e))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['datas'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => ApiProduct.fromJson(e))
            .toList();
      }
      if (data is Map<String, dynamic>) return [ApiProduct.fromJson(data)];
    }
    return [];
  }

  ApiProduct _parseSingleProduct(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['datas'];
      if (data is Map<String, dynamic>) return ApiProduct.fromJson(data);
      return ApiProduct.fromJson(body);
    }
    throw Exception('Unexpected response format for product.');
  }
}
