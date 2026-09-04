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

  /// Returns shops based on location using /digitalstore/shops
  Future<List<Shop>> fetchAllShops({double? lat, double? lng, String? deliveryType}) async {
    final latitude = lat ?? 0.0;
    final longitude = lng ?? 0.0;

    final queryParams = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    if (deliveryType != null) {
      queryParams['delivery_type'] = deliveryType;
    }

    final body = await _client.get(
      ApiConfig.dsShops,
      queryParams: queryParams,
      requiresAuth: true
    );
    return _parseShopList(body);
  }

  // ── Fetch Shop By ID ───────────────────────────────────────────────

  Future<Shop> fetchShopById(String shopId) async {
    final body = await _client.get(ApiConfig.dsShopById(shopId), requiresAuth: true);
    return _parseSingleShop(body);
  }

  // ── Announcements ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getShopAnnouncements(String shopId) async {
    final body = await _client.get(ApiConfig.shopAnnouncements(shopId), requiresAuth: true);
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  // ── Parsers ────────────────────────────────────────────────────────

  List<Shop> _parseShopList(dynamic body) {
    print('ShopService: parseShopList received body of type ${body.runtimeType}');
    if (body is Map<String, dynamic>) {
      print('ShopService: body keys = ${body.keys.toList()}');
    }
    if (body is List) {
      final parsedShops = body
          .whereType<Map<String, dynamic>>()
          .map((e) => Shop.fromJson(e))
          .toList();
          
      final Map<String, Shop> uniqueShops = {};
      for (var shop in parsedShops) {
        if (shop.id.isNotEmpty) {
          uniqueShops[shop.id] = shop;
        }
      }
      return uniqueShops.values.toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['datas'];
      if (data is List) {
        final parsedShops = data
            .whereType<Map<String, dynamic>>()
            .map((e) => Shop.fromJson(e))
            .toList();
            
        final Map<String, Shop> uniqueShops = {};
        for (var shop in parsedShops) {
          if (shop.id.isNotEmpty) {
            uniqueShops[shop.id] = shop;
          }
        }
        return uniqueShops.values.toList();
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
