// lib/core/auth/deep_link_handler.dart
//
// Handles incoming deep links for OAuth callback.
// Listens for:
//   - shopiq://callback?token_id=...&flow=signin
//   - shopiq://auth/callback?token_id=...
//   - https://shopiq.inventq.in/callback?token_id=...&flow=signin
//   - https://shopiq.inventq.in/auth/callback?token_id=...
//   - hyperlocal-app://auth/callback?token_id=...
//
// Parses the token_id and triggers token exchange via AuthProvider.
//

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_config.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// Callback invoked with the token_id when an auth deep link is received.
  Function(String tokenId)? onAuthCallback;
  
  HttpServer? _localAuthServer;

  /// Initialize and start listening for deep links.
  Future<void> initialize() async {
    _startLocalServer();

    // Handle deep link that launched the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      if (kDebugMode) print('[DeepLinkHandler] Failed to get initial link: $e');
    }

    // Listen for deep links while the app is running (warm start)
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) {
        if (kDebugMode) print('[DeepLinkHandler] Stream error: $e');
      },
    );
  }

  void _handleUri(Uri uri) {
    if (kDebugMode) print('[DeepLinkHandler] Received URI: $uri');

    // Match auth callback paths
    final isAuthCallback = _isAuthCallbackUri(uri);
    if (!isAuthCallback) {
      if (kDebugMode) print('[DeepLinkHandler] URI is not an auth callback, skipping.');
      return;
    }

    final tokenId = _extractTokenId(uri);
    final flow = _extractFlow(uri);

    if (tokenId != null && tokenId.isNotEmpty) {
      if (kDebugMode) {
        print('[DeepLinkHandler] Auth callback with token_id: $tokenId (flow: ${flow ?? "unspecified"})');
      }
      onAuthCallback?.call(tokenId);
    } else {
      if (kDebugMode) print('[DeepLinkHandler] Auth callback without token_id, ignoring');
    }
  }

  /// Extracts the token_id regardless of whether it was passed in query parameters,
  /// URL fragment/hash, or embedded in intent URI.
  String? _extractTokenId(Uri uri) {
    // 1. Direct query parameters
    String? token = uri.queryParameters['token_id'] ??
        uri.queryParameters['tokenId'] ??
        uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) return token;

    // 2. Check within uri.fragment if present
    if (uri.hasFragment && uri.fragment.isNotEmpty) {
      final fragmentMatch = RegExp(r'(?:^|[?&#])token_id=([^&;#\s]+)').firstMatch(uri.fragment);
      if (fragmentMatch != null) {
        return Uri.decodeComponent(fragmentMatch.group(1)!);
      }
    }

    // 3. Fallback: regex search across the raw URI string
    final rawString = uri.toString();
    final rawMatch = RegExp(r'[?&#]token_id=([^&;#\s]+)').firstMatch(rawString);
    if (rawMatch != null) {
      return Uri.decodeComponent(rawMatch.group(1)!);
    }

    return null;
  }

  /// Extracts the optional auth flow parameter (e.g. "signin", "signup").
  String? _extractFlow(Uri uri) {
    String? flow = uri.queryParameters['flow'];
    if (flow != null && flow.isNotEmpty) return flow;

    if (uri.hasFragment && uri.fragment.isNotEmpty) {
      final match = RegExp(r'(?:^|[?&#])flow=([^&;#\s]+)').firstMatch(uri.fragment);
      if (match != null) {
        return Uri.decodeComponent(match.group(1)!);
      }
    }

    final rawMatch = RegExp(r'[?&#]flow=([^&;#\s]+)').firstMatch(uri.toString());
    if (rawMatch != null) {
      return Uri.decodeComponent(rawMatch.group(1)!);
    }

    return null;
  }

  bool _isAuthCallbackUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    // 1. Custom Schemes: shopiq://, hyperlocal://, hyperlocal-app://
    if (scheme == 'shopiq' || scheme == 'hyperlocal' || scheme == 'hyperlocal-app') {
      // Handles:
      // shopiq://callback?token_id=...
      // shopiq://auth/callback?token_id=...
      // shopiq:///callback?token_id=...
      // shopiq://shopiq.inventq.in/callback?token_id=...
      if (host == 'callback' ||
          host == 'auth' ||
          host == 'shopiq.inventq.in' ||
          host.isEmpty ||
          path.startsWith('/callback') ||
          path.startsWith('/auth/callback') ||
          path.contains('callback')) {
        return true;
      }
    }

    // 2. Verified App Links / Universal Links (HTTPS / HTTP)
    if (scheme == 'http' || scheme == 'https') {
      // Allowed hosts: shopiq.inventq.in, localhost, baseIp
      final isShopiqDomain = (host == 'shopiq.inventq.in');
      final isGatewayCallback = (host == ApiConfig.baseIp ||
          host == '10.39.224.101' ||
          host == '127.0.0.1' ||
          host == 'localhost' ||
          host.isEmpty);

      final isCallbackPath = path.startsWith('/callback') ||
          path.startsWith('/auth/callback') ||
          path.startsWith('/api/auth/callback') ||
          path.contains('callback');

      if ((isShopiqDomain || isGatewayCallback) && isCallbackPath) {
        return true;
      }
    }

    // 3. Robust fallback: Any URI that contains a token_id and has "callback" in host or path
    if ((host.contains('callback') || path.contains('callback')) &&
        (uri.queryParameters.containsKey('token_id') || uri.toString().contains('token_id='))) {
      return true;
    }

    return false;
  }
  
  /// Starts a local HTTP server to intercept the localhost redirect from the browser.
  Future<void> _startLocalServer() async {
    try {
      if (_localAuthServer != null) return;
      _localAuthServer = await HttpServer.bind(InternetAddress.anyIPv4, 8000);
      if (kDebugMode) print('[DeepLinkHandler] Local auth server listening on port 8000');
      
      _localAuthServer?.listen((HttpRequest request) {
        if (request.uri.path == '/auth/callback' || request.uri.path == '/api/auth/callback') {
          final tokenId = _extractTokenId(request.uri);
          
          // Respond to the browser
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('''
              <!DOCTYPE html>
              <html>
              <head><title>Login Successful</title></head>
              <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; flex-direction:column;">
                <h2>Login Successful!</h2>
                <p>You can close this browser and return to the app.</p>
                <script>
                  setTimeout(function() { window.close(); }, 1500);
                </script>
              </body>
              </html>
            ''');
          request.response.close();
          
          if (tokenId != null && tokenId.isNotEmpty) {
            if (kDebugMode) print('[DeepLinkHandler] Intercepted token_id from local server: $tokenId');
            
            // Immediately close the in-app browser so the app comes to the foreground
            try {
              closeInAppWebView();
            } catch (_) {}
            
            onAuthCallback?.call(tokenId);
          }
        } else {
          request.response
            ..statusCode = 404
            ..write('Not found');
          request.response.close();
        }
      });
    } catch (e) {
      if (kDebugMode) print('[DeepLinkHandler] Failed to start local server: $e');
    }
  }

  @visibleForTesting
  bool isAuthCallbackUri(Uri uri) => _isAuthCallbackUri(uri);

  @visibleForTesting
  String? extractTokenId(Uri uri) => _extractTokenId(uri);

  @visibleForTesting
  String? extractFlow(Uri uri) => _extractFlow(uri);

  void dispose() {
    _subscription?.cancel();
    _localAuthServer?.close(force: true);
  }
}
