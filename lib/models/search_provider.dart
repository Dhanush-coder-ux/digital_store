// lib/models/search_provider.dart
//
// Manages search state: product/shop search, search history,
// debounced queries, and recent searches from DigitalStore API.
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
  bool _isSearching = false;
  bool _isLoadingHistory = false;
  String? _error;
  String _query = '';
  Timer? _debounce;

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

  // ── Search (Debounced) ──────────────────────────────────────────

  void search(String query, {String? userId}) {
    _query = query;
    _debounce?.cancel();

    if (query.isEmpty) {
      _shopResults = [];
      _productResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(query, userId: userId);
    });
  }

  Future<void> executeSearchNow({String? userId}) async {
    if (_query.isEmpty) return;
    _debounce?.cancel();
    await _executeSearch(_query, userId: userId);
  }

  Future<void> _executeSearch(String query, {String? userId}) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      // Search shops and products in parallel
      final results = await Future.wait([
        _searchShops(query),
        _searchProducts(query),
      ]);

      _shopResults = results[0] as List<Shop>;
      _productResults = results[1] as List<ApiProduct>;

      // Save search history if user is logged in
      if (userId != null && query.isNotEmpty) {
        try {
          await _service.addSearchHistory(userId, query);
        } catch (_) {
          // Non-critical
        }
      }
    } catch (e) {
      _error = 'Search failed. Try again.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<List<Shop>> _searchShops(String query) async {
    try {
      final body = await _service.fetchShops(query: query, limit: 20, offset: 1);
      return _parseShopList(body);
    } catch (_) {
      return [];
    }
  }

  Future<List<ApiProduct>> _searchProducts(String query) async {
    try {
      final body = await _service.fetchProducts(query: query, limit: 20, offset: 1);
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

  Future<void> clearSearchHistory(String userId) async {
    try {
      await _service.clearSearchHistory(userId);
      _recentSearches = [];
      notifyListeners();
    } catch (_) {
      _error = 'Failed to clear search history.';
      notifyListeners();
    }
  }

  // ── Parsers ─────────────────────────────────────────────────────

  List<Shop> _parseShopList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => Shop.fromJson(e))
          .where((s) => s.visibleOnline)
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Shop.fromJson(e))
            .where((s) => s.visibleOnline)
            .toList();
      }
    }
    return [];
  }

  List<ApiProduct> _parseProductList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map((e) => ApiProduct.fromJson(e))
          .where((p) => p.isActive)
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => ApiProduct.fromJson(e))
            .where((p) => p.isActive)
            .toList();
      }
    }
    return [];
  }

  void clearResults() {
    _query = '';
    _shopResults = [];
    _productResults = [];
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
