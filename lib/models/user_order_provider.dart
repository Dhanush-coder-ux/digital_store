// lib/models/user_order_provider.dart
//
// Dedicated provider for user order management.
// Links orders to users, fetches order history with full details,
// and supports pagination.
//

import 'package:flutter/foundation.dart';
import '../services/digitalstore_service.dart';
import '../core/models/user_order_model.dart';
import '../models/order_model.dart';

class UserOrderProvider extends ChangeNotifier {
  final DigitalStoreService _service;

  List<UserOrderLink> _userOrderLinks = [];
  List<ApiOrder> _orders = [];
  ApiOrder? _selectedOrder;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  bool _hasFetched = false;
  int _currentOffset = 0;
  bool _hasMore = true;

  UserOrderProvider(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  List<UserOrderLink> get userOrderLinks => _userOrderLinks;
  List<ApiOrder> get orders => _orders;
  ApiOrder? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  bool get hasFetched => _hasFetched;
  bool get hasMore => _hasMore;

  // ── Link Order to User ──────────────────────────────────────────

  /// Called after placing an order to link it to the user.
  Future<void> linkOrder({
    required String userId,
    required String orderId,
    PaymentInfo? paymentInfo,
  }) async {
    try {
      final link = UserOrderLink(
        userId: userId,
        orderId: orderId,
        paymentInfo: paymentInfo,
      );
      await _service.linkOrderPayment(link);
      _userOrderLinks.insert(0, link);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[UserOrderProvider] Failed to link order: $e');
      // Non-critical — order is placed, link can be retried
    }
  }

  // ── Fetch User Order Links ──────────────────────────────────────

  Future<void> fetchUserOrders(
    String userId, {
    bool force = false,
    int limit = 10,
  }) async {
    if (_hasFetched && !force && _error == null) return;

    _isLoading = true;
    _error = null;
    _currentOffset = 1; // Used as page number
    notifyListeners();

    try {
      final body = await _service.fetchUserOrders(
        userId, limit: limit, offset: _currentOffset,
      );
      _orders = _parseOrderList(body);
      
      _hasMore = _orders.length >= limit;
      _currentOffset++;
      _hasFetched = true;
    } catch (e) {
      _error = 'Failed to load orders.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Load More (Pagination) ──────────────────────────────────────

  Future<void> loadMore(String userId, {int limit = 10}) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final body = await _service.fetchUserOrders(
        userId, limit: limit, offset: _currentOffset,
      );
      final more = _parseOrderList(body);
      
      _orders.addAll(more);
      _hasMore = more.length >= limit;
      _currentOffset++;
    } catch (e) {
      _error = 'Failed to load more orders.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Full Order Detail ─────────────────────────────────────

  Future<void> fetchOrderDetail(String shopId, String orderId) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final body = await _service.fetchOrderById(shopId, orderId);
      if (body is Map<String, dynamic>) {
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic>) {
          _selectedOrder = ApiOrder.fromJson(data);
        }
      }
    } catch (e) {
      _error = 'Failed to load order detail.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── Internal: Fetch Order Details ───────────────────────────────

  Future<void> _fetchOrderDetails() async {
    if (_userOrderLinks.isEmpty) return;

    final orderIds = _userOrderLinks.map((l) => l.orderId).toList();
    try {
      final body = await _service.fetchUserOrders(
        _userOrderLinks.first.userId,
        limit: orderIds.length,
        offset: 1,
      );
      _orders = _parseOrderList(body);
    } catch (e) {
      // Fallback: show order links without full details
      _orders = [];
    }
  }

  Future<void> _fetchOrderDetailsForLinks(List<UserOrderLink> links) async {
    // For now, refresh all — could be optimized with bulk endpoint
    if (links.isNotEmpty) {
      try {
        final body = await _service.fetchUserOrders(
          links.first.userId,
          limit: _userOrderLinks.length,
          offset: 1,
        );
        _orders = _parseOrderList(body);
      } catch (_) {}
    }
  }

  List<ApiOrder> _parseOrderList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => ApiOrder.fromJson(e))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => ApiOrder.fromJson(e))
            .toList();
      }
    }
    return [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _userOrderLinks = [];
    _orders = [];
    _selectedOrder = null;
    _isLoading = false;
    _isLoadingDetail = false;
    _error = null;
    _hasFetched = false;
    _currentOffset = 0;
    _hasMore = true;
    notifyListeners();
  }
}
