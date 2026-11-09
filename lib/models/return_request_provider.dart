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
          parsed.add(ReturnRequestModel.fromJson(item));
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

  /// Fetches return requests for a batch of order IDs (e.g. all user orders).
  Future<void> fetchUserReturnRequests(
    List<String> orderIds, {
    List<ApiOrder>? orders,
    bool force = false,
  }) async {
    // First, seed from provided orders if available
    if (orders != null && orders.isNotEmpty) {
      for (final o in orders) {
        seedFromOrder(o);
      }
    }

    if (orderIds.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<ReturnRequestModel> combined = [];
      for (final orderId in orderIds) {
        // Find corresponding shop ID if available
        final orderObj = orders?.where((o) => o.id == orderId).firstOrNull;
        final list = await _service.getReturnRequestsByOrder(
          orderId,
          shopId: orderObj?.shopId,
        );
        if (list.isNotEmpty || !_orderRequestsMap.containsKey(orderId)) {
          _orderRequestsMap[orderId] = list;
        }
        combined.addAll(list);
      }

      // Deduplicate by ID
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

