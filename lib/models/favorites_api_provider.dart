// lib/models/favorites_api_provider.dart
//
// Backend-synced favorites provider.
// Manages favorite product IDs and shop IDs via DigitalStore API.
// Provides optimistic UI updates with backend sync.
//

import 'package:flutter/foundation.dart';
import '../services/digitalstore_service.dart';

class FavoritesApiProvider extends ChangeNotifier {
  final DigitalStoreService _service;

  final Set<String> _favoriteProductIds = {};
  final Set<String> _favoriteShopIds = {};
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  FavoritesApiProvider(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  Set<String> get favoriteProductIds => _favoriteProductIds;
  Set<String> get favoriteShopIds => _favoriteShopIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetched => _hasFetched;

  bool isProductFavorited(String productId) => _favoriteProductIds.contains(productId);
  bool isShopFavorited(String shopId) => _favoriteShopIds.contains(shopId);

  // ── Fetch All Favorites ─────────────────────────────────────────

  Future<void> fetchFavorites(String userId, {bool force = false}) async {
    if (_hasFetched && !force && _error == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await _service.getFavoriteProducts(userId, limit: 100);
      final shops = await _service.getFavoriteShops(userId, limit: 100);

      _favoriteProductIds.clear();
      _favoriteProductIds.addAll(products);

      _favoriteShopIds.clear();
      _favoriteShopIds.addAll(shops);

      _hasFetched = true;
    } catch (e) {
      _error = 'Failed to load favorites.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Toggle Product Favorite ─────────────────────────────────────

  Future<void> toggleProductFavorite(String userId, String productId) async {
    final wasFavorited = _favoriteProductIds.contains(productId);

    // Optimistic update
    if (wasFavorited) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      if (wasFavorited) {
        await _service.unfavoriteProduct(userId, productId);
      } else {
        await _service.favoriteProduct(userId, productId);
      }
    } catch (e) {
      // Rollback on failure
      if (wasFavorited) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }
      _error = wasFavorited ? 'Failed to unfavorite product.' : 'Failed to favorite product.';
      notifyListeners();
    }
  }

  // ── Toggle Shop Favorite ────────────────────────────────────────

  Future<void> toggleShopFavorite(String userId, String shopId) async {
    final wasFavorited = _favoriteShopIds.contains(shopId);

    // Optimistic update
    if (wasFavorited) {
      _favoriteShopIds.remove(shopId);
    } else {
      _favoriteShopIds.add(shopId);
    }
    notifyListeners();

    try {
      if (wasFavorited) {
        await _service.unfavoriteShop(userId, shopId);
      } else {
        await _service.favoriteShop(userId, shopId);
      }
    } catch (e) {
      // Rollback on failure
      if (wasFavorited) {
        _favoriteShopIds.add(shopId);
      } else {
        _favoriteShopIds.remove(shopId);
      }
      _error = wasFavorited ? 'Failed to unfavorite shop.' : 'Failed to favorite shop.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _favoriteProductIds.clear();
    _favoriteShopIds.clear();
    _hasFetched = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
