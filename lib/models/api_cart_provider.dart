// lib/models/api_cart_provider.dart
//
// Manages the backend cart session (Order Service, Redis-backed).
// Also maintains a local mirror of items for fast UI rendering.
// No authentication required — anonymous customer cart.
//

import 'package:flutter/foundation.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/customer_service.dart';
import '../core/network/api_exceptions.dart';
import '../models/cart_session_model.dart';
import '../models/order_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

enum CartState {
  idle,
  initializing,
  loading,
  adding,
  removing,
  placingOrder,
  error,
}

class ApiCartProvider extends ChangeNotifier {
  final CartService _cartService;
  final OrderService _orderService;
  final CustomerService _customerService;

  ApiCartProvider(this._cartService, this._orderService, this._customerService);

  String? _sessionId;
  String? _shopId;
  String? _lastCustomerId;
  List<CartSessionItem> _items = [];
  CartState _state = CartState.idle;
  String? _error;
  ApiOrder? _lastOrder;
  final List<ApiOrder> _myOrders = [];

  // Local quick-add mirror for instant UI feedback before backend sync
  // productId → LocalCartEntry
  final Map<String, LocalCartEntry> _localMirror = {};

  // Local cache of product details (persisted) in case backend item_info is missing
  final Map<String, ApiProduct> _productCache = {};

  // ── Getters ───────────────────────────────────────────────────────

  String? get sessionId => _sessionId;
  String? get shopId => _shopId;
  List<CartSessionItem> get items => _items;
  CartState get state => _state;
  String? get error => _error;
  ApiOrder? get lastOrder => _lastOrder;
  List<ApiOrder> get myOrders => List.unmodifiable(_myOrders);

  bool get isLoading =>
      _state == CartState.loading ||
      _state == CartState.initializing ||
      _state == CartState.adding ||
      _state == CartState.removing ||
      _state == CartState.placingOrder;

  bool get isEmpty => _items.isEmpty && _localMirror.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get itemCount {
    if (_items.isNotEmpty) {
      return _items.fold(0, (sum, i) => sum + i.qty.round());
    }
    return _localMirror.values.fold(0, (sum, e) => sum + e.qty);
  }

  double get subtotal {
    if (_items.isNotEmpty) {
      return _items.fold(0.0, (sum, i) => sum + i.lineTotal);
    }
    return _localMirror.values
        .fold(0.0, (sum, e) => sum + (e.product.displayPrice * e.qty));
  }

  // Local mirror items for fast UI before backend sync
  List<LocalCartEntry> get localItems => _localMirror.values.toList();

  // ── Init Cart ─────────────────────────────────────────────────────

  static const _sessionKey = 'api_cart_session_id';
  static const _shopKey = 'api_cart_shop_id';

  Future<void> initCart(String shopId) async {
    if (_sessionId != null && _shopId == shopId) return; // Already initialized

    _state = CartState.initializing;
    _shopId = shopId;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSession = prefs.getString(_sessionKey);
      final savedShop = prefs.getString(_shopKey);

      if (savedSession != null && savedSession.isNotEmpty && savedShop == shopId) {
        // Try to resume session
        _sessionId = savedSession;
        await _syncCart();
        
        // If _syncCart wiped _sessionId because it was expired or invalid in Redis, fall through to init a new one
        if (_sessionId != null) {
          await _loadPersistedOrders();
          _state = CartState.idle;
          notifyListeners();
          return;
        }
      }

      // Start fresh
      _sessionId = await _cartService.initCart();
      await prefs.setString(_sessionKey, _sessionId!);
      await prefs.setString(_shopKey, shopId);

      _items = [];
      _localMirror.clear();
      await _loadPersistedOrders();
      await _loadProductCache(prefs);
    } on ApiException catch (e) {
      _error = e.message;
      _state = CartState.error;
      notifyListeners();
      return;
    } catch (e) {
      _error = 'Failed to start cart session. Check your connection.';
      _state = CartState.error;
      notifyListeners();
      return;
    }

    _state = CartState.idle;
    notifyListeners();
  }

  Future<void> _loadProductCache(SharedPreferences prefs) async {
    try {
      final cacheStr = prefs.getString('api_cart_product_cache');
      if (cacheStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheStr);
        _productCache.clear();
        decoded.forEach((k, v) {
          _productCache[k] = ApiProduct.fromJson(v);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProductCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = jsonEncode(_productCache.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString('api_cart_product_cache', cacheStr);
    } catch (_) {}
  }

  // ── Reset for different shop ───────────────────────────────────────

  Future<void> resetForShop(String shopId) async {
    if (_sessionId != null) {
      try {
        await _cartService.cancelCart(_sessionId!);
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_shopKey);
    } catch (_) {}

    _sessionId = null;
    _shopId = null;
    _items = [];
    _localMirror.clear();
    _lastOrder = null;
    _error = null;
    _state = CartState.idle;
    notifyListeners();
    await initCart(shopId);
  }

  // ── Add Item ──────────────────────────────────────────────────────

  Future<void> addItem({
    required ApiProduct product,
    required String shopId,
    double qty = 1,
    String? variantId,
    String? batchId,
  }) async {
    int attempts = 0;

    // Auto-resolve variantId and batchId if missing or nested in variant
    String? effectiveVariantId = variantId;
    String? effectiveBatchId = batchId;

    if (effectiveVariantId == null && product.variants.isNotEmpty) {
      Map<String, dynamic>? selectedV;
      for (final v in product.variants) {
        if (ApiProduct.getVariantStock(v, haveTracking: product.haveTracking) > 0 || ApiProduct.getVariantPrice(v) > 0) {
          selectedV = v;
          break;
        }
      }
      selectedV ??= product.variants.first;
      effectiveVariantId = selectedV['id']?.toString();

      if (effectiveBatchId == null && selectedV['batch_infos'] is List && (selectedV['batch_infos'] as List).isNotEmpty) {
        for (final b in (selectedV['batch_infos'] as List)) {
          if (b is Map && b['id'] != null) {
            effectiveBatchId = b['id'].toString();
            break;
          }
        }
      }
    } else if (effectiveVariantId != null && effectiveBatchId == null) {
      // Find matching variant map to check for nested batch_infos
      for (final v in product.variants) {
        if (v['id']?.toString() == effectiveVariantId) {
          if (v['batch_infos'] is List && (v['batch_infos'] as List).isNotEmpty) {
            for (final b in (v['batch_infos'] as List)) {
              if (b is Map && b['id'] != null) {
                effectiveBatchId = b['id'].toString();
                break;
              }
            }
          }
          break;
        }
      }
    }

    if (effectiveBatchId == null && product.batches.isNotEmpty) {
      effectiveBatchId = product.batches.first['id']?.toString();
    }
    
    while (attempts < 2) {
      attempts++;
      
      // 1. Ensure cart session is ready for this shop
      if (_sessionId == null || _shopId != shopId) {
        await initCart(shopId);
        if (_sessionId == null) return; // Init failed
      }

      if (attempts == 1) {
        // Instant local feedback only on first attempt
        _updateLocalMirror(product, qty);
        _productCache[product.id] = product;
        _saveProductCache(); // fire and forget
        _state = CartState.adding;
        _error = null;
        notifyListeners();
      }

      try {
        await _cartService.addItem(
          sessionId: _sessionId!,
          shopId: shopId,
          productId: product.id,
          qty: qty,
          variantId: effectiveVariantId,
          batchId: effectiveBatchId,
          unit: product.unit,
        );
        
        // Sync with backend to get enriched items
        await _syncCart();
        
        _state = CartState.idle;
        notifyListeners();
        return; // Success!
        
      } on ApiException catch (e) {
        final msg = e.message.toLowerCase();
        if (e.statusCode == 400 || 
            e.statusCode == 404 || 
            msg.contains('invalid') || 
            msg.contains('expired') || 
            msg.contains('session') ||
            msg.contains('not found')) {
          _sessionId = null;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_sessionKey);
            await prefs.remove(_shopKey);
          } catch (_) {}
          
          if (attempts < 2) continue; // Retry with a fresh session!
        }
        _error = e.message;
        _state = CartState.idle;
        notifyListeners();
        return;
      } catch (e) {
        _error = 'Failed to add item. Try again.';
        _state = CartState.idle;
        notifyListeners();
        return;
      }
    }
  }

  // ── Remove Item ───────────────────────────────────────────────────

  Future<void> removeItem({
    required String productId,
    String? variantId,
    String? batchId,
  }) async {
    if (_sessionId == null) return;

    // Instant local feedback
    _localMirror.remove(productId);
    _items.removeWhere((i) => i.productId == productId);
    _state = CartState.removing;
    _error = null;
    notifyListeners();

    try {
      await _cartService.removeItem(
        sessionId: _sessionId!,
        productId: productId,
        variantId: variantId,
        batchId: batchId,
      );
      await _syncCart();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to remove item. Try again.';
    } finally {
      _state = CartState.idle;
      notifyListeners();
    }
  }

  // ── Update Quantity ───────────────────────────────────────────────

  Future<void> updateQuantity(CartSessionItem item, int newQty) async {
    int attempts = 0;
    
    while (attempts < 2) {
      attempts++;
      
      if (_sessionId == null) return;
      if (newQty <= 0) {
        await removeItem(productId: item.productId);
        return;
      }
      
      if (attempts == 1) {
        _state = CartState.adding;
        _error = null;
        notifyListeners();
      }

      try {
        await _cartService.removeItem(
          sessionId: _sessionId!,
          productId: item.productId,
        );
        await _cartService.addItem(
          sessionId: _sessionId!,
          shopId: item.shopId,
          productId: item.productId,
          qty: newQty.toDouble(),
          unit: item.unit,
        );
        await _syncCart();
        
        _state = CartState.idle;
        notifyListeners();
        return; // Success!
      } on ApiException catch (e) {
        final msg = e.message.toLowerCase();
        if (e.statusCode == 400 || 
            e.statusCode == 404 || 
            msg.contains('invalid') || 
            msg.contains('expired') || 
            msg.contains('session') ||
            msg.contains('not found')) {
          _sessionId = null;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_sessionKey);
            await prefs.remove(_shopKey);
          } catch (_) {}
          
          // Re-init session to avoid returning without one
          await initCart(item.shopId);
          if (attempts < 2) continue; // Retry!
        }
        _error = 'Failed to update quantity.';
        _state = CartState.idle;
        notifyListeners();
        return;
      } catch (e) {
        _error = 'Failed to update quantity.';
        _state = CartState.idle;
        notifyListeners();
        return;
      }
    }
  }

  // ── Get/Sync Cart ─────────────────────────────────────────────────

  Future<void> refreshCart() async {
    if (_sessionId == null) return;
    _state = CartState.loading;
    notifyListeners();
    await _syncCart();
    _state = CartState.idle;
    notifyListeners();
  }

  Future<void> _syncCart() async {
    if (_sessionId == null) return;
    try {
      _items = await _cartService.getCart(_sessionId!);
      
      // Patch missing backend data using our local cache
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.productName == 'Unknown Product' && _productCache.containsKey(item.productId)) {
          final cached = _productCache[item.productId]!;
          
          final Map<String, dynamic> fakeItemInfo = {
            'product': {
              'name': cached.name,
              'image_url': cached.imageUrls,
              'selling_price': cached.displayPrice,
            }
          };

          _items[i] = CartSessionItem(
            productId: item.productId,
            shopId: item.shopId,
            qty: item.qty,
            unit: item.unit,
            variantId: item.variantId,
            batchId: item.batchId,
            serialnoInfos: item.serialnoInfos,
            itemInfo: fakeItemInfo,
          );
        }
      }

      // Clear local mirror after successful sync
      _localMirror.clear();
    } on NotFoundException catch (_) {
      _sessionId = null;
      _items = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
        await prefs.remove(_shopKey);
      } catch (_) {}
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.statusCode == 404 || e.statusCode == 400 || msg.contains('session') || msg.contains('expired') || msg.contains('invalid') || msg.contains('not found')) {
        _sessionId = null;
        _items = [];
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_sessionKey);
          await prefs.remove(_shopKey);
        } catch (_) {}
      }
    } catch (_) {
      // Keep local mirror if network sync fails
    }
  }

  // ── Place Order ───────────────────────────────────────────────────

  Future<bool> placeOrder({
    required String shopId,
    required String customerName,
    required String customerPhone,
    String? paymentMethod,
    String? note,
    Map<String, dynamic>? deliveryAddress,
    String? userId,
    String? addressId,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? city,
    String? pincode,
    String? state,
  }) async {
    if (_sessionId == null) {
      _error = 'No active cart session.';
      notifyListeners();
      return false;
    }

    _state = CartState.placingOrder;
    _error = null;
    notifyListeners();

    try {
      final currentTotal = subtotal;
      
      // Build additional_infos with customer details, delivery + note (without calling /api/customers)
      final Map<String, dynamic> additionalInfos = {
        'customer_name': customerName,
        'customer_phone': customerPhone,
      };
      if (note != null && note.isNotEmpty) additionalInfos['note'] = note;
      if (deliveryAddress != null) additionalInfos['delivery_address'] = deliveryAddress;

      // Build payment_infos
      final Map<String, dynamic> paymentInfos = {};
      if (paymentMethod != null) {
        if (paymentMethod.toUpperCase() == 'CASH ON DELIVERY' || paymentMethod.toUpperCase() == 'COD') {
          paymentInfos[paymentMethod] = 0.0;
        } else {
          paymentInfos[paymentMethod] = currentTotal;
        }
      }

      final String? finalAddressId = addressId ?? deliveryAddress?['address_id']?.toString() ?? deliveryAddress?['id']?.toString();
      final String? finalFullAddress = fullAddress ?? deliveryAddress?['full_address']?.toString() ?? deliveryAddress?['address']?.toString();
      final double? finalLat = latitude ?? (deliveryAddress?['latitude'] != null ? double.tryParse(deliveryAddress!['latitude'].toString()) : (deliveryAddress?['lat'] != null ? double.tryParse(deliveryAddress!['lat'].toString()) : null));
      final double? finalLng = longitude ?? (deliveryAddress?['longitude'] != null ? double.tryParse(deliveryAddress!['longitude'].toString()) : (deliveryAddress?['lng'] != null ? double.tryParse(deliveryAddress!['lng'].toString()) : null));
      final String? finalCity = city ?? deliveryAddress?['city']?.toString();
      final String? finalPincode = pincode ?? deliveryAddress?['pincode']?.toString();
      final String? finalState = state ?? deliveryAddress?['state']?.toString();

      final payload = CreateOrderPayload(
        shopId: shopId,
        sessionId: _sessionId!,
        customerId: null,
        status: 'PENDING',
        origin: 'ONLINE',
        paymentInfos: paymentInfos,
        additionalInfos: additionalInfos.isNotEmpty ? additionalInfos : null,
        userId: userId,
        name: customerName,
        phone: customerPhone,
        addressId: finalAddressId,
        fullAddress: finalFullAddress,
        latitude: finalLat,
        longitude: finalLng,
        city: finalCity,
        pincode: finalPincode,
        state: finalState,
      );

      final orderItems = _items.map((cartItem) {
        return ApiOrderItem(
          productId: cartItem.productId,
          variantId: cartItem.variantId,
          batchId: cartItem.batchId,
          qty: cartItem.qty,
          unit: cartItem.unit,
          unitPrice: cartItem.sellingPrice,
          lineTotal: cartItem.lineTotal,
          productName: cartItem.productName,
        );
      }).toList();

      final createdOrder = await _orderService.placeOrder(payload);
      
      if (createdOrder.id.isEmpty || createdOrder.id == 'N/A') {
        _lastOrder = ApiOrder(
           id: 'N/A',
           shopId: shopId,
           status: 'PROCESSING',
           totalAmount: currentTotal,
           items: orderItems,
           createdAt: DateTime.now().toIso8601String(),
        );
      } else {
        _lastOrder = createdOrder;
      }
      
      _myOrders.add(_lastOrder!);

      // Clear cart after successful order
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
        await prefs.remove(_shopKey);
      } catch (_) {}

      _sessionId = null;
      _shopId = null;
      _items = [];
      _localMirror.clear();
      _state = CartState.idle;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = CartState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to place order. Please try again.';
      _state = CartState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Cancel Cart ───────────────────────────────────────────────────

  Future<void> cancelCart() async {
    if (_sessionId == null) return;
    try {
      await _cartService.cancelCart(_sessionId!);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_shopKey);
    } catch (_) {}

    _sessionId = null;
    _shopId = null;
    _items = [];
    _localMirror.clear();
    _state = CartState.idle;
    _error = null;
    notifyListeners();
  }

  // ── Local Mirror Helpers ──────────────────────────────────────────

  void _updateLocalMirror(ApiProduct product, double additionalQty) {
    if (_localMirror.containsKey(product.id)) {
      _localMirror[product.id]!.qty += additionalQty.round();
    } else {
      _localMirror[product.id] = LocalCartEntry(
        product: product,
        qty: additionalQty.round(),
      );
    }
  }

  bool isInCart(String productId) {
    if (_items.any((i) => i.productId == productId)) return true;
    return _localMirror.containsKey(productId);
  }

  int quantityOf(String productId) {
    for (final item in _items) {
      if (item.productId == productId) return item.qty.round();
    }
    return _localMirror[productId]?.qty ?? 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Refresh Orders ──────────────────────────────────────────────────
  Future<void> refreshOrders() async {
    if (_shopId != null && _lastCustomerId != null) {
      final orders = await _orderService.getOrdersByCustomer(_shopId!, _lastCustomerId!);
      if (orders.isNotEmpty) {
        _myOrders.clear();
        _myOrders.addAll(orders);
      }
    } else {
      // Fallback to old behavior if no customer ID
      for (int i = 0; i < _myOrders.length; i++) {
        final order = _myOrders[i];
        if (order.id == 'N/A' || order.shopId.isEmpty) continue;
        
        final freshOrder = await _orderService.getOrderById(order.shopId, order.id);
        if (freshOrder != null) {
          _myOrders[i] = freshOrder;
        }
      }
    }
    notifyListeners();
  }
  // ── Persistence ──────────────────────────────────────────────────────
  static const _customerKey = 'api_cart_customer_id';

  Future<void> _savePersistedCustomerId(String customerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerKey, customerId);
    } catch (_) {}
  }

  Future<void> _loadPersistedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastCustomerId = prefs.getString(_customerKey);
      if (_lastCustomerId != null && _shopId != null) {
        await refreshOrders();
      }
    } catch (_) {}
  }
}

class LocalCartEntry {
  final ApiProduct product;
  int qty;

  LocalCartEntry({required this.product, required this.qty});
}
