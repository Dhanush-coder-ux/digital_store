// lib/models/shop_provider.dart
//
// Fetches and manages the list of shops from the ShopEmp service.
//

import 'package:flutter/foundation.dart';
import '../services/shop_service.dart';
import '../models/shop_model.dart';
import '../core/network/api_exceptions.dart';
import '../services/location_service.dart';

class ShopProvider extends ChangeNotifier {
  final ShopService _service;
  final LocationService _locationService = LocationService();

  List<Shop> _shops = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;
  
  String _selectedDeliveryType = 'INSTANT';

  ShopProvider(this._service);

  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetched => _hasFetched;
  bool get hasShops => _shops.isNotEmpty;
  ShopService get service => _service;
  String get selectedDeliveryType => _selectedDeliveryType;

  void setDeliveryType(String type, {double? lat, double? lng}) {
    if (_selectedDeliveryType != type) {
      _selectedDeliveryType = type;
      fetchAllShops(force: true, lat: lat, lng: lng);
    }
  }

  // ── Fetch ─────────────────────────────────────────────────────────

  Future<void> fetchAllShops({bool force = false, double? lat, double? lng, String? deliveryType}) async {
    if (_hasFetched && !force && _error == null) return; // Skip if cached

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      double? finalLat = lat;
      double? finalLng = lng;

      if (finalLat == null || finalLng == null) {
        print('ShopProvider: Fetching current location...');
        final position = await _locationService.getCurrentLocation();
        finalLat = position.latitude;
        finalLng = position.longitude;
      }

      print('ShopProvider: Fetching all shops...');
      _shops = await _service.fetchAllShops(lat: finalLat, lng: finalLng, deliveryType: deliveryType ?? _selectedDeliveryType);
      print('ShopProvider: Successfully fetched ${_shops.length} shops');
      _hasFetched = true;
    } on LocationPermissionException catch (e) {
      print('ShopProvider: LocationPermissionException - ${e.message}');
      _error = e.message;
      _shops = [];
    } on LocationServiceDisabledException catch (e) {
      print('ShopProvider: LocationServiceDisabledException - ${e.message}');
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
