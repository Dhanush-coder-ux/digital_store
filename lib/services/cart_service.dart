// lib/services/cart_service.dart
//
// HTTP layer for the Order Service — cart endpoints.
// The backend cart is Redis-backed and tied to a session_id.
// No authentication required.
//

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/cart_session_model.dart';

class CartService {
  const CartService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Init Cart Session ──────────────────────────────────────────────

  /// Creates a new cart session in Redis. Returns the session_id.
  /// POST /api/cart/init → {detail: {...}, data: {session_id: "..."}}
  Future<String> initCart() async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.cartInit),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Response: {detail: {...}, data: {session_id: "..."}}
      final data = body['data'] ?? body;
      final sessionId = data['session_id']?.toString() ?? '';
      if (sessionId.isEmpty) {
        throw const ApiException('Cart session ID was empty in response.');
      }
      return sessionId;
    } else {
      throw ApiException(
          'Failed to initialize cart (${response.statusCode})');
    }
  }

  // ── Add Item to Cart ───────────────────────────────────────────────

  /// POST /api/cart/add
  /// Body: {session_id, shop_id, product_id, qty, variant_id?, batch_id?, unit?}
  Future<void> addItem({
    required String sessionId,
    required String shopId,
    required String productId,
    required double qty,
    String? variantId,
    String? batchId,
    String? unit,
  }) async {
    final payload = {
      'session_id': sessionId,
      'shop_id': shopId,
      'product_id': productId,
      'qty': qty,
      if (variantId != null) 'variant_id': variantId,
      if (batchId != null) 'batch_id': batchId,
      if (unit != null) 'unit': unit,
    };

    final response = await http
        .post(
          Uri.parse(ApiConfig.cartAdd),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = _tryDecode(response.body);
      final detail = _extractDetail(body) ?? 'Failed to add item to cart (${response.statusCode})';
      throw ApiException(detail);
    }
  }

  // ── Remove Item from Cart ──────────────────────────────────────────

  /// POST /api/cart/remove
  /// Body: {session_id, product_id, variant_id?, batch_id?}
  Future<void> removeItem({
    required String sessionId,
    required String productId,
    String? variantId,
    String? batchId,
  }) async {
    final payload = {
      'session_id': sessionId,
      'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      if (batchId != null) 'batch_id': batchId,
    };

    final response = await http
        .post(
          Uri.parse(ApiConfig.cartRemove),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to remove item from cart (${response.statusCode})');
    }
  }

  // ── Cancel Cart Session ────────────────────────────────────────────

  /// POST /api/cart/cancel
  /// Body: {session_id}
  Future<void> cancelCart(String sessionId) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.cartCancel),
          headers: _headers,
          body: jsonEncode({'session_id': sessionId}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw ApiException(
          'Failed to cancel cart (${response.statusCode})');
    }
  }

  // ── Get Cart ───────────────────────────────────────────────────────

  /// GET /api/cart/{session_id}
  /// Returns: {detail: {...}, data: {session_id, items: [enriched items]}}
  Future<List<CartSessionItem>> getCart(String sessionId) async {
    final uri = Uri.parse(ApiConfig.cartGet(sessionId));
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'] ?? body;
      final itemsRaw = data['items'] ?? data;
      if (itemsRaw is List) {
        return itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => CartSessionItem.fromJson(e))
            .toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      return []; // Cart expired or not found — treat as empty
    } else {
      throw ApiException(
          'Failed to load cart (${response.statusCode})');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _extractDetail(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is Map) return detail['msg']?.toString();
    }
    return null;
  }
}
