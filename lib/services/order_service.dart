// lib/services/order_service.dart
//
// HTTP layer for the Order Service — order placement.
// Uses ApiClient for authenticated/standardized requests.
//

import '../core/network/api_client.dart';
import 'api_config.dart';
import '../models/order_model.dart';

class OrderService {
  final ApiClient _client;

  const OrderService(this._client);

  // ── Place Order ────────────────────────────────────────────────────

  /// Creates an order from the given cart session.
  /// Uses backend's CreateOrderSchema: shop_id, session_id, status, origin
  Future<ApiOrder> placeOrder(CreateOrderPayload payload) async {
    final body = await _client.post(
      ApiConfig.orderCreate,
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _parseSingleOrder(body);
  }

  // ── Get Order ────────────────────────────────────────────────────────

  Future<ApiOrder?> getOrderById(String shopId, String orderId) async {
    try {
      final body = await _client.get(
        '${ApiConfig.orderBase}/$shopId/$orderId',
        requiresAuth: true,
      );
      return _parseSingleOrder(body);
    } catch (e) {
      return null;
    }
  }

  Future<List<ApiOrder>> getOrdersByCustomer(String shopId, String customerId) async {
    try {
      final body = await _client.get(
        ApiConfig.dsOrdersByUser(customerId),
        requiresAuth: true,
      );
      final data = (body is Map) ? body['data'] : null;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map((e) => ApiOrder.fromJson(e)).toList();
      }
    } catch (e) {
      // Ignored
    }
    return [];
  }

  // ── Parsers ────────────────────────────────────────────────────────

  ApiOrder _parseSingleOrder(dynamic body) {
    if (body is Map<String, dynamic>) {
      // Try {data: {...}} wrapper
      final data = body['data'];
      if (data is Map<String, dynamic>) return ApiOrder.fromJson(data);
      // Top-level object
      if (body.containsKey('id') || body.containsKey('shop_id')) {
        return ApiOrder.fromJson(body);
      }
      // {detail: {status_code, success, msg}, data: {...}}
      final nested = body['detail'];
      if (nested is Map<String, dynamic> && body['data'] != null) {
        final d = body['data'];
        if (d is Map<String, dynamic>) return ApiOrder.fromJson(d);
      }
    }
    // Fallback
    return const ApiOrder(
      id: 'N/A',
      shopId: '',
      status: 'PENDING',
      totalAmount: 0,
    );
  }
}
