// lib/core/auth/deep_link_handler.dart
//
// Handles incoming deep links for OAuth callback.
// Listens for:
//   - hyperlocal-app://auth/callback?token_id=...
//   - https://auth.hyperlocal.com/callback?token_id=...
//
// Parses the token_id and triggers token exchange via AuthProvider.
//

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (!isAuthCallback) return;

    final tokenId = uri.queryParameters['token_id'];
    if (tokenId != null && tokenId.isNotEmpty) {
      if (kDebugMode) print('[DeepLinkHandler] Auth callback with token_id: $tokenId');
      onAuthCallback?.call(tokenId);
    } else {
      if (kDebugMode) print('[DeepLinkHandler] Auth callback without token_id, ignoring');
    }
  }

  bool _isAuthCallbackUri(Uri uri) {
    // hyperlocal://auth/callback OR hyperlocal-app://auth/callback OR http://localhost:5173/auth/callback
    final isCustomScheme = (uri.scheme == 'hyperlocal' || uri.scheme == 'hyperlocal-app') && uri.host == 'auth' && uri.path.startsWith('/callback');
    final isWebScheme = (uri.scheme == 'http' || uri.scheme == 'https') && uri.path.startsWith('/auth/callback');
    // We also support intercepting the gateway URL if needed
    final isGatewayCallback = (uri.host == '10.167.188.101' || uri.host == '127.0.0.1' || uri.host == 'localhost') && uri.path.startsWith('/api/auth/callback');
    
    return isCustomScheme || isWebScheme || isGatewayCallback;
  }
  
  /// Starts a local HTTP server to intercept the localhost redirect from the browser.
  Future<void> _startLocalServer() async {
    try {
      if (_localAuthServer != null) return;
      _localAuthServer = await HttpServer.bind(InternetAddress.anyIPv4, 8000);
      if (kDebugMode) print('[DeepLinkHandler] Local auth server listening on port 8000');
      
      _localAuthServer?.listen((HttpRequest request) {
        if (request.uri.path == '/auth/callback' || request.uri.path == '/api/auth/callback') {
          final tokenId = request.uri.queryParameters['token_id'];
          
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

  void dispose() {
    _subscription?.cancel();
    _localAuthServer?.close(force: true);
  }
}
