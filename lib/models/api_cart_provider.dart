// lib/models/api_cart_provider.dart
//
// Manages the backend cart session (Order Service, Redis-backed).
// Also maintains a local mirror of items for fast UI rendering.
// No authentication required — anonymous customer cart.
//

import 'package:flutter/foundation.dart';
import 'dart:async';
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

  CustomerService get customerService => _customerService;

  String? _sessionId;
  String? _shopId;
  String? _lastCustomerId;
  List<CartSessionItem> _items = [];
  CartState _state = CartState.idle;
  String? _error;
  ApiOrder? _lastOrder;
  final List<ApiOrder> _myOrders = [];
  String? _addingProductId;

  final Map<String, Timer> _debounceTimers = {};

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
  String? get addingProductId => _addingProductId;

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

  double get baseSubtotal {
    if (_items.isNotEmpty) {
      return double.parse(
        _items.fold(0.0, (sum, i) => sum + i.lineBasePrice).toStringAsFixed(2),
      );
    }
    return double.parse(
      _localMirror.values
          .fold(0.0, (sum, e) => sum + e.lineBasePrice)
          .toStringAsFixed(2),
    );
  }

  double get totalGstAmount {
    if (_items.isNotEmpty) {
      return double.parse(
        _items.fold(0.0, (sum, i) => sum + i.lineGstAmount).toStringAsFixed(2),
      );
    }
    return double.parse(
      _localMirror.values
          .fold(0.0, (sum, e) => sum + e.lineGstAmount)
          .toStringAsFixed(2),
    );
  }

  // Local mirror items for fast UI before backend sync
  List<LocalCartEntry> get localItems => _localMirror.values.toList();

  // ── Init Cart ─────────────────────────────────────────────────────

  static const _sessionKey = 'api_cart_session_id';
  static const _shopKey = 'api_cart_shop_id';
  static const _sessionTsKey = 'api_cart_session_ts';

  // Redis session TTL is 20 minutes (1200s). Re-init if older than 18 minutes.
  static const int _sessionMaxAgeMs = 18 * 60 * 1000;

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
      final savedTs = prefs.getInt(_sessionTsKey) ?? 0;
      final isFresh = (DateTime.now().millisecondsSinceEpoch - savedTs) < _sessionMaxAgeMs;

      if (savedSession != null && savedSession.isNotEmpty && savedShop == shopId && isFresh) {
        // Try to resume session
        _sessionId = savedSession;
        await _syncCart();
        
        // If _syncCart wiped _sessionId because it was expired or invalid in Redis, fall through to init a new one
        if (_sessionId != null) {
          unawaited(_loadPersistedOrders());
          _state = CartState.idle;
          notifyListeners();
          return;
        }
      }

      // Start fresh
      _sessionId = await _cartService.initCart();
      await prefs.setString(_sessionKey, _sessionId!);
      await prefs.setString(_shopKey, shopId);
      await prefs.setInt(_sessionTsKey, DateTime.now().millisecondsSinceEpoch);

      _items = [];
      // Do not clear _localMirror here — preserves optimistic items added by user
      unawaited(_loadPersistedOrders());
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
      await prefs.remove(_sessionTsKey);
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
    // 1. Auto-resolve variantId and batchId if missing or nested in variant
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

    // 2. Instant optimistic local feedback before any network latency
    _updateLocalMirror(product, qty, variantId: effectiveVariantId, batchId: effectiveBatchId);
    _productCache[product.id] = product;
    _saveProductCache(); // fire and forget
    _state = CartState.adding;
    _addingProductId = product.id;
    _error = null;
    notifyListeners();

    int attempts = 0;
    while (attempts < 2) {
      attempts++;

      // Ensure cart session is ready for this shop
      if (_sessionId == null || _shopId != shopId) {
        await initCart(shopId);
        if (_sessionId == null) {
          _state = CartState.idle;
          _addingProductId = null;
          notifyListeners();
          return; // Init failed
        }
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

        // Update session timestamp on successful touch
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(_sessionTsKey, DateTime.now().millisecondsSinceEpoch);
        });

        // Sync with backend to get enriched items
        await _syncCart();

        _state = CartState.idle;
        _addingProductId = null;
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
            await prefs.remove(_sessionTsKey);
          } catch (_) {}

          if (attempts < 2) continue; // Retry with a fresh session!
        }

        // Handle intermittent server errors without clearing session
        if (e.statusCode != null && e.statusCode! >= 500) {
          if (attempts < 2) {
            await Future.delayed(const Duration(milliseconds: 300));
            continue; // Retry
          }
        }
        _error = e.message;
        _state = CartState.idle;
        _addingProductId = null;
        notifyListeners();
        return;
      } catch (e) {
        _error = 'Failed to add item. Try again.';
        _state = CartState.idle;
        _addingProductId = null;
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
    final key = '${productId}_${variantId ?? ''}_${batchId ?? ''}';
    _localMirror.remove(key);
    _items.removeWhere((i) => i.productId == productId && i.variantId == variantId && i.batchId == batchId);
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

  Future<void> updateQuantityByProduct({
    required ApiProduct product,
    required String shopId,
    required int newQty,
    String? variantId,
    String? batchId,
  }) async {
    CartSessionItem? item;
    for (final i in _items) {
      if (i.productId == product.id && i.variantId == variantId && i.batchId == batchId) {
        item = i;
        break;
      }
    }
    
    if (item != null) {
      await updateQuantity(item, newQty);
    } else if (newQty == 0) {
      await removeItem(productId: product.id, variantId: variantId, batchId: batchId);
    } else {
      // If it's not in the backend items, maybe add it fresh (or it was just a local mirror)
      await addItem(
        product: product,
        shopId: shopId,
        qty: newQty.toDouble(),
        variantId: variantId,
        batchId: batchId,
      );
    }
  }

  Future<void> updateQuantity(CartSessionItem item, int newQty) async {
    if (_sessionId == null) return;
    
    // Optimistic UI Update
    final index = _items.indexWhere((i) => i.productId == item.productId && i.variantId == item.variantId && i.batchId == item.batchId);
    
    if (newQty <= 0) {
      if (index != -1) {
        _items.removeAt(index);
        notifyListeners();
      }
      _debouncedBackendUpdate(item.productId, item.variantId, item.batchId, item.shopId, 0, item.unit);
      return;
    }

    if (index != -1) {
      _items[index] = CartSessionItem(
        productId: item.productId,
        shopId: item.shopId,
        variantId: item.variantId,
        batchId: item.batchId,
        serialnoInfos: item.serialnoInfos,
        qty: newQty.toDouble(),
        unit: item.unit,
        itemInfo: item.itemInfo,
      );
      notifyListeners();
    }
    
    _debouncedBackendUpdate(item.productId, item.variantId, item.batchId, item.shopId, newQty.toDouble(), item.unit);
  }

  void _debouncedBackendUpdate(String productId, String? variantId, String? batchId, String shopId, double newQty, String? unit) {
    final key = '${productId}_${variantId ?? ''}_${batchId ?? ''}';
    
    if (_debounceTimers.containsKey(key)) {
      _debounceTimers[key]?.cancel();
    }
    
    _debounceTimers[key] = Timer(const Duration(milliseconds: 500), () async {
      _debounceTimers.remove(key);
      int attempts = 0;
      while (attempts < 2) {
        attempts++;
        try {
          await _cartService.removeItem(
            sessionId: _sessionId!,
            productId: productId,
            variantId: variantId,
            batchId: batchId,
          );
          if (newQty > 0) {
            await _cartService.addItem(
              sessionId: _sessionId!,
              shopId: shopId,
              productId: productId,
              qty: newQty,
              unit: unit,
              variantId: variantId,
              batchId: batchId,
            );
          }
          
          // Background sync to ensure backend matches local
          _syncCart().then((_) {
            if (hasListeners) notifyListeners();
          });
          
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
            
            await initCart(shopId);
            if (attempts < 2) continue; // Retry!
          }
          
          // On permanent failure, revert cart by syncing
          _error = 'Failed to update quantity.';
          await _syncCart();
          if (hasListeners) notifyListeners();
          return;
        } catch (e) {
          _error = 'Failed to update quantity.';
          await _syncCart();
          if (hasListeners) notifyListeners();
          return;
        }
      }
    });
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
        final bool isMissingInfo = item.itemInfo == null ||
            item.itemInfo!.isEmpty ||
            item.productName == 'Product' ||
            item.productName == 'Unknown Product';
        if (isMissingInfo && _productCache.containsKey(item.productId)) {
          final cached = _productCache[item.productId]!;
          
          final Map<String, dynamic> fakeItemInfo = {
            'product': {
              'name': cached.name,
              'image_url': cached.imageUrls,
              'selling_price': cached.displayPrice,
              'gst': cached.gst,
              'pricing_infos': {
                'sell_price': cached.displayPrice,
                'online_sell_price': cached.displayPrice,
              },
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

      // Selectively clean up local mirror for items confirmed by backend
      for (final item in _items) {
        final key = '${item.productId}_${item.variantId ?? ''}_${item.batchId ?? ''}';
        _localMirror.remove(key);
        _localMirror.remove('${item.productId}__');
      }
      if (_items.isNotEmpty) {
        _localMirror.removeWhere((key, entry) =>
            _items.any((i) => i.productId == entry.product.id));
      }
    } on NotFoundException catch (_) {
      _sessionId = null;
      _items = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
        await prefs.remove(_shopKey);
        await prefs.remove(_sessionTsKey);
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
          await prefs.remove(_sessionTsKey);
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
    String? customerPhone,
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
    double deliveryFee = 0.0,
    Map<String, dynamic>? deliveryOptionInfo,
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
        if (customerPhone != null && customerPhone.trim().isNotEmpty)
          'customer_phone': customerPhone.trim(),
      };
      final String? finalAddressId = addressId ?? deliveryAddress?['address_id']?.toString() ?? deliveryAddress?['id']?.toString();
      if (finalAddressId != null && finalAddressId.isNotEmpty) {
        additionalInfos['address_id'] = finalAddressId;
      }
      if (note != null && note.isNotEmpty) additionalInfos['note'] = note;
      if (deliveryAddress != null) additionalInfos['delivery_address'] = deliveryAddress;

      if (deliveryOptionInfo != null) {
        additionalInfos['delivery_option'] = deliveryOptionInfo;
        if (deliveryOptionInfo['type'] != null) {
          additionalInfos['delivery_type'] = deliveryOptionInfo['type'];
        }
        if (deliveryOptionInfo['title'] != null) {
          additionalInfos['delivery_option_name'] = deliveryOptionInfo['title'];
        }
        if (deliveryOptionInfo['speed'] != null) {
          additionalInfos['delivery_speed'] = deliveryOptionInfo['speed'];
        }
        additionalInfos['delivery_charge'] = deliveryFee;
      }

      final double finalTotal = currentTotal + deliveryFee;

      // Build payment_infos
      final Map<String, dynamic> paymentInfos = {};
      if (paymentMethod != null) {
        if (paymentMethod.toUpperCase() == 'CASH ON DELIVERY' || paymentMethod.toUpperCase() == 'COD') {
          paymentInfos[paymentMethod] = 0.0;
        } else {
          paymentInfos[paymentMethod] = finalTotal;
        }
      }

      final String? finalFullAddress = fullAddress ?? deliveryAddress?['full_address']?.toString() ?? deliveryAddress?['address']?.toString();
      final double? finalLat = latitude ?? (deliveryAddress?['latitude'] != null ? double.tryParse(deliveryAddress!['latitude'].toString()) : (deliveryAddress?['lat'] != null ? double.tryParse(deliveryAddress!['lat'].toString()) : null));
      final double? finalLng = longitude ?? (deliveryAddress?['longitude'] != null ? double.tryParse(deliveryAddress!['longitude'].toString()) : (deliveryAddress?['lng'] != null ? double.tryParse(deliveryAddress!['lng'].toString()) : null));
      final String? finalCity = city ?? deliveryAddress?['city']?.toString();
      final String? finalPincode = pincode ?? deliveryAddress?['pincode']?.toString();
      final String? finalState = state ?? deliveryAddress?['state']?.toString();

      final List<Map<String, dynamic>> calcItems = [];
      final Map<double, Map<String, double>> taxGroupsMap = {};
      double calcBaseTotal = 0.0;
      double calcGstTotal = 0.0;

      void accumulateItem({
        required String productId,
        required String name,
        String? variantName,
        required double qty,
        String? unit,
        required double sellingPrice,
        required double gstRate,
        required double lineTotal,
      }) {
        final unitSplit = calculateInclusiveTaxSplit(sellingPrice, gstRate);
        final lineTaxable = double.parse((unitSplit.unitBasePrice * qty).toStringAsFixed(2));
        final lineGst = double.parse((unitSplit.unitGst * qty).toStringAsFixed(2));
        final lineCgst = double.parse((lineGst / 2.0).toStringAsFixed(2));
        final lineSgst = double.parse((lineGst - lineCgst).toStringAsFixed(2));

        calcBaseTotal += lineTaxable;
        calcGstTotal += lineGst;

        if (gstRate > 0) {
          final bucket = taxGroupsMap.putIfAbsent(
            gstRate,
            () => {'taxableValue': 0.0, 'totalTax': 0.0, 'cgst': 0.0, 'sgst': 0.0},
          );
          bucket['taxableValue'] = (bucket['taxableValue'] ?? 0.0) + lineTaxable;
          bucket['totalTax'] = (bucket['totalTax'] ?? 0.0) + lineGst;
          bucket['cgst'] = (bucket['cgst'] ?? 0.0) + lineCgst;
          bucket['sgst'] = (bucket['sgst'] ?? 0.0) + lineSgst;
        }

        calcItems.add({
          'product_id': productId,
          'name': name,
          'variant_name': ?variantName,
          'qty': qty,
          'unit': ?unit,
          'price': sellingPrice,
          'gst_rate': gstRate,
          'taxable_value': lineTaxable,
          'gst_amount': lineGst,
          'cgst': lineCgst,
          'sgst': lineSgst,
          'final_inclusive': lineTotal,
        });
      }

      if (_items.isNotEmpty) {
        for (final cartItem in _items) {
          accumulateItem(
            productId: cartItem.productId,
            name: cartItem.productName,
            variantName: cartItem.variantName,
            qty: cartItem.qty,
            unit: cartItem.unit,
            sellingPrice: cartItem.sellingPrice,
            gstRate: cartItem.gstRate,
            lineTotal: cartItem.lineTotal,
          );
        }
      } else {
        for (final localEntry in _localMirror.values) {
          accumulateItem(
            productId: localEntry.product.id,
            name: localEntry.product.name,
            qty: localEntry.qty.toDouble(),
            sellingPrice: localEntry.product.displayPrice,
            gstRate: localEntry.gstRate,
            lineTotal: localEntry.lineTotal,
          );
        }
      }

      calcGstTotal = double.parse(calcGstTotal.toStringAsFixed(2));
      calcBaseTotal = calcBaseTotal > 0
          ? double.parse(calcBaseTotal.toStringAsFixed(2))
          : double.parse((currentTotal - calcGstTotal).clamp(0.0, double.infinity).toStringAsFixed(2));
      final double calcCgstTotal = double.parse((calcGstTotal / 2.0).toStringAsFixed(2));
      final double calcSgstTotal = double.parse((calcGstTotal - calcCgstTotal).toStringAsFixed(2));
      final taxGroupsList = taxGroupsMap.entries
          .map((e) => {
                'gstRate': e.key,
                'taxableValue': double.parse((e.value['taxableValue'] ?? 0.0).toStringAsFixed(2)),
                'cgst': double.parse((e.value['cgst'] ?? 0.0).toStringAsFixed(2)),
                'sgst': double.parse((e.value['sgst'] ?? 0.0).toStringAsFixed(2)),
                'totalTax': double.parse((e.value['totalTax'] ?? 0.0).toStringAsFixed(2)),
              })
          .toList();

      final Map<String, dynamic> calculationInfos = {
        'subtotal': currentTotal,
        'taxable_amount': calcBaseTotal,
        'base_subtotal': calcBaseTotal,
        'gst_amount': calcGstTotal,
        'cgst': calcCgstTotal,
        'sgst': calcSgstTotal,
        if (taxGroupsList.isNotEmpty) 'tax_groups': taxGroupsList,
        if (calcItems.isNotEmpty) 'items': calcItems,
        'delivery_fee': deliveryFee,
        'total': finalTotal,
        'grand_total': finalTotal,
        'full_address': ?finalFullAddress,
        'delivery_address': ?deliveryAddress,
      };

      final Map<String, dynamic> chargesInfos = {
        if (deliveryFee > 0) 'delivery_charge': deliveryFee,
      };

      final payload = CreateOrderPayload(
        shopId: shopId,
        sessionId: _sessionId!,
        customerId: null,
        status: 'PENDING',
        origin: 'ONLINE',
        paymentInfos: paymentInfos,
        calculationInfos: calculationInfos,
        chargesInfos: chargesInfos,
        additionalInfos: additionalInfos.isNotEmpty ? additionalInfos : null,
        userId: userId,
        name: customerName,
        phone: (customerPhone != null && customerPhone.trim().isNotEmpty) ? customerPhone.trim() : null,
        addressId: finalAddressId,
        fullAddress: finalFullAddress,
        latitude: finalLat,
        longitude: finalLng,
        city: finalCity,
        pincode: finalPincode,
        state: finalState,
      );

      if (kDebugMode) {
        print('\x1B[35m┌──────────────────────────────────────────────────────────────\x1B[0m');
        print('\x1B[35m│ [CHECKOUT] Sending Exact Customer Info to Backend:\x1B[0m');
        print('\x1B[35m│ User ID:      $userId\x1B[0m');
        print('\x1B[35m│ Name:         $customerName\x1B[0m');
        print('\x1B[35m│ Phone:        $customerPhone\x1B[0m');
        print('\x1B[35m│ Address ID:   $finalAddressId\x1B[0m');
        print('\x1B[35m│ Full Address: $finalFullAddress\x1B[0m');
        print('\x1B[35m│ City:         $finalCity\x1B[0m');
        print('\x1B[35m│ State:        $finalState\x1B[0m');
        print('\x1B[35m│ Pincode:      $finalPincode\x1B[0m');
        print('\x1B[35m│ Latitude:     $finalLat\x1B[0m');
        print('\x1B[35m│ Longitude:    $finalLng\x1B[0m');
        print('\x1B[35m└──────────────────────────────────────────────────────────────\x1B[0m');
      }

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
          imageUrl: cartItem.productImage,
        );
      }).toList();

      final createdOrder = await _orderService.placeOrder(payload);
      
      List<ApiOrderItem> finalItems = createdOrder.items.isNotEmpty ? createdOrder.items : orderItems;
      finalItems = finalItems.map((item) {
        if (item.imageUrl == null) {
          final matched = orderItems.where((c) => c.productId == item.productId).firstOrNull;
          if (matched?.imageUrl != null) {
            return item.copyWith(imageUrl: matched!.imageUrl);
          }
        }
        return item;
      }).toList();

      if (createdOrder.id.isEmpty || createdOrder.id == 'N/A') {
        _lastOrder = ApiOrder(
           id: 'N/A',
           shopId: shopId,
           status: 'PROCESSING',
           totalAmount: finalTotal,
           calculationInfos: calculationInfos,
           chargesInfos: chargesInfos,
           additionalInfos: additionalInfos,
           deliveryAddress: deliveryAddress,
           customerName: customerName,
           customerPhone: customerPhone,
           addressId: finalAddressId,
           fullAddress: finalFullAddress,
           city: finalCity,
           pincode: finalPincode,
           state: finalState,
           note: note,
           items: finalItems,
           createdAt: DateTime.now().toIso8601String(),
        );
      } else {
        _lastOrder = ApiOrder(
           id: createdOrder.id,
           uiId: createdOrder.uiId,
           shopId: createdOrder.shopId,
           customerId: createdOrder.customerId,
           status: createdOrder.status,
           description: createdOrder.description,
           totalAmount: createdOrder.totalAmount > 0 ? createdOrder.totalAmount : finalTotal,
           calculationInfos: createdOrder.calculationInfos ?? calculationInfos,
           chargesInfos: createdOrder.chargesInfos ?? chargesInfos,
           paymentInfos: createdOrder.paymentInfos,
           additionalInfos: createdOrder.additionalInfos ?? additionalInfos,
           deliveryAddress: createdOrder.deliveryAddress ?? deliveryAddress,
           customerName: createdOrder.customerName ?? customerName,
           customerPhone: createdOrder.customerPhone ?? customerPhone,
           addressId: createdOrder.addressId ?? finalAddressId,
           fullAddress: createdOrder.fullAddress ?? finalFullAddress,
           city: createdOrder.city ?? finalCity,
           pincode: createdOrder.pincode ?? finalPincode,
           state: createdOrder.state ?? finalState,
           note: createdOrder.note ?? note,
           items: finalItems,
           createdAt: createdOrder.createdAt,
           updatedAt: createdOrder.updatedAt,
           otp: createdOrder.otp,
        );
      }
      
      _myOrders.add(_lastOrder!);

      if (userId != null && userId.isNotEmpty) {
        _lastCustomerId = userId;
        _savePersistedCustomerId(userId);
      }

      // Clear cart after successful order
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
        await prefs.remove(_shopKey);
        await prefs.remove(_sessionTsKey);
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
      await prefs.remove(_sessionTsKey);
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

  void _updateLocalMirror(ApiProduct product, double additionalQty, {String? variantId, String? batchId}) {
    final key = '${product.id}_${variantId ?? ''}_${batchId ?? ''}';
    if (_localMirror.containsKey(key)) {
      _localMirror[key]!.qty += additionalQty.round();
    } else {
      _localMirror[key] = LocalCartEntry(
        product: product,
        qty: additionalQty.round(),
        variantId: variantId,
        batchId: batchId,
      );
    }
  }

  bool isVariantInCart(String productId, String? variantId, String? batchId) {
    // 1. Strict match in backend items
    if (_items.any((i) =>
        i.productId == productId &&
        i.variantId == variantId &&
        (batchId == null || i.batchId == null || i.batchId == batchId))) {
      return true;
    }
    // 2. Strict match in local mirror
    final key = '${productId}_${variantId ?? ''}_${batchId ?? ''}';
    if (_localMirror.containsKey(key)) return true;

    // 3. Relaxed match in local mirror if batch was omitted or auto-resolved
    if (_localMirror.values.any((e) =>
        e.product.id == productId &&
        (variantId == null || e.variantId == null || e.variantId == variantId))) {
      return true;
    }
    return false;
  }

  bool isInCart(String productId) {
    if (_items.any((i) => i.productId == productId)) return true;
    return _localMirror.values.any((e) => e.product.id == productId);
  }

  int quantityOf(String productId, {String? variantId, String? batchId}) {
    for (final item in _items) {
      if (item.productId == productId &&
          item.variantId == variantId &&
          (batchId == null || item.batchId == null || item.batchId == batchId)) {
        return item.qty.round();
      }
    }
    final key = '${productId}_${variantId ?? ''}_${batchId ?? ''}';
    if (_localMirror.containsKey(key)) return _localMirror[key]!.qty;
    for (final entry in _localMirror.values) {
      if (entry.product.id == productId &&
          (variantId == null || entry.variantId == null || entry.variantId == variantId)) {
        return entry.qty;
      }
    }
    return 0;
  }

  int totalQuantityOf(String productId) {
    int total = 0;
    for (final item in _items) {
      if (item.productId == productId) {
        total += item.qty.round();
      }
    }
    for (final entry in _localMirror.values) {
      if (entry.product.id == productId && !_items.any((i) => i.productId == productId && i.variantId == entry.variantId && i.batchId == entry.batchId)) {
        total += entry.qty;
      }
    }
    return total;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateOrderStatusLocally(String orderId, String newStatus) {
    final idx = _myOrders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _myOrders[idx] = _myOrders[idx].copyWith(
        status: newStatus,
        updatedAt: DateTime.now().toIso8601String(),
      );
      notifyListeners();
    }
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
  final String? variantId;
  final String? batchId;

  LocalCartEntry({
    required this.product, 
    required this.qty,
    this.variantId,
    this.batchId,
  });

  /// Raw GST rate percentage (e.g. 18.0)
  double get gstRate {
    if (product.gst != null) {
      final cleaned = product.gst!.replaceAll('%', '').trim();
      final parsed = double.tryParse(cleaned);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0.0;
  }

  /// Unit GST amount based on inclusive selling price
  double get unitGstAmount {
    if (gstRate <= 0) return 0.0;
    final calculated = product.displayPrice * (gstRate / 100.0);
    return double.parse(calculated.toStringAsFixed(2));
  }

  /// Unit base price excluding GST
  double get unitBasePrice {
    final base = product.displayPrice - unitGstAmount;
    return double.parse(base.toStringAsFixed(2));
  }

  /// Total base price for line item
  double get lineBasePrice => double.parse((unitBasePrice * qty).toStringAsFixed(2));

  /// Total GST amount for line item
  double get lineGstAmount => double.parse((unitGstAmount * qty).toStringAsFixed(2));

  /// Line total
  double get lineTotal => product.displayPrice * qty;
}
