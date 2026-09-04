// lib/services/cart_service.dart
//
// HTTP layer for the Order Service — cart endpoints.
// Uses ApiClient for standardized requests.
//

import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import 'api_config.dart';
import '../models/cart_session_model.dart';

class CartService {
  final ApiClient _client;

  const CartService(this._client);

  // ── Init Cart Session ──────────────────────────────────────────────

  /// Creates a new cart session in Redis. Returns the session_id.
  Future<String> initCart() async {
    final body = await _client.post(ApiConfig.dsCartInit, requiresAuth: true);
    
    if (body is Map<String, dynamic>) {
      if (body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String || (detail is Map && detail['success'] != true)) {
          final msg = detail is Map ? detail['msg'] ?? detail.toString() : detail.toString();
          throw ApiException(msg, statusCode: 400);
        }
      }
      final data = body['data'] ?? body;
      final sessionId = data['session_id']?.toString() ?? '';
      if (sessionId.isNotEmpty) {
        return sessionId;
      }
    }
    throw const ApiException('Cart session ID was empty in response.');
  }

  // ── Add Item to Cart ───────────────────────────────────────────────

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

    final body = await _client.post(ApiConfig.dsCartAdd, body: payload, requiresAuth: true);
    if (body is Map<String, dynamic> && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is String || (detail is Map && detail['success'] != true)) {
        final msg = detail is Map ? detail['msg'] ?? detail.toString() : detail.toString();
        throw ApiException(msg, statusCode: 400);
      }
    }
  }

  // ── Remove Item from Cart ──────────────────────────────────────────

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

    final body = await _client.post(ApiConfig.dsCartRemove, body: payload, requiresAuth: true);
    if (body is Map<String, dynamic> && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is String || (detail is Map && detail['success'] != true)) {
        final msg = detail is Map ? detail['msg'] ?? detail.toString() : detail.toString();
        throw ApiException(msg, statusCode: 400);
      }
    }
  }

  // ── Cancel Cart Session ────────────────────────────────────────────

  Future<void> cancelCart(String sessionId) async {
    final body = await _client.post(
      ApiConfig.dsCartCancel,
      body: {'session_id': sessionId},
      requiresAuth: true,
    );
    if (body is Map<String, dynamic> && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is String || (detail is Map && detail['success'] != true)) {
        final msg = detail is Map ? detail['msg'] ?? detail.toString() : detail.toString();
        throw ApiException(msg, statusCode: 400);
      }
    }
  }

  // ── Get Cart ───────────────────────────────────────────────────────

  Future<List<CartSessionItem>> getCart(String sessionId) async {
    final body = await _client.get(ApiConfig.dsCartGet(sessionId), requiresAuth: true);
    
    if (body is Map<String, dynamic>) {
      if (body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String || (detail is Map && detail['success'] != true)) {
          final msg = detail is Map ? detail['msg'] ?? detail.toString() : detail.toString();
          throw NotFoundException(msg);
        }
      }
      final data = body['data'] ?? body;
      final itemsRaw = data['items'] ?? data;
      if (itemsRaw is List) {
        return itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => CartSessionItem.fromJson(e))
            .toList();
      }
    }
    return [];
  }
}
