// lib/models/profile_provider.dart
//
// Manages user profile state: fetch, create, update profile and addresses.
// Integrates with DigitalStore User Profile API.
//

import 'package:flutter/foundation.dart';
import '../services/digitalstore_service.dart';
import '../core/models/user_profile_model.dart';
import '../core/models/address_model.dart';
import '../core/network/api_exceptions.dart';

class ProfileProvider extends ChangeNotifier {
  final DigitalStoreService _service;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  ProfileProvider(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetched => _hasFetched;
  String get userName => _profile?.name ?? '';
  List<AddressModel> get addresses => _profile?.addresses ?? [];
  AddressModel? get defaultAddress => _profile?.defaultAddress;

  // ── Fetch Profile ───────────────────────────────────────────────

  Future<void> fetchProfile(String userId, {bool force = false}) async {
    if (_hasFetched && !force && _error == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.getProfile(userId);
      _hasFetched = true;
    } on NotFoundException {
      // Profile doesn't exist yet — will be created on first update
      _profile = null;
      _hasFetched = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create Profile ──────────────────────────────────────────────

  Future<bool> createProfile(String userId, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = UserProfile(userId: userId, name: name);
      await _service.createProfile(profile);
      _profile = profile;
      _hasFetched = true;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to create profile.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Profile ──────────────────────────────────────────────

  Future<bool> updateName(String userId, String name) async {
    _error = null;
    try {
      await _service.updateProfile(userId, UpdateUserProfile(name: name));
      _profile = _profile?.copyWith(name: name) ??
          UserProfile(userId: userId, name: name);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update name.';
      notifyListeners();
      return false;
    }
  }

  // ── Address Management ──────────────────────────────────────────

  Future<bool> addAddress(String userId, AddressModel address) async {
    if (_profile == null) return false;
    _error = null;

    try {
      final updatedAddresses = [..._profile!.addresses, address];
      await _service.updateProfile(
        userId,
        UpdateUserProfile(addresses: updatedAddresses),
      );
      _profile = _profile!.copyWith(addresses: updatedAddresses);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add address.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(
    String userId,
    String addressId,
    AddressModel updated,
  ) async {
    if (_profile == null) return false;
    _error = null;

    try {
      final updatedAddresses = _profile!.addresses.map((a) {
        if (a.addressId == addressId) return updated;
        return a;
      }).toList();

      await _service.updateProfile(
        userId,
        UpdateUserProfile(addresses: updatedAddresses),
      );
      _profile = _profile!.copyWith(addresses: updatedAddresses);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update address.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAddress(String userId, String addressId) async {
    if (_profile == null) return false;
    _error = null;

    try {
      final updatedAddresses = _profile!.addresses
          .where((a) => a.addressId != addressId)
          .toList();

      await _service.updateProfile(
        userId,
        UpdateUserProfile(addresses: updatedAddresses),
      );
      _profile = _profile!.copyWith(addresses: updatedAddresses);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to remove address.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(String userId, String addressId) async {
    if (_profile == null) return false;
    _error = null;

    try {
      final updatedAddresses = _profile!.addresses.map((a) {
        return a.copyWith(isDefault: a.addressId == addressId);
      }).toList();

      await _service.updateProfile(
        userId,
        UpdateUserProfile(addresses: updatedAddresses),
      );
      _profile = _profile!.copyWith(addresses: updatedAddresses);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to set default address.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _profile = null;
    _hasFetched = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
