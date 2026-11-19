// lib/core/auth/auth_provider.dart
//
// Full authentication state management.
// Handles login via browser, deep link callback, token exchange,
// session restoration, auto-refresh, and logout.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // Polling state
  String? _currentTempId;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int maxPollAttempts = 60; // 60 attempts * 5 sec = 300 sec (5 minutes)
  static const Duration pollInterval = Duration(seconds: 5);

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
  String? get currentTempId => _currentTempId;
  bool get hasPendingLogin => _currentTempId != null && _currentTempId!.isNotEmpty;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isPolling => _pollTimer != null && _pollTimer!.isActive;
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
      // Also restore any active tempId from storage if not in memory
      _currentTempId ??= await _tokenStorage.getTempId();

      final hasSession = await _tokenStorage.hasStoredSession();
      if (!hasSession) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        // If we have a pending tempId from a previous launch, start polling
        if (_currentTempId != null && _currentTempId!.isNotEmpty && _pollTimer == null) {
          startPolling(_currentTempId!);
        }
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
  /// Also starts background polling for the generated tempId every 5 seconds.
  /// Returns the URL string to be opened via url_launcher.
  Future<String?> getLoginUrl() async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.getLoginUrl(
        service: 'HYPERLOCAL_APP',
        version: '1',
      );
      _pendingLoginUrl = response.loginUrl;
      _currentTempId = response.tempId;
      await _tokenStorage.saveTempId(_currentTempId);
      _state = AuthState.unauthenticated;
      notifyListeners();

      // Automatically start 5-second polling if tempId is present
      if (_currentTempId != null && _currentTempId!.isNotEmpty) {
        startPolling(_currentTempId!);
      }

      return _pendingLoginUrl;
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] getLoginUrl error: $e');
      _error = 'Could not connect to authentication service: $e';
      _state = AuthState.error;
      notifyListeners();
      return null;
    }
  }

  /// Starts polling the backend every 5 seconds using tempId.
  /// When authentication completes in the external browser, automatically saves
  /// tokens and signs the user in.
  void startPolling(String tempId) {
    stopPolling();
    _currentTempId = tempId;
    _pollAttempts = 0;

    if (kDebugMode) {
      print('[AuthProvider] Starting auth polling for tempId: $tempId (interval: 5s, timeout: 5m)');
    }

    _pollTimer = Timer.periodic(pollInterval, (timer) async {
      // If already authenticated, stop polling
      if (_state == AuthState.authenticated) {
        timer.cancel();
        _pollTimer = null;
        return;
      }

      _pollAttempts++;
      if (_pollAttempts >= maxPollAttempts) {
        if (kDebugMode) print('[AuthProvider] Auth polling expired after 5 minutes.');
        timer.cancel();
        _pollTimer = null;
        return;
      }

      try {
        final pollRes = await _authService.pollAuthStatus(tempId);
        if (kDebugMode) print('[AuthProvider] Poll tick #$_pollAttempts for $tempId: status=${pollRes.status}');

        if (pollRes.isAuthenticated && pollRes.tokenResponse != null) {
          timer.cancel();
          _pollTimer = null;
          final tokens = pollRes.tokenResponse!;

          await _tokenStorage.saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken ?? '',
            expiresIn: tokens.expiresIn,
          );
          await _tokenStorage.saveTempId(null);

          await _loadUserInfo();
          _state = AuthState.authenticated;
          _pendingLoginUrl = null;
          _currentTempId = null;
          notifyListeners();
          if (kDebugMode) print('[AuthProvider] Polling authentication successful! Automatically logged in.');
        } else if (pollRes.isExpired) {
          timer.cancel();
          _pollTimer = null;
          _currentTempId = null;
          await _tokenStorage.saveTempId(null);
          notifyListeners();
          if (kDebugMode) print('[AuthProvider] Auth polling session expired on backend.');
        }
      } catch (e) {
        if (kDebugMode) print('[AuthProvider] Polling tick error: $e');
      }
    });
  }

  /// Stops and cancels the active polling timer.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually checks auth status immediately (e.g. when user clicks 'Tap to verify' / 'Refresh').
  /// If authentication is verified, logs in immediately.
  /// If still pending and polling had stopped, restarts polling.
  Future<bool> checkAuthStatusNow() async {
    String? tempId = _currentTempId;
    if (tempId == null || tempId.isEmpty) {
      tempId = await _tokenStorage.getTempId();
      _currentTempId = tempId;
    }
    if (tempId == null || tempId.isEmpty) {
      return false;
    }

    try {
      final pollRes = await _authService.pollAuthStatus(tempId);
      if (kDebugMode) {
        print('[AuthProvider] Manual status check for $tempId: status=${pollRes.status}');
      }

      if (pollRes.isAuthenticated && pollRes.tokenResponse != null) {
        stopPolling();
        final tokens = pollRes.tokenResponse!;

        await _tokenStorage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken ?? '',
          expiresIn: tokens.expiresIn,
        );
        await _tokenStorage.saveTempId(null);

        await _loadUserInfo();
        _state = AuthState.authenticated;
        _pendingLoginUrl = null;
        _currentTempId = null;
        notifyListeners();
        return true;
      } else if (pollRes.isExpired) {
        stopPolling();
        _currentTempId = null;
        await _tokenStorage.saveTempId(null);
        notifyListeners();
      } else {
        // If not authenticated and polling timer had stopped, restart polling
        if (_pollTimer == null && !pollRes.isExpired) {
          startPolling(tempId);
        }
      }
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] Manual status check error: $e');
    }
    return false;
  }

  /// Step 2: Called when the deep link callback is received with a token_id.
  /// Exchanges the token_id for JWT tokens and completes login.
  Future<bool> handleAuthCallback(String tokenId) async {
    // If polling has already authenticated the user, stop polling and return success
    if (_state == AuthState.authenticated) {
      stopPolling();
      return true;
    }

    stopPolling();
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final tokenResponse = await _authService.exchangeToken(
        tokenId,
        service: 'HYPERLOCAL_APP',
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
      await _tokenStorage.saveTempId(null);

      await _loadUserInfo();
      _state = AuthState.authenticated;
      _pendingLoginUrl = null;
      _currentTempId = null;
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
    stopPolling();
    _currentTempId = null;
    await _tokenStorage.saveTempId(null);
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
    _currentTempId = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ── Account Deletion with OTP Verification ─────────────────────────

  /// Step 1: Requests a 6-digit verification code sent to the user's Gmail.
  Future<Map<String, dynamic>> requestDeleteAccountOtp() async {
    if (_userId == null && (_email == null || _email!.isEmpty)) {
      throw const AuthException('No active user logged in.');
    }
    final res = await _authService.requestDeleteAccountOtp(
      userId: _userId ?? '',
      email: _email,
    );
    if (res['user_id'] != null) {
      _userId = res['user_id'].toString();
    }
    return res;
  }

  /// Step 2: Verifies the entered OTP, soft-deletes the account, and terminates session.
  Future<bool> verifyDeleteAccountOtp(String otp) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authService.verifyDeleteAccountOtp(
        userId: _userId ?? '',
        email: _email,
        otp: otp.trim(),
      );
      await logout();
      return true;
    } catch (e) {
      _state = AuthState.authenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Permanently deletes the user account, clears tokens, and resets session state.
  Future<bool> deleteAccount({Future<void> Function(String userId)? onServerDelete}) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      if (_userId != null && onServerDelete != null) {
        await onServerDelete(_userId!);
      }
    } catch (e) {
      if (kDebugMode) print('[AuthProvider] Account server delete notice: $e');
    }

    await logout();
    return true;
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
