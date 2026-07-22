// lib/services/shop_service.dart
//
// HTTP layer for ShopEmp service — shops endpoints.
// Uses ApiClient for authenticated/standardized requests.
//

import '../core/network/api_client.dart';
import 'api_config.dart';
import '../models/shop_model.dart';

class ShopService {
  final ApiClient _client;

  const ShopService(this._client);

  // ── Fetch My Shops ─────────────────────────────────────────────────

  /// Returns all shops
  Future<List<Shop>> fetchAllShops() async {
    final body = await _client.get(ApiConfig.dsShops, requiresAuth: true);
    return _parseShopList(body);
  }

  // ── Fetch Shop By ID ───────────────────────────────────────────────

  Future<Shop> fetchShopById(String shopId) async {
    final body = await _client.get(ApiConfig.dsShopById(shopId), requiresAuth: true);
    return _parseSingleShop(body);
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
    throw Exception('Unexpected response format for shop.');
  }
}
