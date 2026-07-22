import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Theme
import 'theme/app_theme.dart';

// Core infrastructure
import 'core/network/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/token_storage.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/deep_link_handler.dart';

// Services
import 'services/digitalstore_service.dart';
import 'services/shop_service.dart';
import 'services/product_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/customer_service.dart';

// Legacy / Mock Providers (UI state)
import 'models/providers.dart';

// Real API Providers
import 'models/shop_provider.dart';
import 'models/product_provider.dart';
import 'models/api_cart_provider.dart';
import 'models/profile_provider.dart';
import 'models/favorites_api_provider.dart';
import 'models/search_provider.dart';
import 'models/review_provider.dart';
import 'models/user_order_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Core Services
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authService = const AuthService();
  final digitalStoreService = DigitalStoreService(apiClient);

  // 2. Initialize Auth Provider and link ApiClient for token refresh
  final authProvider = AuthProvider(
    authService: authService,
    tokenStorage: tokenStorage,
  );
  authProvider.initialize(apiClient);

  // 3. Initialize Deep Link Handler for OAuth callbacks
  final deepLinkHandler = DeepLinkHandler();
  deepLinkHandler.onAuthCallback = (tokenId) async {
    await authProvider.handleAuthCallback(tokenId);
  };
  await deepLinkHandler.initialize();

  runApp(
    MyApp(
      authProvider: authProvider,
      apiClient: apiClient,
      digitalStoreService: digitalStoreService,
      deepLinkHandler: deepLinkHandler,
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  final ApiClient apiClient;
  final DigitalStoreService digitalStoreService;
  final DeepLinkHandler deepLinkHandler;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.apiClient,
    required this.digitalStoreService,
    required this.deepLinkHandler,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Auth Provider (Core) ────────────────────────────────────
        ChangeNotifierProvider.value(value: widget.authProvider),

        // ── UI / Local State Providers (Legacy) ─────────────────────
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),

        // ── DigitalStore Integrated Providers ───────────────────────
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(widget.digitalStoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesApiProvider(widget.digitalStoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(widget.digitalStoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(widget.digitalStoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserOrderProvider(widget.digitalStoreService),
        ),

        // ── Aggregated API Providers (Existing, adapted) ────────────
        ChangeNotifierProvider(
          create: (_) => ShopProvider(ShopService(widget.apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService(widget.apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ApiCartProvider(
            CartService(widget.apiClient),
            OrderService(widget.apiClient),
            CustomerService(widget.apiClient),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DigiStore',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}
