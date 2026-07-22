// lib/models/review_provider.dart
//
// Manages shop review state: submit, fetch shop reviews, fetch user reviews.
// Integrates with DigitalStore Reviews API.
//

import 'package:flutter/foundation.dart';
import '../services/digitalstore_service.dart';
import '../core/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  final DigitalStoreService _service;

  // Reviews keyed by shop_id for caching
  final Map<String, List<ShopReview>> _shopReviews = {};
  final Map<String, bool> _loadingByShop = {};
  List<ShopReview> _userReviews = [];
  bool _isSubmitting = false;
  bool _isLoadingUserReviews = false;
  String? _error;

  ReviewProvider(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  List<ShopReview> reviewsForShop(String shopId) => _shopReviews[shopId] ?? [];
  bool isLoadingShop(String shopId) => _loadingByShop[shopId] ?? false;
  List<ShopReview> get userReviews => _userReviews;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingUserReviews => _isLoadingUserReviews;
  String? get error => _error;

  double averageRatingForShop(String shopId) {
    final reviews = _shopReviews[shopId];
    if (reviews == null || reviews.isEmpty) return 0;
    final total = reviews.fold(0.0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  int reviewCountForShop(String shopId) => _shopReviews[shopId]?.length ?? 0;

  // ── Submit Review ───────────────────────────────────────────────

  Future<bool> submitReview(ShopReview review) async {
    final validation = review.validate();
    if (validation != null) {
      _error = validation;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitReview(review);
      // Update local cache
      _shopReviews[review.shopId] ??= [];
      // Replace existing review by same user, or add new
      final idx = _shopReviews[review.shopId]!
          .indexWhere((r) => r.userId == review.userId);
      if (idx >= 0) {
        _shopReviews[review.shopId]![idx] = review;
      } else {
        _shopReviews[review.shopId]!.insert(0, review);
      }
      return true;
    } catch (e) {
      _error = 'Failed to submit review.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── Fetch Shop Reviews ──────────────────────────────────────────

  Future<void> fetchShopReviews(
    String shopId, {
    int limit = 20,
    int offset = 0,
    bool force = false,
  }) async {
    if (!force && _shopReviews.containsKey(shopId)) return;

    _loadingByShop[shopId] = true;
    notifyListeners();

    try {
      final reviews = await _service.getShopReviews(
        shopId, limit: limit, offset: offset,
      );
      _shopReviews[shopId] = reviews;
    } catch (e) {
      _error = 'Failed to load reviews.';
    } finally {
      _loadingByShop[shopId] = false;
      notifyListeners();
    }
  }

  // ── Fetch User Reviews ──────────────────────────────────────────

  Future<void> fetchUserReviews(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    _isLoadingUserReviews = true;
    notifyListeners();

    try {
      _userReviews = await _service.getUserReviews(
        userId, limit: limit, offset: offset,
      );
    } catch (e) {
      _error = 'Failed to load your reviews.';
    } finally {
      _isLoadingUserReviews = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _shopReviews.clear();
    _loadingByShop.clear();
    _userReviews = [];
    _isSubmitting = false;
    _isLoadingUserReviews = false;
    _error = null;
    notifyListeners();
  }
}
