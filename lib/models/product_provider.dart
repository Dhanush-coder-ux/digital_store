// lib/models/product_provider.dart
//
// Fetches and caches products per shop from the Inventory Service.
//

import 'package:flutter/foundation.dart';
import '../services/product_service.dart';
import '../core/network/api_exceptions.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service;

  ProductProvider(this._service);

  // Keyed by shopId so multiple shops can be cached concurrently
  final Map<String, List<ApiProduct>> _productsByShop = {};
  final Map<String, bool> _loadingByShop = {};
  final Map<String, String?> _errorByShop = {};

  List<ApiProduct> productsForShop(String shopId) =>
      (_productsByShop[shopId] ?? []).where((p) => p.visibleOnline).toList();

  /// All products across all cached shops — used by the Favorites page.
  List<ApiProduct> get allCachedProducts =>
      _productsByShop.values.expand((list) => list).toList();

  bool isLoadingShop(String shopId) => _loadingByShop[shopId] ?? false;

  String? errorForShop(String shopId) => _errorByShop[shopId];

  // ── Fetch Products by Shop ─────────────────────────────────────────

  Future<void> fetchProductsByShop(
    String shopId, {
    bool force = false,
    String q = '',
    int limit = 100,
    int offset = 1,
  }) async {
    if (!force && _productsByShop.containsKey(shopId) && _errorByShop[shopId] == null) {
      return; // Already cached
    }

    _loadingByShop[shopId] = true;
    _errorByShop[shopId] = null;
    notifyListeners();

    try {
      _productsByShop[shopId] = await _service.fetchProductsByShop(
        shopId,
        q: q,
        limit: limit,
        offset: offset,
      );
    } on ApiException catch (e) {
      _errorByShop[shopId] = e.message;
    } catch (e) {
      _errorByShop[shopId] = 'Could not load products. Check your connection.';
    } finally {
      _loadingByShop[shopId] = false;
      notifyListeners();
    }
  }

  Future<void> refreshProductsByShop(String shopId) =>
      fetchProductsByShop(shopId, force: true);

  // ── Filtered/Searched Products ─────────────────────────────────────

  List<ApiProduct> filteredProducts(String shopId, {String? category, String? query}) {
    var list = productsForShop(shopId);
    if (category != null && category.isNotEmpty && category != 'All') {
      list = list.where((p) =>
          p.category?.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  /// All unique categories for a given shop
  List<String> categoriesForShop(String shopId) {
    final products = productsForShop(shopId);
    final cats = products
        .map((p) => p.category)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  void clearShop(String shopId) {
    _productsByShop.remove(shopId);
    _loadingByShop.remove(shopId);
    _errorByShop.remove(shopId);
    notifyListeners();
  }

  void reset() {
    _productsByShop.clear();
    _loadingByShop.clear();
    _errorByShop.clear();
    notifyListeners();
  }
}
