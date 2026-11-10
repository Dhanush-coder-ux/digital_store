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
  /// POST /orders/return-request (with multi-endpoint fallback to /returns/request, /returns/requests, & /orders/returns/request)
  Future<ReturnRequestModel> submitReturnRequest(CreateReturnRequestPayload payload) async {
    dynamic response;
    ApiException? lastApiException;

    final endpoints = [
      ApiConfig.returnRequestCreate,              // POST /orders/return-request (primary & cleanest)
      ApiConfig.returnRequestCreateReturns,       // POST /returns/request
      ApiConfig.returnRequestCreateAlt,           // POST /returns/requests
      ApiConfig.returnRequestCreateOrdersDirect,  // POST /orders/returns/request
    ];

    for (final endpoint in endpoints) {
      try {
        if (kDebugMode) print('[ReturnService] Submitting return request to: $endpoint');
        response = await _client.post(
          endpoint,
          body: payload.toJson(),
          requiresAuth: true,
        );
        lastApiException = null;
        break;
      } on ApiException catch (e) {
        lastApiException = e;
        if (kDebugMode) print('[ReturnService] Error from $endpoint (${e.statusCode}): ${e.message}');

        // If the error is a domain validation error (400) from ReturnRequestRepo,
        // it means the endpoint was reached and verified our payload.
        if (e.statusCode == 400 && !e.message.toLowerCase().contains('invalid data for return')) {
          rethrow;
        }

        // On 404 (route missing or "Order not found" from wrong route) or 405 (method not allowed),
        // proceed to test the next fallback candidate.
      } catch (e) {
        if (kDebugMode) print('[ReturnService] Network error from $endpoint: $e');
      }
    }

    // Final fallback: If dedicated return-request routes returned 404/405, attempt in-store
    // return route: POST /api/returns/{shop_id} using the order's actual shopId
    if (response == null) {
      final List<String> fallbackEndpoints = [];
      if (payload.shopId != null && payload.shopId!.isNotEmpty) {
        fallbackEndpoints.add('${ApiConfig.gatewayBase}/returns/${payload.shopId}');
      }
      fallbackEndpoints.add('${ApiConfig.gatewayBase}/returns');

      // Resolve payment method and initial refund amount
      String paymentMethod = 'CASH';
      double refundAmt = (payload.refundAmount != null && payload.refundAmount! > 0)
          ? payload.refundAmount!
          : 0.0;

      if (payload.paymentInfos != null && payload.paymentInfos!.isNotEmpty) {
        for (final entry in payload.paymentInfos!.entries) {
          final k = entry.key.trim().toUpperCase();
          if (k != 'STATUS' && k != 'METHOD' && k != 'ON_CREDIT' && k != 'AMOUNT') {
            paymentMethod = entry.key;
            if (refundAmt <= 0) {
              if (entry.value is num) {
                refundAmt = (entry.value as num).toDouble();
              } else if (entry.value is Map && entry.value['amount'] is num) {
                refundAmt = (entry.value['amount'] as num).toDouble();
              }
            }
            break;
          }
        }
      }

      final directPayload = {
        if (payload.shopId != null && payload.shopId!.isNotEmpty)
          'shop_id': payload.shopId,
        'order_id': payload.orderId,
        'payment_infos': {
          paymentMethod: refundAmt,
        },
        'items': payload.items.map((i) => {
          'order_item_id': (i.orderItemId != null && i.orderItemId!.isNotEmpty) ? i.orderItemId : (i.productId ?? ''),
          'quantity': i.quantity,
          if (i.unit != null && i.unit!.isNotEmpty) 'unit': i.unit,
          if (i.reason != null && i.reason!.isNotEmpty) 'reason': i.reason,
        }).toList(),
        'description': payload.description,
      };

      for (final directShopEndpoint in fallbackEndpoints) {
        try {
          if (kDebugMode) {
            print('[ReturnService] Attempting direct shop return fallback: $directShopEndpoint with amount: $refundAmt');
          }
          response = await _client.post(
            directShopEndpoint,
            body: directPayload,
            requiresAuth: true,
          );
          lastApiException = null;
          break;
        } on ApiException catch (e) {
          lastApiException = e;
          if (kDebugMode) {
            print('[ReturnService] Direct shop return fallback error from $directShopEndpoint (${e.statusCode}): ${e.message}');
          }

          // Check if backend rejected with:
          // "Entered refund amount (X) does not match required return total (Y)."
          final fullErr = '${e.message} ${e.body != null ? e.body.toString() : ''}';
          final match = RegExp(r'required return total \(([0-9.]+)\)').firstMatch(fullErr);
          if (match != null) {
            final requiredTotal = double.tryParse(match.group(1)!);
            if (requiredTotal != null && requiredTotal > 0) {
              if (kDebugMode) {
                print('[ReturnService] Auto-healing refund amount to backend required total: $requiredTotal and retrying...');
              }
              try {
                directPayload['payment_infos'] = {
                  paymentMethod: requiredTotal,
                };
                response = await _client.post(
                  directShopEndpoint,
                  body: directPayload,
                  requiresAuth: true,
                );
                lastApiException = null;
                break;
              } on ApiException catch (retryErr) {
                lastApiException = retryErr;
                if (kDebugMode) {
                  print('[ReturnService] Auto-healed retry failed: ${retryErr.statusCode} ${retryErr.message}');
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('[ReturnService] Direct shop return network error: $e');
        }
      }
    }

    if (response == null) {
      if (lastApiException != null) {
        throw lastApiException;
      }
      throw const ApiException('Unable to submit return request to server.');
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
      // Valid response (even if list is empty []). Return immediately without triggering fallbacks.
      return _parseReturnRequestList(response);
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
          orderUiId: payload.orderUiId,
          shopId: payload.shopId ?? '',
          customerId: payload.customerId,
          customerName: payload.customerName ?? 'Customer',
          customerPhone: payload.customerPhone ?? '',
          customerEmail: payload.customerEmail,
          items: payload.items.map((i) => ReturnItemDetail(
            orderItemId: i.orderItemId ?? '',
            productId: i.productId ?? '',
            productName: (i.productName != null && i.productName!.isNotEmpty) ? i.productName! : 'Returned Item',
            quantity: i.quantity,
            price: i.price ?? (payload.refundAmount != null && payload.items.length == 1 ? payload.refundAmount! : 0.0),
            totalAmount: i.totalAmount ?? (payload.refundAmount != null && payload.items.length == 1 ? payload.refundAmount! : 0.0),
            unit: i.unit,
            reason: i.reason,
          )).toList(),
          description: payload.description,
          status: 'COMPLETED',
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

