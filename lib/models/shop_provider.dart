// lib/models/shop_provider.dart
//
// Fetches and manages the list of shops from the ShopEmp service.
//

import 'package:flutter/foundation.dart';
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../models/shop_model.dart';

class ShopProvider extends ChangeNotifier {
  List<Shop> _shops = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetched => _hasFetched;
  bool get hasShops => _shops.isNotEmpty;

  // ── Fetch ─────────────────────────────────────────────────────────

  Future<void> fetchAllShops({bool force = false}) async {
    if (_hasFetched && !force && _error == null) return; // Skip if cached

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('ShopProvider: Fetching all shops...');
      const service = ShopService();
      _shops = await service.fetchAllShops();
      print('ShopProvider: Successfully fetched ${_shops.length} shops');
      _hasFetched = true;
    } on AuthException catch (e) {
      print('ShopProvider: AuthException - ${e.message}');
      _error = e.message;
      _shops = [];
    } on ApiException catch (e) {
      print('ShopProvider: ApiException - ${e.message}');
      _error = e.message;
      _shops = [];
    } catch (e, stacktrace) {
      print('ShopProvider: General Exception - $e\n$stacktrace');
      _error = 'Could not connect to server. Check your network and API config.';
      _shops = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────

  Future<void> refresh() => fetchAllShops(force: true);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _shops = [];
    _hasFetched = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
