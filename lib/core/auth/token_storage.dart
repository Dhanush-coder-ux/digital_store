// lib/core/auth/token_storage.dart
//
// Secure token persistence using SharedPreferences.
// Stores JWT access/refresh tokens, user_id, and session metadata.
// Provides JWT decoding (without signature verification) for extracting claims.
//

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessTokenKey = 'hl_access_token';
  static const _refreshTokenKey = 'hl_refresh_token';
  static const _userIdKey = 'hl_user_id';
  static const _emailKey = 'hl_email';
  static const _mobileKey = 'hl_mobile';
  static const _tokenVersionKey = 'hl_token_version';
  static const _expiresAtKey = 'hl_expires_at';

  // ── Save Tokens ─────────────────────────────────────────────────────

  /// Saves both tokens and extracts user info from the access token JWT.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);

    // Extract claims from access token
    final claims = decodeJwt(accessToken);
    if (claims != null) {
      final userId = claims['user_id']?.toString() ?? claims['sub']?.toString();
      if (userId != null) await prefs.setString(_userIdKey, userId);

      final email = claims['email']?.toString();
      if (email != null) await prefs.setString(_emailKey, email);

      final mobile = claims['mobilenumber']?.toString();
      if (mobile != null) await prefs.setString(_mobileKey, mobile);

      final version = claims['version']?.toString();
      if (version != null) await prefs.setString(_tokenVersionKey, version);

      // Calculate expiry time
      final exp = claims['exp'];
      if (exp is int) {
        await prefs.setInt(_expiresAtKey, exp);
      } else if (expiresIn != null) {
        final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        await prefs.setInt(_expiresAtKey, expiresAt);
      }
    }
  }

  /// Saves only the access token (after refresh).
  Future<void> saveAccessToken(String accessToken, {int? expiresIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    final claims = decodeJwt(accessToken);
    if (claims != null) {
      final exp = claims['exp'];
      if (exp is int) {
        await prefs.setInt(_expiresAtKey, exp);
      } else if (expiresIn != null) {
        final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        await prefs.setInt(_expiresAtKey, expiresAt);
      }
    }
  }

  // ── Read Tokens ─────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  Future<String?> getTokenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenVersionKey);
  }

  // ── Token Validation ────────────────────────────────────────────────

  /// Returns true if the stored access token exists and has not expired.
  Future<bool> hasValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token == null || token.isEmpty) return false;

    final expiresAt = prefs.getInt(_expiresAtKey);
    if (expiresAt == null) return true; // No expiry info — assume valid

    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Consider expired if within 60 seconds of expiry (buffer for network latency)
    return nowEpoch < (expiresAt - 60);
  }

  /// Returns true if we have a refresh token stored.
  Future<bool> hasRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Returns true if there are any stored credentials (tokens + userId).
  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_accessTokenKey) && prefs.containsKey(_userIdKey);
  }

  // ── Clear Tokens ────────────────────────────────────────────────────

  /// Clears all stored auth data. Called on logout.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_tokenVersionKey);
    await prefs.remove(_expiresAtKey);
  }

  // ── JWT Decode Helper ───────────────────────────────────────────────

  /// Decodes a JWT token's payload WITHOUT verifying the signature.
  /// Returns the claims map, or null if decoding fails.
  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64Url decode the payload (second segment)
      String payload = parts[1];
      // Add padding if necessary
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
