// lib/core/network/api_client.dart
//
// Central HTTP client with automatic Bearer token injection,
// token refresh on 401, retry logic, timeout, and structured error parsing.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exceptions.dart';
import '../auth/token_storage.dart';

/// Callback type for refreshing the access token.
/// Returns the new access token, or null if refresh failed (triggers logout).
typedef TokenRefresher = Future<String?> Function();

/// Callback invoked when the session is fully expired and cannot be refreshed.
typedef SessionExpiredCallback = void Function();

class ApiClient {
  final TokenStorage _tokenStorage;
  TokenRefresher? _tokenRefresher;
  SessionExpiredCallback? _onSessionExpired;

  static const Duration _defaultTimeout = Duration(seconds: 20);
  static const Duration _longTimeout = Duration(seconds: 30);
  static const int _maxRetries = 1;

  ApiClient({
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage();

  /// Sets the token refresher callback. Called by AuthProvider after init.
  void setTokenRefresher(TokenRefresher refresher) {
    _tokenRefresher = refresher;
  }

  /// Sets the session expired callback. Called by AuthProvider after init.
  void setSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  // ── Core Request Methods ──────────────────────────────────────────

  Future<dynamic> get(
    String url, {
    Map<String, String>? queryParams,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(url, queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      if (kDebugMode) print('[ApiClient] GET $uri');
      final response = await http.get(uri, headers: headers)
          .timeout(timeout ?? _defaultTimeout);
      return _handleResponse(response);
    }, url: url, requiresAuth: requiresAuth);
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, String>? queryParams,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(url, queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      if (kDebugMode) print('[ApiClient] POST $uri');
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout ?? _defaultTimeout);
      return _handleResponse(response);
    }, url: url, requiresAuth: requiresAuth);
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, String>? queryParams,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(url, queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      if (kDebugMode) print('[ApiClient] PUT $uri');
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout ?? _defaultTimeout);
      return _handleResponse(response);
    }, url: url, requiresAuth: requiresAuth);
  }

  Future<dynamic> delete(
    String url, {
    Map<String, String>? queryParams,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(url, queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      if (kDebugMode) print('[ApiClient] DELETE $uri');
      final response = await http.delete(uri, headers: headers)
          .timeout(timeout ?? _defaultTimeout);
      return _handleResponse(response);
    }, url: url, requiresAuth: requiresAuth);
  }

  // ── Internal Helpers ──────────────────────────────────────────────

  Uri _buildUri(String url, Map<String, String>? queryParams) {
    final uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      });
    }
    return uri;
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Executes a request with automatic retry on 401 (token refresh) and 5xx.
  Future<dynamic> _executeWithRetry(
    Future<dynamic> Function() request, {
    required String url,
    bool requiresAuth = true,
    int attempt = 0,
  }) async {
    try {
      return await request();
    } on UnauthorizedException {
      // Try refreshing the token exactly once
      if (attempt < _maxRetries && requiresAuth && _tokenRefresher != null) {
        if (kDebugMode) print('[ApiClient] 401 — attempting token refresh...');
        final newToken = await _tokenRefresher!();
        if (newToken != null) {
          if (kDebugMode) print('[ApiClient] Token refreshed. Retrying request...');
          return _executeWithRetry(
            request,
            url: url,
            requiresAuth: requiresAuth,
            attempt: attempt + 1,
          );
        }
      }
      // Refresh failed — session expired
      _onSessionExpired?.call();
      rethrow;
    } on ServerException {
      // Retry once on server errors
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _executeWithRetry(
          request,
          url: url,
          requiresAuth: requiresAuth,
          attempt: attempt + 1,
        );
      }
      rethrow;
    } on TimeoutException {
      throw const ApiTimeoutException();
    } on SocketException {
      throw const NoInternetException();
    }
  }

  /// Parses the HTTP response and throws typed exceptions for error codes.
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      body = response.body;
    }

    if (kDebugMode && statusCode >= 400) {
      print('[ApiClient] Error $statusCode: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    switch (statusCode) {
      case 401:
        final detail = _extractDetail(body);
        if (detail != null && detail.toLowerCase().contains('expired')) {
          throw const TokenExpiredException();
        }
        throw UnauthorizedException(detail ?? 'Unauthorized');
      case 403:
        throw ForbiddenException(_extractDetail(body) ?? 'Access forbidden');
      case 404:
        throw NotFoundException(_extractDetail(body) ?? 'Resource not found');
      case 422:
        final errors = _parseValidationErrors(body);
        throw ValidationException(
          message: _extractDetail(body) ?? 'Validation error',
          errors: errors,
        );
      case 429:
        throw const ApiException('Too many requests. Please wait a moment.', statusCode: 429);
      default:
        if (statusCode >= 500) {
          throw ServerException(_extractDetail(body) ?? 'Server error ($statusCode)');
        }
        throw ApiException(
          _extractDetail(body) ?? 'Request failed ($statusCode)',
          statusCode: statusCode,
          body: body,
        );
    }
  }

  /// Extracts the `detail` field from a FastAPI error response.
  String? _extractDetail(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is Map) return detail['msg']?.toString() ?? detail.toString();
      if (detail is List && detail.isNotEmpty) {
        // Validation error list — summarize
        return detail.map((e) {
          if (e is Map) return e['msg']?.toString() ?? '';
          return e.toString();
        }).where((s) => s.isNotEmpty).join('; ');
      }
    }
    if (body is String) return body;
    return null;
  }

  /// Parses FastAPI's HTTPValidationError into a list of ValidationDetail.
  List<ValidationDetail> _parseValidationErrors(dynamic body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is List) {
        return detail
            .whereType<Map<String, dynamic>>()
            .map((e) => ValidationDetail.fromJson(e))
            .toList();
      }
    }
    return [];
  }
}
