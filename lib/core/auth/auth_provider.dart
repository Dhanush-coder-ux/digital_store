// lib/core/auth/auth_provider.dart
//
// Full authentication state management.
// Handles login via browser, deep link callback, token exchange,
// session restoration, auto-refresh, and logout.
//

import 'package:flutter/foundation.dart';
import '../../services/api_config.dart';
import 'auth_service.dart';
import 'token_storage.dart';
import '../network/api_client.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  ApiClient? _apiClient;

  AuthState _state = AuthState.initial;
  String? _userId;
  String? _email;
  String? _mobile;
  String? _error;
  String? _pendingLoginUrl;

  AuthProvider({
    AuthService? authService,
    TokenStorage? tokenStorage,
  })  : _authService = authService ?? const AuthService(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  // ── Getters ─────────────────────────────────────────────────────────

  AuthState get state => _state;
  String? get userId => _userId;
  String? get email => _email;
  String? get mobile => _mobile;
  String? get error => _error;
  String? get pendingLoginUrl => _pendingLoginUrl;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  TokenStorage get tokenStorage => _tokenStorage;

  // ── Initialize ──────────────────────────────────────────────────────

  /// Call once on app startup. Wires up the ApiClient for auto-refresh.
  void initialize(ApiClient apiClient) {
    _apiClient = apiClient;
    _apiClient!.setTokenRefresher(_refreshAccessToken);
    _apiClient!.setSessionExpiredCallback(_handleSessionExpired);
  }

  // ── Check Session (Splash) ──────────────────────────────────────────

  /// Checks for stored tokens and restores the session if valid.
  /// Called from the splash screen on app startup.
  Future<void> checkSession() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final hasSession = await _tokenStorage.hasStoredSession();
      if (!hasSession) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      // Check if access token is still valid
      final isValid = await _tokenStorage.hasValidAccessToken();
      if (isValid) {
        await _loadUserInfo();
        _state = AuthState.authenticated;
        notifyListeners();
        return;
      }

      // Access token expired — try refreshing
      final hasRefresh = await _tokenStorage.hasRefreshToken();
      if (hasRefresh) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          await _loadUserInfo();
          _state = AuthState.authenticated;
          notifyListeners();
          return;
        }
      }

      // No valid session
      await _tokenStorage.clearAll();
      _state = AuthState.unauthenticated;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] checkSession error: $e');
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  // ── Login Flow ──────────────────────────────────────────────────────

  /// Step 1: Fetches the login URL to open in the browser.
  /// Returns the URL string to be opened via url_launcher.
  Future<String?> getLoginUrl() async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.getLoginUrl(
        service: 'HYPERLOCAL-APP',
        version: '1',
      );
      _pendingLoginUrl = response.loginUrl;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return _pendingLoginUrl;
    } catch (e) {
      _error = 'Could not connect to authentication service.';
      _state = AuthState.error;
      notifyListeners();
      return null;
    }
  }

  /// Step 2: Called when the deep link callback is received with a token_id.
  /// Exchanges the token_id for JWT tokens and completes login.
  Future<bool> handleAuthCallback(String tokenId) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final tokenResponse = await _authService.exchangeToken(
        tokenId,
        service: 'HYPERLOCAL-APP',
        version: '1',
      );

      if (tokenResponse.accessToken.isEmpty) {
        throw Exception('Empty access token received');
      }

      // Save tokens
      await _tokenStorage.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken ?? '',
        expiresIn: tokenResponse.expiresIn,
      );

      await _loadUserInfo();
      _state = AuthState.authenticated;
      _pendingLoginUrl = null;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] handleAuthCallback error: $e');
      _error = 'Auth Error: ${e.toString()}';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ── Token Refresh ─────────────────────────────────────────────────

  /// Refreshes the access token using the stored refresh token.
  /// Returns the new access token, or null if refresh fails.
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final version = await _tokenStorage.getTokenVersion() ?? '1';

      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await _authService.refreshToken(
        refreshToken: refreshToken,
        version: version,
      );

      await _tokenStorage.saveAccessToken(
        response.accessToken,
        expiresIn: response.expiresIn,
      );

      return response.accessToken;
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] Token refresh failed: $e');
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────

  /// Logs out the user: revokes tokens, clears storage, resets state.
  Future<void> logout() async {
    try {
      // Best-effort revoke both tokens
      final accessToken = await _tokenStorage.getAccessToken();
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (accessToken != null) {
        await _authService.revokeToken(accessToken);
      }
      if (refreshToken != null) {
        await _authService.revokeToken(refreshToken);
      }
    } catch (_) {
      // Revocation failure is non-critical
    }

    await _tokenStorage.clearAll();
    _userId = null;
    _email = null;
    _mobile = null;
    _error = null;
    _pendingLoginUrl = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ── Session Expired Handler ────────────────────────────────────────

  void _handleSessionExpired() {
    _userId = null;
    _email = null;
    _mobile = null;
    _state = AuthState.unauthenticated;
    _error = 'Session expired. Please log in again.';
    _tokenStorage.clearAll();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<void> _loadUserInfo() async {
    _userId = await _tokenStorage.getUserId();
    _email = await _tokenStorage.getEmail();
    _mobile = await _tokenStorage.getMobile();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
