// lib/models/search_provider.dart
//
// Manages search state: product/shop search, search history,
// debounced queries, product-matched shops resolution, shop cache,
// and recent searches from DigitalStore API.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/digitalstore_service.dart';
import '../core/models/search_history_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';

class SearchProvider extends ChangeNotifier {
  final DigitalStoreService _service;

  List<SearchHistoryEntry> _recentSearches = [];
  List<Shop> _shopResults = [];
  List<ApiProduct> _productResults = [];
  
  // Cache of known shops by shopId for instant lookup and name resolution
  final Map<String, Shop> _shopCache = {};

  // Maps shopId -> list of product names from that shop that matched the search query
  Map<String, List<String>> _shopMatchedProductNames = {};

  bool _isSearching = false;
  bool _isLoadingHistory = false;
  String? _error;
  String _query = '';
  Timer? _debounce;
  int _searchSessionId = 0;

  SearchProvider(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  List<SearchHistoryEntry> get recentSearches => _recentSearches;
  List<Shop> get shopResults => _shopResults;
  List<ApiProduct> get productResults => _productResults;
  bool get isSearching => _isSearching;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  String get query => _query;
  bool get hasResults => _shopResults.isNotEmpty || _productResults.isNotEmpty;
  Map<String, List<String>> get shopMatchedProducts => _shopMatchedProductNames;

  // ── Shop Cache & Resolution Helpers ─────────────────────────────

  void seedShopCache(List<Shop> shops) {
    for (final shop in shops) {
      if (shop.id.isNotEmpty) {
        _shopCache[shop.id] = shop;
      }
    }
  }

  Shop? getShop(String shopId) => _shopCache[shopId];

  String getShopName(String shopId) {
    final shop = _shopCache[shopId];
    if (shop != null && shop.name.isNotEmpty) {
      return shop.name;
    }
    return shopId.length > 8 ? 'Shop #${shopId.substring(0, 6)}' : 'Shop #$shopId';
  }

  String? getShopLogo(String shopId) => _shopCache[shopId]?.logoUrl;

  bool isShopMatchedViaProduct(String shopId) {
    return _shopMatchedProductNames.containsKey(shopId) &&
        (_shopMatchedProductNames[shopId]?.isNotEmpty ?? false);
  }

  List<String> getMatchedProductNamesForShop(String shopId) {
    return _shopMatchedProductNames[shopId] ?? [];
  }

  String? getMatchedProductSummary(String shopId) {
    final products = _shopMatchedProductNames[shopId];
    if (products == null || products.isEmpty) return null;
    if (products.length == 1) {
      return 'Offers "${products.first}"';
    } else if (products.length == 2) {
      return 'Offers "${products[0]}" & "${products[1]}"';
    } else {
      return 'Offers "${products[0]}" (+${products.length - 1} more)';
    }
  }

  // ── Search (Debounced 300ms) ────────────────────────────────────

  void search(String query, {String? userId, List<Shop>? cachedShops}) {
    _query = query;
    _debounce?.cancel();

    if (cachedShops != null && cachedShops.isNotEmpty) {
      seedShopCache(cachedShops);
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchSessionId++;
      _shopResults = [];
      _productResults = [];
      _shopMatchedProductNames = {};
      _isSearching = false;
      _error = null;
      notifyListeners();
      return;
    }

    // Invalidate stale in-flight searches immediately to discard old results
    final sessionId = ++_searchSessionId;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(trimmed, sessionId: sessionId, userId: userId);
    });
  }

  Future<void> executeSearchNow({String? userId, List<Shop>? cachedShops, String? query}) async {
    _debounce?.cancel();
    if (query != null) {
      _query = query;
    }
    if (cachedShops != null && cachedShops.isNotEmpty) {
      seedShopCache(cachedShops);
    }
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      _searchSessionId++;
      _shopResults = [];
      _productResults = [];
      _shopMatchedProductNames = {};
      _isSearching = false;
      _error = null;
      notifyListeners();
      return;
    }
    final sessionId = ++_searchSessionId;
    await _executeSearch(trimmed, sessionId: sessionId, userId: userId);
  }

  Future<void> _executeSearch(String query, {required int sessionId, String? userId}) async {
    if (sessionId != _searchSessionId) return;
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch shops and products in parallel (fast!)
      final results = await Future.wait([
        _fetchAllShops(),
        _searchProducts(query),
      ]);

      if (sessionId != _searchSessionId) return;

      final allShops = results[0] as List<Shop>;
      final products = results[1] as List<ApiProduct>;

      // Seed all retrieved shops to cache
      seedShopCache(allShops);
      _productResults = products;

      // 2. Identify shops that sell the matched products
      final Map<String, List<String>> matchedShops = {};
      final Set<String> missingShopIds = {};

      for (final p in products) {
        if (p.shopId.isNotEmpty) {
          matchedShops.putIfAbsent(p.shopId, () => []);
          if (!matchedShops[p.shopId]!.contains(p.name)) {
            matchedShops[p.shopId]!.add(p.name);
          }
          if (!_shopCache.containsKey(p.shopId)) {
            missingShopIds.add(p.shopId);
          }
        }
      }

      _shopMatchedProductNames = matchedShops;

      // 3. Instant placeholder for missing shops & non-blocking background fetch
      for (final shopId in missingShopIds) {
        _shopCache.putIfAbsent(
          shopId,
          () => Shop(
            id: shopId,
            name: 'Shop #${shopId.length > 6 ? shopId.substring(0, 6) : shopId}',
            categories: const [],
            visibleOnline: true,
          ),
        );
        _resolveMissingShop(shopId);
      }

      // 4. Identify direct shop matches
      final cleanQ = query.trim().toLowerCase();
      final directShopMatches = allShops.where((s) {
        final nameMatches = s.name.toLowerCase().contains(cleanQ);
        final tagMatches = s.tagline?.toLowerCase().contains(cleanQ) ?? false;
        final descMatches = s.description?.toLowerCase().contains(cleanQ) ?? false;
        final catMatches = s.categories.any((c) => c.toLowerCase().contains(cleanQ));
        final cityMatches = s.city.toLowerCase().contains(cleanQ);
        final addressMatches = s.displayAddress.toLowerCase().contains(cleanQ);

        return nameMatches || tagMatches || descMatches || catMatches || cityMatches || addressMatches;
      }).toList();

      // 5. Merge direct shop matches + product-term matched shops
      final Map<String, Shop> combinedShops = {};

      // Direct matches first
      for (final shop in directShopMatches) {
        combinedShops[shop.id] = shop;
      }

      // Add shops identified via matched products
      for (final shopId in matchedShops.keys) {
        if (!combinedShops.containsKey(shopId)) {
          final resolvedShop = _shopCache[shopId];
          if (resolvedShop != null) {
            combinedShops[shopId] = resolvedShop;
          }
        }
      }

      if (sessionId == _searchSessionId) {
        _shopResults = combinedShops.values.toList();
      }

      // 6. Save search history (fire-and-forget, non-blocking)
      if (userId != null && query.isNotEmpty) {
        _service.addSearchHistory(userId, query).catchError((_) {});
      }
    } catch (e) {
      if (sessionId == _searchSessionId) {
        _error = 'Search failed. Try again.';
      }
    } finally {
      if (sessionId == _searchSessionId) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> _resolveMissingShop(String shopId) async {
    try {
      final body = await _service.fetchShopById(shopId).timeout(const Duration(seconds: 3));
      final shop = _parseSingleShop(body);
      if (shop != null && shop.id.isNotEmpty) {
        _shopCache[shop.id] = shop;
        final idx = _shopResults.indexWhere((s) => s.id == shop.id);
        if (idx != -1) {
          _shopResults[idx] = shop;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<List<Shop>> _fetchAllShops() async {
    // If shop cache already has items, return immediately without network overhead
    if (_shopCache.isNotEmpty) {
      return _shopCache.values.toList();
    }
    try {
      final body = await _service.fetchShops(
        latitude: 0.0,
        longitude: 0.0,
        limit: 100,
        offset: 1,
      ).timeout(const Duration(seconds: 3));
      final list = _parseShopList(body);
      seedShopCache(list);
      return list;
    } catch (_) {
      return _shopCache.values.toList();
    }
  }

  Future<List<ApiProduct>> _searchProducts(String query) async {
    try {
      final body = await _service.fetchProducts(query: query, limit: 30, offset: 1)
          .timeout(const Duration(seconds: 4));
      return _parseProductList(body);
    } catch (_) {
      return [];
    }
  }

  // ── Search History ──────────────────────────────────────────────

  Future<void> loadSearchHistory(String userId) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _recentSearches = await _service.getSearchHistory(userId, limit: 20);
    } catch (_) {
      // Non-critical
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> clearSearchHistory(String? userId) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _service.clearSearchHistory(userId);
      }
      _recentSearches = [];
      notifyListeners();
    } catch (_) {
      _error = 'Failed to clear search history.';
      notifyListeners();
    }
  }

  void removeRecentSearchLocally(String term) {
    _recentSearches.removeWhere((e) => e.searchTerm.toLowerCase() == term.toLowerCase());
    notifyListeners();
  }

  // ── Parsers ─────────────────────────────────────────────────────

  List<Shop> _parseShopList(dynamic body) {
    List<dynamic>? list;
    if (body is List) {
      list = body;
    } else if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['datas'];
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = [data];
      }
    }

    if (list != null) {
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => Shop.fromJson(e))
          .where((s) => s.visibleOnline)
          .toList();
    }
    return [];
  }

  Shop? _parseSingleShop(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return Shop.fromJson(data);
      if (body.containsKey('id')) return Shop.fromJson(body);
    }
    return null;
  }

  List<ApiProduct> _parseProductList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => ApiProduct.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.isActive || p.visibleOnline)
          .toList();
    }
    if (body is Map) {
      final data = body['data'] ?? body['datas'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ApiProduct.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.isActive || p.visibleOnline)
            .toList();
      }
      if (data is Map) {
        final p = ApiProduct.fromJson(Map<String, dynamic>.from(data));
        return (p.isActive || p.visibleOnline) ? [p] : [];
      }
    }
    return [];
  }

  void clearResults() {
    _searchSessionId++;
    _debounce?.cancel();
    _query = '';
    _shopResults = [];
    _productResults = [];
    _shopMatchedProductNames = {};
    _isSearching = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _debounce?.cancel();
    _recentSearches = [];
    _shopResults = [];
    _productResults = [];
    _shopMatchedProductNames = {};
    _isSearching = false;
    _isLoadingHistory = false;
    _error = null;
    _query = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
