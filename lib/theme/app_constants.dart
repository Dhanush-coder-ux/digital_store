import 'package:flutter/material.dart';

/// Responsive Design Breakpoints
class AppBreakpoints {
  // Screen width breakpoints
  static const double mobile = 360;
  static const double mobileLandscape = 600;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
  
  // Helper methods
  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}

/// Responsive Size Configuration
class AppResponsive {
  final double screenWidth;
  final double screenHeight;
  
  AppResponsive({
    required this.screenWidth,
    required this.screenHeight,
  });
  
  factory AppResponsive.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppResponsive(
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }
  
  bool get isMobile => AppBreakpoints.isMobile(screenWidth);
  bool get isTablet => AppBreakpoints.isTablet(screenWidth);
  bool get isDesktop => AppBreakpoints.isDesktop(screenWidth);
  
  /// Responsive padding based on screen size
  double get screenPadding {
    if (isDesktop) return 40;
    if (isTablet) return 24;
    return 16;
  }
  
  /// Grid column count based on screen size
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 2;
    return 1;
  }
  
  /// Maximum width for content
  double get maxContentWidth {
    if (isDesktop) return 1200;
    if (isTablet) return 768;
    return double.infinity;
  }
  
  /// Bottom navigation height
  double get navBarHeight {
    if (isMobile) return 80;
    return 0; // Not needed on larger screens
  }
}

/// Animation Durations
class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1200);
}

/// Animation Curves
class AppCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve smooth = Curves.fastOutSlowIn;
}

/// Opacity Values
class AppOpacity {
  static const double disabled = 0.5;
  static const double secondary = 0.6;
  static const double tertiary = 0.7;
  static const double enabled = 0.8;
  static const double hover = 0.9;
  static const double full = 1.0;
}

/// Z-Index layers
class AppZIndex {
  static const int background = 0;
  static const int card = 1;
  static const int floating = 10;
  static const int modal = 100;
  static const int tooltip = 1000;
  static const int snackbar = 2000;
}

/// String Constants
class AppStrings {
  // Common
  static const String appName = 'Digital Store';
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  
  // Empty States
  static const String emptyCart = 'Your cart is empty';
  static const String emptyOrders = 'No orders yet';
  static const String emptyFavorites = 'No favorites yet';
  static const String emptyAddresses = 'No addresses saved';
  
  // Navigation
  static const String home = 'Home';
  static const String stores = 'Stores';
  static const String cart = 'Cart';
  static const String profile = 'Profile';
  static const String orders = 'Orders';
  static const String favorites = 'Favorites';
  static const String addresses = 'Addresses';
  static const String payment = 'Payment';
  static const String checkout = 'Checkout';
  
  // Validation
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
}

/// Error Messages
class AppErrors {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unknownError = 'An unknown error occurred.';
  static const String loadingError = 'Failed to load data.';
}

/// Success Messages
class AppSuccess {
  static const String itemAdded = 'Item added to cart';
  static const String itemRemoved = 'Item removed';
  static const String addressAdded = 'Address added successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String orderPlaced = 'Order placed successfully';
}

/// Numeric Constants
class AppNumbers {
  // Cart
  static const int maxCartItems = 999;
  static const double minOrderValue = 50.0;
  static const double deliveryFee = 40.0;
  
  // Pagination
  static const int itemsPerPage = 10;
  static const int storesPerPage = 8;
  
  // Debounce
  static const int searchDebounce = 500; // milliseconds
  
  // Retry
  static const int maxRetries = 3;
  static const int retryDelay = 2000; // milliseconds
}
