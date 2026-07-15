// lib/services/product_service.dart
//
// HTTP layer for the Inventory Service — product endpoints.
//

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/product_model.dart';

class ProductService {
  const ProductService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Fetch Products By Shop ─────────────────────────────────────────

  /// Returns all products for the given [shopId].
  Future<List<ApiProduct>> fetchProductsByShop(String shopId) async {
    final uri = Uri.parse(ApiConfig.productsByShop(shopId));
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return _parseProductList(body);
    } else if (response.statusCode == 404) {
      return []; // No products yet — treat as empty
    } else {
      throw ApiException(
          'Failed to load products (${response.statusCode})');
    }
  }

  // ── Fetch Single Product ───────────────────────────────────────────

  Future<ApiProduct> fetchProductById(String shopId, String productId) async {
    final uri = Uri.parse(ApiConfig.productById(shopId, productId));
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return _parseSingleProduct(body);
    } else if (response.statusCode == 404) {
      throw ApiException('Product not found.');
    } else {
      throw ApiException(
          'Failed to load product (${response.statusCode})');
    }
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
      final data = body['data'];
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
      final data = body['data'];
      if (data is Map<String, dynamic>) return ApiProduct.fromJson(data);
      return ApiProduct.fromJson(body);
    }
    throw ApiException('Unexpected response format for product.');
  }
}
