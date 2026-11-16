import 'package:flutter_test/flutter_test.dart';
import 'package:digital_app/core/auth/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler Deep Link Parsing Tests', () {
    late DeepLinkHandler handler;

    setUp(() {
      handler = DeepLinkHandler();
    });

    test('parses exact user issue URL (shopiq.inventq.in/callback)', () {
      final uri = Uri.parse(
        'https://shopiq.inventq.in/callback?token_id=8b23d4c6-4884-4d4d-a46e-a101bebe584b&flow=signin',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), '8b23d4c6-4884-4d4d-a46e-a101bebe584b');
      expect(handler.extractFlow(uri), 'signin');
    });

    test('parses custom scheme redirect URL (shopiq://callback)', () {
      final uri = Uri.parse(
        'shopiq://callback?token_id=8b23d4c6-4884-4d4d-a46e-a101bebe584b&flow=signin',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), '8b23d4c6-4884-4d4d-a46e-a101bebe584b');
      expect(handler.extractFlow(uri), 'signin');
    });

    test('parses https auth callback path (shopiq.inventq.in/auth/callback)', () {
      final uri = Uri.parse(
        'https://shopiq.inventq.in/auth/callback?token_id=test-token-12345&flow=signup',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), 'test-token-12345');
      expect(handler.extractFlow(uri), 'signup');
    });

    test('parses custom scheme with auth host (shopiq://auth/callback)', () {
      final uri = Uri.parse(
        'shopiq://auth/callback?token_id=test-token-auth-host',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), 'test-token-auth-host');
    });

    test('parses custom scheme without host (shopiq:///callback)', () {
      final uri = Uri.parse(
        'shopiq:///callback?token_id=test-token-no-host',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), 'test-token-no-host');
    });

    test('parses hyperlocal-app custom scheme (hyperlocal-app://auth/callback)', () {
      final uri = Uri.parse(
        'hyperlocal-app://auth/callback?token_id=hyperlocal-token-999',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), 'hyperlocal-token-999');
    });

    test('parses intent URI with hash/fragment fallback', () {
      final uri = Uri.parse(
        'intent://callback?token_id=8b23d4c6-4884-4d4d-a46e-a101bebe584b&flow=signin#Intent;scheme=shopiq;package=in.inventq.shopiq;end',
      );

      expect(handler.isAuthCallbackUri(uri), isTrue);
      expect(handler.extractTokenId(uri), '8b23d4c6-4884-4d4d-a46e-a101bebe584b');
      expect(handler.extractFlow(uri), 'signin');
    });

    test('ignores unrelated URLs', () {
      final uri = Uri.parse('https://shopiq.inventq.in/products/123');
      expect(handler.isAuthCallbackUri(uri), isFalse);
      expect(handler.extractTokenId(uri), isNull);
    });
  });
}
