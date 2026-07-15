// lib/services/order_service.dart
//
// HTTP layer for the Order Service — order placement.
// No authentication required — customer-facing anonymous orders.
//

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/order_model.dart';

class OrderService {
  const OrderService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Place Order ────────────────────────────────────────────────────

  /// Creates an order from the given cart session.
  /// Uses backend's CreateOrderSchema: shop_id, session_id, status, origin
  Future<ApiOrder> placeOrder(CreateOrderPayload payload) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.orderCreate),
          headers: _headers,
          body: jsonEncode(payload.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return _parseSingleOrder(body);
    } else {
      final body = _tryDecode(response.body);
      final detail = _extractDetail(body) ?? 'Failed to place order (${response.statusCode})';
      throw ApiException(detail);
    }
  }

  // ── Get Order ────────────────────────────────────────────────────────

  Future<ApiOrder?> getOrderById(String shopId, String orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.orderBase}/$shopId/$orderId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return _parseSingleOrder(body);
      }
    } catch (e) {
      // Ignored for refresh logic
    }
    return null;
  }

  Future<List<ApiOrder>> getOrdersByCustomer(String shopId, String customerId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.orderBase}/by/customer/$shopId/$customerId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List?;
        if (data != null) {
          return data.map((e) => ApiOrder.fromJson(e)).toList();
        }
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
    // Fallback — create a minimal order object so the success page can show
    return const ApiOrder(
      id: 'N/A',
      shopId: '',
      status: 'PENDING',
      totalAmount: 0,
    );
  }

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
