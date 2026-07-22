// lib/core/auth/auth_service.dart
//
// Authentication HTTP service.
// Handles login URL retrieval, token exchange, refresh, and revocation.
// Maps to backend auth routes: GET /api/auth/login-url, GET /api/auth/callback,
// POST /api/auth/refresh, POST /api/auth/revoke.
//

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';

/// Response from the token exchange or refresh endpoint.
class AuthTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresIn = 3600,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: json['expires_in'] is int
          ? json['expires_in']
          : int.tryParse(json['expires_in']?.toString() ?? '') ?? 3600,
    );
  }
}

/// Login URL response containing OAuth provider URLs.
class LoginUrlResponse {
  final Map<String, dynamic> rawData;

  const LoginUrlResponse({required this.rawData});

  /// The primary login URL to open in the browser.
  /// The Debugger Auth service typically returns a map with auth URLs.
  String? get loginUrl {
    // Try common keys
    if (rawData.containsKey('url')) return rawData['url']?.toString();
    if (rawData.containsKey('login_url')) return rawData['login_url']?.toString();
    if (rawData.containsKey('auth_url')) return rawData['auth_url']?.toString();
    // If data contains providers, pick the first URL
    if (rawData.containsKey('data') && rawData['data'] is Map) {
      final data = rawData['data'] as Map;
      for (final v in data.values) {
        if (v is String && (v.startsWith('http://') || v.startsWith('https://'))) {
          return v;
        }
      }
    }
    // Fallback: iterate top-level values for a URL
    for (final v in rawData.values) {
      if (v is String && (v.startsWith('http://') || v.startsWith('https://'))) {
        return v;
      }
    }
    return null;
  }
}

class AuthService {
  const AuthService();

  static const _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Get Login URL ─────────────────────────────────────────────────

  /// Fetches the OAuth login URL from the auth service.
  /// GET /api/auth/login-url?service=HYPERLOCAL-APP&version=1
  Future<LoginUrlResponse> getLoginUrl({
    String service = 'HYPERLOCAL-APP',
    String version = '1',
  }) async {
    final uri = Uri.parse(ApiConfig.authLoginUrl).replace(
      queryParameters: {'service': service, 'version': version},
    );

    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return LoginUrlResponse(rawData: body);
      }
      throw Exception('Unexpected login URL response format');
    } else {
      throw Exception('Failed to get login URL (${response.statusCode})');
    }
  }

  // ── Exchange Token ────────────────────────────────────────────────

  /// Exchanges a login_id (token_id) for JWT access + refresh tokens.
  /// GET /api/auth/callback?token_id={tokenId}&service=HYPERLOCAL-APP&version=1
  Future<AuthTokenResponse> exchangeToken(
    String tokenId, {
    String service = 'HYPERLOCAL-APP',
    String version = '1',
  }) async {
    final uri = Uri.parse(ApiConfig.authCallback).replace(
      queryParameters: {
        'token_id': tokenId,
        'service': service,
        'version': version,
      },
    );

    final client = http.Client();
    try {
      final request = http.Request('GET', uri)..headers.addAll(_headers);
      request.followRedirects = false; // Prevent Dart from blindly following the redirect to localhost:5173
      
      final streamedResponse = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      // The backend will return a 307 Redirect to FRONTEND_URL (localhost:5173) with the new login_id
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location != null) {
          final redirectUri = Uri.parse(location);
          final loginId = redirectUri.queryParameters['token_id'];
          
          if (loginId != null) {
            // Make the final request with the actual login_id
            final secondUri = Uri.parse(ApiConfig.authCallback).replace(
              queryParameters: {
                'token_id': loginId,
                'service': service,
                'version': version,
              },
            );
            
            final secondRequest = http.Request('GET', secondUri)..headers.addAll(_headers);
            secondRequest.followRedirects = false;
            
            final secondStream = await client.send(secondRequest).timeout(_timeout);
            final secondResponse = await http.Response.fromStream(secondStream);
            
            if (secondResponse.statusCode == 200) {
              final body = jsonDecode(secondResponse.body);
              if (body is Map<String, dynamic> && body.containsKey('access_token')) {
                return AuthTokenResponse.fromJson(body);
              }
            } else {
               final detail = _extractDetail(secondResponse.body);
               throw Exception(detail ?? 'Token exchange failed on second leg (${secondResponse.statusCode})');
            }
          }
        }
        throw Exception('Failed to follow authentication redirect');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('access_token')) {
          return AuthTokenResponse.fromJson(body);
        }
      }
      
      final detail = _extractDetail(response.body);
      throw Exception(detail ?? 'Token exchange failed (${response.statusCode})');
    } finally {
      client.close();
    }
  }

  // ── Refresh Token ─────────────────────────────────────────────────

  /// Refreshes an expired access token using the refresh token.
  /// POST /api/auth/refresh  body: {refresh_token, version}
  Future<AuthTokenResponse> refreshToken({
    required String refreshToken,
    String version = '1',
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.authRefresh),
      headers: _headers,
      body: jsonEncode({
        'refresh_token': refreshToken,
        'version': version,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return AuthTokenResponse.fromJson(body as Map<String, dynamic>);
    } else {
      final detail = _extractDetail(response.body);
      throw Exception(detail ?? 'Token refresh failed (${response.statusCode})');
    }
  }

  // ── Revoke Token ──────────────────────────────────────────────────

  /// Revokes a token (access or refresh). Used on logout.
  /// POST /api/auth/revoke  body: {token}
  Future<void> revokeToken(String token) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.authRevoke),
        headers: _headers,
        body: jsonEncode({'token': token}),
      ).timeout(_timeout);
    } catch (_) {
      // Revocation failure is non-critical — token will expire anyway
    }
  }

  // ── Helper ────────────────────────────────────────────────────────

  String? _extractDetail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final detail = json['detail'];
        if (detail is String) return detail;
        if (detail is Map) return detail['msg']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
