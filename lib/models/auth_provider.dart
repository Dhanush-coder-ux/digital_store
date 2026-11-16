// lib/models/auth_provider.dart
//
// Provides persistent customer identification for the digital store app.
//

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String _userId = 'guest_customer';
  String? get userId => _userId;
  String? get shopId => null;
  bool get isAuthenticated => true;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('api_cart_customer_id') ?? prefs.getString('digital_store_user_id');
      if (saved != null && saved.isNotEmpty) {
        _userId = saved;
        notifyListeners();
      } else {
        final newId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('digital_store_user_id', newId);
        _userId = newId;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }
}
