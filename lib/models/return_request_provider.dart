// lib/models/return_request_provider.dart
//
// State management provider for Customer Return Requests in digital_app.
//

import 'package:flutter/foundation.dart';
import '../services/return_service.dart';
import '../core/network/api_exceptions.dart';
import 'order_model.dart';
import 'return_request_model.dart';

class ReturnRequestProvider extends ChangeNotifier {
  final ReturnService _service;

  final Map<String, List<ReturnRequestModel>> _orderRequestsMap = {};
  List<ReturnRequestModel> _allUserRequests = [];
  ReturnRequestModel? _lastCreatedRequest;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _successMessage;

  ReturnRequestProvider(this._service);

  // ── Getters ──────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get successMessage => _successMessage;
  ReturnRequestModel? get lastCreatedRequest => _lastCreatedRequest;
  List<ReturnRequestModel> get allUserRequests => _allUserRequests;

  List<ReturnRequestModel> getRequestsForOrder(String orderId) {
    return _orderRequestsMap[orderId] ?? const [];
  }

  /// Returns true if the order already has an active return request (e.g. PENDING or ACCEPTED).
  bool hasActiveReturnRequest(String orderId) {
    final list = _orderRequestsMap[orderId];
    if (list == null || list.isEmpty) return false;
    return list.any((r) => r.isPending || r.isAccepted);
  }

  /// Returns the most recent return request for an order if any.
  ReturnRequestModel? getLatestRequestForOrder(String orderId) {
    final list = _orderRequestsMap[orderId];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Seeds return requests already embedded within an ApiOrder instance.
  void seedFromOrder(ApiOrder order) {
    final returns = order.returnRequests;
    if (returns == null || returns.isEmpty) return;
    try {
      final List<ReturnRequestModel> parsed = [];
      for (final item in returns) {
        if (item is Map<String, dynamic>) {
          final itemMap = Map<String, dynamic>.from(item);

          // Backfill orderId if missing or empty
          if ((itemMap['order_id'] == null || itemMap['order_id'].toString().trim().isEmpty) && order.id.isNotEmpty) {
            itemMap['order_id'] = order.id;
          }
          // Backfill orderUiId if missing or empty
          if (itemMap['order_ui_id'] == null || itemMap['order_ui_id'].toString().trim().isEmpty) {
            final ui = (order.uiId != null && order.uiId!.trim().isNotEmpty) ? order.uiId!.trim() : order.id;
            itemMap['order_ui_id'] = ui;
          }
          // Backfill shopId if missing
          if ((itemMap['shop_id'] == null || itemMap['shop_id'].toString().trim().isEmpty) && order.shopId.isNotEmpty) {
            itemMap['shop_id'] = order.shopId;
          }
          // Backfill customer details
          if ((itemMap['customer_name'] == null || itemMap['customer_name'].toString().trim().isEmpty) && order.customerName != null) {
            itemMap['customer_name'] = order.customerName;
          }
          if ((itemMap['customer_phone'] == null || itemMap['customer_phone'].toString().trim().isEmpty) && order.customerPhone != null) {
            itemMap['customer_phone'] = order.customerPhone;
          }
          // Backfill createdAt if missing
          if ((itemMap['created_at'] == null || itemMap['created_at'].toString().trim().isEmpty) && order.createdAt != null) {
            itemMap['created_at'] = order.createdAt;
          }

          var model = ReturnRequestModel.fromJson(itemMap);

          // If items inside model have 0 price / totalAmount, backfill from order items
          if (model.items.isNotEmpty && model.totalRefundAmount == 0 && order.items.isNotEmpty) {
            final updatedItems = model.items.map((retItem) {
              if (retItem.price == 0 && retItem.totalAmount == 0) {
                final match = order.items.cast<ApiOrderItem?>().firstWhere(
                  (oi) => (oi != null && oi.productId.isNotEmpty && oi.productId == retItem.productId) ||
                          (oi != null && oi.orderItemId != null && oi.orderItemId == retItem.orderItemId) ||
                          (oi != null && oi.productName != null && oi.productName!.toLowerCase() == retItem.productName.toLowerCase()),
                  orElse: () => null,
                );
                if (match != null) {
                  final price = match.unitPrice;
                  final total = price * retItem.quantity;
                  return ReturnItemDetail(
                    orderItemId: retItem.orderItemId.isNotEmpty ? retItem.orderItemId : (match.orderItemId ?? ''),
                    productId: retItem.productId.isNotEmpty ? retItem.productId : match.productId,
                    productName: retItem.productName != 'Item' ? retItem.productName : (match.productName ?? 'Item'),
                    variantName: retItem.variantName,
                    quantity: retItem.quantity,
                    price: price,
                    totalAmount: total,
                    unit: retItem.unit ?? match.unit,
                    reason: retItem.reason,
                  );
                }
              }
              return retItem;
            }).toList();
            model = model.copyWith(items: updatedItems);
          }

          parsed.add(model);
        }
      }
      if (parsed.isNotEmpty) {
        _orderRequestsMap[order.id] = parsed;
        for (final req in parsed) {
          final idx = _allUserRequests.indexWhere((r) => r.id == req.id);
          if (idx >= 0) {
            _allUserRequests[idx] = req;
          } else {
            _allUserRequests.add(req);
          }
        }
        _allUserRequests.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('[ReturnRequestProvider] seedFromOrder error: $e');
    }
  }

  /// Fetches return requests associated with a single order.
  /// Uses shopId and orderId to target the backend query.
  Future<List<ReturnRequestModel>> fetchRequestsForOrder(
    String orderId, {
    String? shopId,
    bool force = false,
  }) async {
    if (!force && _orderRequestsMap.containsKey(orderId)) {
      return _orderRequestsMap[orderId]!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.getReturnRequestsByOrder(orderId, shopId: shopId);
      if (list.isNotEmpty || !_orderRequestsMap.containsKey(orderId)) {
        _orderRequestsMap[orderId] = list;
      }

      // Also merge into allUserRequests
      for (final req in list) {
        final existingIndex = _allUserRequests.indexWhere((r) => r.id == req.id);
        if (existingIndex >= 0) {
          _allUserRequests[existingIndex] = req;
        } else {
          _allUserRequests.add(req);
        }
      }
      _allUserRequests.sort((a, b) {
        final aDate = a.createdAt ?? '';
        final bDate = b.createdAt ?? '';
        return bDate.compareTo(aDate);
      });

      return _orderRequestsMap[orderId] ?? list;
    } catch (e) {
      if (kDebugMode) print('[ReturnRequestProvider] fetchRequestsForOrder error: $e');
      return _orderRequestsMap[orderId] ?? [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ReturnRequestModel _enrichWithOrder(ReturnRequestModel req, ApiOrder orderObj) {
    var updated = req;
    if (updated.orderUiId == null || updated.orderUiId!.trim().isEmpty) {
      final ui = (orderObj.uiId != null && orderObj.uiId!.trim().isNotEmpty)
          ? orderObj.uiId!.trim()
          : orderObj.id;
      updated = updated.copyWith(orderUiId: ui);
    }
    if (updated.items.isNotEmpty && updated.totalRefundAmount == 0 && orderObj.items.isNotEmpty) {
      final updatedItems = updated.items.map((retItem) {
        if (retItem.price == 0 && retItem.totalAmount == 0) {
          final match = orderObj.items.cast<ApiOrderItem?>().firstWhere(
            (oi) => (oi != null && oi.productId.isNotEmpty && oi.productId == retItem.productId) ||
                    (oi != null && oi.orderItemId != null && oi.orderItemId == retItem.orderItemId) ||
                    (oi != null && oi.productName != null && oi.productName!.toLowerCase() == retItem.productName.toLowerCase()),
            orElse: () => null,
          );
          if (match != null) {
            final price = match.unitPrice;
            final total = price * retItem.quantity;
            return ReturnItemDetail(
              orderItemId: retItem.orderItemId.isNotEmpty ? retItem.orderItemId : (match.orderItemId ?? ''),
              productId: retItem.productId.isNotEmpty ? retItem.productId : match.productId,
              productName: retItem.productName != 'Item' ? retItem.productName : (match.productName ?? 'Item'),
              variantName: retItem.variantName,
              quantity: retItem.quantity,
              price: price,
              totalAmount: total,
              unit: retItem.unit ?? match.unit,
              reason: retItem.reason,
            );
          }
        }
        return retItem;
      }).toList();
      updated = updated.copyWith(items: updatedItems);
    }
    return updated;
  }

  /// Fetches return requests for an authenticated user (fast single-endpoint query,
  /// with parallel per-order fallback and order enrichment).
  Future<void> fetchUserReturnRequests(
    List<String> orderIds, {
    String? userId,
    List<ApiOrder>? orders,
    bool force = false,
  }) async {
    // First, seed from provided orders if available
    if (orders != null && orders.isNotEmpty) {
      for (final o in orders) {
        seedFromOrder(o);
      }
    }

    if ((userId == null || userId.trim().isEmpty) && orderIds.isEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, ApiOrder> orderLookup = {
        for (final o in (orders ?? const <ApiOrder>[])) o.id: o,
      };
      final List<ReturnRequestModel> combined = [];

      // 1. Fast path: single aggregated query by userId
      List<ReturnRequestModel>? directUserList;
      if (userId != null && userId.trim().isNotEmpty) {
        directUserList = await _service.getReturnRequestsByUser(userId.trim());
      }

      if (directUserList != null) {
        for (final req in directUserList) {
          final orderObj = orderLookup[req.orderId];
          final enriched = orderObj != null ? _enrichWithOrder(req, orderObj) : req;
          combined.add(enriched);
          final existingForOrder = _orderRequestsMap[req.orderId] ?? [];
          final idx = existingForOrder.indexWhere((r) => r.id == enriched.id);
          if (idx >= 0) {
            existingForOrder[idx] = enriched;
            _orderRequestsMap[req.orderId] = existingForOrder;
          } else {
            _orderRequestsMap[req.orderId] = [...existingForOrder, enriched];
          }
        }
      } else if (orderIds.isNotEmpty) {
        // 2. Fallback: parallel per-order requests
        final perOrderResults = await Future.wait(
          orderIds.map((orderId) async {
            final orderObj = orderLookup[orderId];
            final list = await _service.getReturnRequestsByOrder(
              orderId,
              shopId: orderObj?.shopId,
            );
            final enrichedList = list
                .map((req) => orderObj != null ? _enrichWithOrder(req, orderObj) : req)
                .toList();
            if (enrichedList.isNotEmpty || !_orderRequestsMap.containsKey(orderId)) {
              _orderRequestsMap[orderId] = enrichedList;
            }
            return enrichedList;
          }),
        );
        for (final list in perOrderResults) {
          combined.addAll(list);
        }
      } else {
        if (_allUserRequests.isEmpty) {
          _error = 'Failed to load return requests.';
        }
      }

      // Deduplicate by ID (prefer newly fetched records over older cache)
      final Map<String, ReturnRequestModel> dedup = {};
      for (final r in _allUserRequests) {
        dedup[r.id] = r;
      }
      for (final r in combined) {
        dedup[r.id] = r;
      }
      _allUserRequests = dedup.values.toList()
        ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    } catch (e) {
      if (kDebugMode) print('[ReturnRequestProvider] fetchUserReturnRequests error: $e');
      if (_allUserRequests.isEmpty) {
        _error = 'Failed to load return requests.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a return request to the backend.
  /// Handles duplicate check, loading, and error states.
  Future<ReturnRequestModel?> submitReturnRequest(
    CreateReturnRequestPayload payload,
  ) async {
    if (_isSubmitting) return null;

    // Check if duplicate active request exists
    if (hasActiveReturnRequest(payload.orderId)) {
      _error = 'An active return request already exists for this order.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _service.submitReturnRequest(payload);
      _lastCreatedRequest = result;
      _successMessage = 'Return request submitted successfully!';

      // Cache into local maps
      final list = _orderRequestsMap[payload.orderId] ?? [];
      _orderRequestsMap[payload.orderId] = [result, ...list];
      _allUserRequests.insert(0, result);

      return result;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to submit return request. Please check your connection and try again.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _orderRequestsMap.clear();
    _allUserRequests.clear();
    _lastCreatedRequest = null;
    _isLoading = false;
    _isSubmitting = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}

