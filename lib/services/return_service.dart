// lib/services/return_service.dart
//
// HTTP service layer for Customer Return Requests interacting with Hyperlocal-Order-Service.
//

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import 'api_config.dart';
import '../models/return_request_model.dart';

class ReturnService {
  final ApiClient _client;

  const ReturnService(this._client);

  /// Submits a new customer return request.
  /// POST /returns/request (with fallback to /returns/requests & /orders/return-request)
  Future<ReturnRequestModel> submitReturnRequest(CreateReturnRequestPayload payload) async {
    dynamic response;
    try {
      response = await _client.post(
        ApiConfig.returnRequestCreate,
        body: payload.toJson(),
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (kDebugMode) print('[ReturnService] returnRequestCreate error: ${e.statusCode} ${e.message}');
      final isRouteMissing = (e.statusCode == 404 && e.message.trim().toLowerCase() == 'not found') ||
          e.statusCode == 405;
      if (isRouteMissing) {
        try {
          response = await _client.post(
            ApiConfig.returnRequestCreateAlt,
            body: payload.toJson(),
            requiresAuth: true,
          );
        } catch (_) {
          response = await _client.post(
            ApiConfig.returnRequestCreateOrders,
            body: payload.toJson(),
            requiresAuth: true,
          );
        }
      } else {
        rethrow;
      }
    }

    return _parseReturnRequest(response, payload);
  }

  /// Fetches return requests for a specific order.
  /// Primary path: GET /orders/return-requests/{shop_id}?order_id={order_id}
  /// Fallback path: GET /returns/requests/order/{order_id}
  Future<List<ReturnRequestModel>> getReturnRequestsByOrder(
    String orderId, {
    String? shopId,
  }) async {
    // 1. Primary path: query via orders router: GET /orders/return-requests/{shop_id}?order_id={order_id}
    try {
      final sId = (shopId != null && shopId.isNotEmpty) ? shopId : 'ALL';
      final response = await _client.get(
        ApiConfig.returnRequestsByOrder(orderId, shopId: sId),
        requiresAuth: true,
      );
      final list = _parseReturnRequestList(response);
      if (list.isNotEmpty) return list;
    } catch (e) {
      if (kDebugMode) print('[ReturnService] getReturnRequestsByOrder primary route: $e');
    }

    // 2. Fallback path: query via direct returns router: GET /returns/requests/order/{order_id}
    try {
      final response = await _client.get(
        ApiConfig.returnRequestsByOrderDirect(orderId),
        requiresAuth: true,
      );
      return _parseReturnRequestList(response);
    } catch (e) {
      if (kDebugMode) print('[ReturnService] getReturnRequestsByOrder direct fallback: $e');
      return [];
    }
  }

  /// Fetches a specific return request by ID.
  /// GET /returns/requests/detail/{request_id} with shop-list fallback.
  Future<ReturnRequestModel?> getReturnRequestById(
    String requestId, {
    String? shopId,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.returnRequestDetail(requestId),
        requiresAuth: true,
      );
      return _parseReturnRequest(response);
    } catch (_) {}

    // Fallback: search shop requests
    try {
      final sId = (shopId != null && shopId.isNotEmpty) ? shopId : 'ALL';
      final list = await getReturnRequestsByShop(sId, limit: 100);
      for (final req in list) {
        if (req.id == requestId) return req;
      }
    } catch (_) {}

    return null;
  }

  /// Fetches return requests for a shop.
  /// GET /orders/return-requests/{shop_id}
  Future<List<ReturnRequestModel>> getReturnRequestsByShop(
    String shopId, {
    String? status,
    String? orderId,
    int limit = 50,
    int offset = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (orderId != null && orderId.isNotEmpty) queryParams['order_id'] = orderId;

      final response = await _client.get(
        ApiConfig.returnRequestsByShop(shopId),
        queryParams: queryParams,
        requiresAuth: true,
      );
      return _parseReturnRequestList(response);
    } catch (e) {
      if (kDebugMode) print('[ReturnService] getReturnRequestsByShop error: $e');
      return [];
    }
  }

  // ── Helper Parsers ──────────────────────────────────────────────────

  ReturnRequestModel _parseReturnRequest(dynamic body, [CreateReturnRequestPayload? payload]) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return ReturnRequestModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      if (body['data'] == true && payload != null) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        return ReturnRequestModel(
          id: 'ret-${DateTime.now().millisecondsSinceEpoch}',
          orderId: payload.orderId,
          shopId: payload.shopId ?? '',
          customerId: payload.customerId,
          customerName: payload.customerName ?? 'Customer',
          customerPhone: payload.customerPhone ?? '',
          customerEmail: payload.customerEmail,
          items: payload.items.map((i) => ReturnItemDetail(
            orderItemId: i.orderItemId ?? '',
            productId: i.productId ?? '',
            productName: 'Returned Item',
            quantity: i.quantity,
            price: 0,
            totalAmount: 0,
            unit: i.unit,
            reason: i.reason,
          )).toList(),
          description: payload.description,
          status: 'PENDING',
          adminNotes: body['detail'] is Map ? body['detail']['msg']?.toString() : null,
          createdAt: nowIso,
          updatedAt: nowIso,
        );
      }
      return ReturnRequestModel.fromJson(body);
    }
    throw const ApiException('Invalid return request response from server');
  }

  List<ReturnRequestModel> _parseReturnRequestList(dynamic body) {
    dynamic listData = body;
    if (body is Map<String, dynamic>) {
      listData = body['data'] ?? body['datas'] ?? body['items'] ?? [];
    }
    if (listData is List) {
      return listData
          .whereType<Map<String, dynamic>>()
          .map((e) => ReturnRequestModel.fromJson(e))
          .toList();
    }
    return [];
  }
}

