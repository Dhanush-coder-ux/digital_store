// lib/models/auth_provider.dart
//
// Authentication has been removed from this customer-facing app.
// This stub is kept only to prevent import errors in files that haven't
// been cleaned up yet. It will be fully removed in a future cleanup pass.
//

import 'package:flutter/foundation.dart';

/// No-op auth provider — authentication has been removed.
/// userId is always null (anonymous customer).
class AuthProvider extends ChangeNotifier {
  String? get userId => null;
  String? get shopId => null;
  bool get isAuthenticated => true; // Always true — no auth needed
}
