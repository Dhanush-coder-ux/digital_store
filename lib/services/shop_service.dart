// lib/services/shop_service.dart
//
// HTTP layer for ShopEmp service — shops endpoints.
//

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/shop_model.dart';

class ShopService {
  const ShopService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Fetch My Shops ─────────────────────────────────────────────────

  /// Returns all shops
  Future<List<Shop>> fetchAllShops() async {
    final uri = Uri.parse(ApiConfig.allShops);

    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return _parseShopList(body);
    } else if (response.statusCode == 401) {
      throw AuthException('Session expired. Please log in again.');
    } else {
      throw ApiException(
          'Failed to load shops (${response.statusCode}): ${response.body}');
    }
  }

  // ── Fetch Shop By ID ───────────────────────────────────────────────

  Future<Shop> fetchShopById(String shopId) async {
    final uri = Uri.parse(ApiConfig.shopById(shopId));
    final response = await http.get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return _parseSingleShop(body);
    } else if (response.statusCode == 404) {
      throw ApiException('Shop not found.');
    } else {
      throw ApiException(
          'Failed to load shop (${response.statusCode})');
    }
  }

  // ── Parsers ────────────────────────────────────────────────────────

  List<Shop> _parseShopList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => Shop.fromJson(e))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Shop.fromJson(e))
            .toList();
      }
      if (data is Map<String, dynamic>) return [Shop.fromJson(data)];
      // Maybe the top-level map IS the shop
      if (body.containsKey('id')) return [Shop.fromJson(body)];
    }
    return [];
  }

  Shop _parseSingleShop(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return Shop.fromJson(data);
      return Shop.fromJson(body);
    }
    throw ApiException('Unexpected response format for shop.');
  }
}
