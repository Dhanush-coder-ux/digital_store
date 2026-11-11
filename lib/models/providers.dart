import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/address_model.dart';
import '../core/auth/token_storage.dart';
import '../services/api_config.dart';
import '../services/notification_service.dart';

/// Product model
class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? image;
  final double? rating;
  final String? description;
  final bool requiresPreOrder;
  final int noticeHours;
  
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.image,
    this.rating,
    this.description,
    this.requiresPreOrder = false,
    this.noticeHours = 0,
  });
  
  Product.fromMap(Map<String, dynamic> map)
    : id = map['id'] ?? '',
      name = map['name'] ?? '',
      category = map['category'] ?? '',
      price = (map['price'] is double) ? map['price'] : double.tryParse(map['price'].toString()) ?? 0.0,
      image = map['image'],
      rating = map['rating'],
      description = map['description'],
      requiresPreOrder = map['requiresPreOrder'] == true,
      noticeHours = map['noticeHours'] ?? 0;
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'image': image,
    'rating': rating,
    'description': description,
    'requiresPreOrder': requiresPreOrder,
    'noticeHours': noticeHours,
  };
  
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? image,
    double? rating,
    String? description,
    bool? requiresPreOrder,
    int? noticeHours,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    image: image ?? this.image,
    rating: rating ?? this.rating,
    description: description ?? this.description,
    requiresPreOrder: requiresPreOrder ?? this.requiresPreOrder,
    noticeHours: noticeHours ?? this.noticeHours,
  );
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Product && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

/// Cart item model
class CartItem {
  final Product product;
  final String storeName;
  int quantity;
  final String? scheduledFor;
  
  CartItem({
    required this.product,
    required this.storeName,
    this.quantity = 1,
    this.scheduledFor,
  });
  
  double get subtotal => product.price * quantity;
  
  CartItem.fromMap(Map<String, dynamic> map)
    : product = Product.fromMap(map['product']),
      storeName = map['storeName'] ?? '',
      quantity = map['quantity'] ?? 1,
      scheduledFor = map['scheduledFor'];
  
  Map<String, dynamic> toMap() => {
    'product': product.toMap(),
    'storeName': storeName,
    'quantity': quantity,
    'scheduledFor': scheduledFor,
  };
  
  CartItem copyWith({
    Product? product,
    String? storeName,
    int? quantity,
    String? scheduledFor,
  }) => CartItem(
    product: product ?? this.product,
    storeName: storeName ?? this.storeName,
    quantity: quantity ?? this.quantity,
    scheduledFor: scheduledFor ?? this.scheduledFor,
  );
}

/// Order item model representing a placed order
class OrderItem {
  final String id;
  final String date;
  final String status;
  final List<CartItem> items;
  final double total;

  OrderItem({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.total,
  });
}

/// Cart Provider - Manages shopping cart state
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final List<OrderItem> _orders = [];
  
  List<CartItem> get items => _items;
  List<OrderItem> get orders => _orders;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  
  bool get isEmpty => _items.isEmpty;
  
  bool get isNotEmpty => _items.isNotEmpty;
  
  /// Group items by store
  Map<String, List<CartItem>> get groupedByStore {
    final groups = <String, List<CartItem>>{};
    for (var item in _items) {
      groups.putIfAbsent(item.storeName, () => []).add(item);
    }
    return groups;
  }
  
  /// Add product to cart
  void addToCart(
    Product product,
    String storeName, {
    int quantity = 1,
    String? scheduledFor,
  }) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.storeName == storeName &&
          item.scheduledFor == scheduledFor,
    );
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        storeName: storeName,
        quantity: quantity,
        scheduledFor: scheduledFor,
      ));
    }
    notifyListeners();
  }
  
  void placeOrder() {
    if (_items.isEmpty) return;
    
    final id = "ORD-${(1000 + DateTime.now().millisecond % 9000)}";
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}";
    
    final double totalAmount = subtotal + 5.00;
    
    final newOrder = OrderItem(
      id: id,
      date: dateStr,
      status: 'ONGOING',
      items: List.from(_items),
      total: totalAmount,
    );
    
    _orders.insert(0, newOrder);
    clearCart();
  }
  
  /// Update item quantity
  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(item);
      return;
    }
    
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }
  
  /// Remove item from cart
  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }
  
  /// Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  
  /// Clear items from specific store
  void clearStoreItems(String storeName) {
    _items.removeWhere((item) => item.storeName == storeName);
    notifyListeners();
  }
}

/// Favorite model
class FavoriteItem {
  final String id;
  final String name;
  final String type; // 'store' or 'product'
  final String? image;
  final double? rating;
  
  FavoriteItem({
    required this.id,
    required this.name,
    required this.type,
    this.image,
    this.rating,
  });
  
  FavoriteItem.fromMap(Map<String, dynamic> map)
    : id = map['id'] ?? '',
      name = map['name'] ?? '',
      type = map['type'] ?? 'store',
      image = map['image'],
      rating = map['rating'];
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'image': image,
    'rating': rating,
  };
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is FavoriteItem && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

/// Favorites Provider - Manages user favorites
class FavoritesProvider extends ChangeNotifier {
  final List<FavoriteItem> _favorites = [];
  
  List<FavoriteItem> get favorites => _favorites;
  
  List<FavoriteItem> get stores => _favorites.where((f) => f.type == 'store').toList();
  
  List<FavoriteItem> get products => _favorites.where((f) => f.type == 'product').toList();
  
  bool isFavorited(String id) => _favorites.any((f) => f.id == id);
  
  /// Toggle favorite
  void toggleFavorite(FavoriteItem item) {
    final index = _favorites.indexWhere((f) => f.id == item.id);
    
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(item);
    }
    notifyListeners();
  }
  
  /// Add favorite
  void addFavorite(FavoriteItem item) {
    if (!isFavorited(item.id)) {
      _favorites.add(item);
      notifyListeners();
    }
  }
  
  /// Remove favorite
  void removeFavorite(String id) {
    _favorites.removeWhere((f) => f.id == id);
    notifyListeners();
  }
  
  /// Clear all favorites
  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}

/// UI State Provider - Manages general UI state
class UIStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _showSnackbar = false;
  String _snackbarMessage = '';
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showSnackbar => _showSnackbar;
  String get snackbarMessage => _snackbarMessage;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void showSnackbarMessage(String message, {Duration duration = const Duration(seconds: 2)}) {
    _snackbarMessage = message;
    _showSnackbar = true;
    notifyListeners();
    
    Future.delayed(duration, () {
      _showSnackbar = false;
      notifyListeners();
    });
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final IconData icon;
  final Color color;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
    required this.color,
    this.createdAt,
    this.metadata = const {},
    this.isRead = false,
  });

  /// Ensures only Digital Store customer app notifications are shown in the mobile app
  /// (excludes InventQ ERP inventory/purchase/product/analytics/POS or merchant-only alerts).
  static bool isDigitalStoreCustomerNotification(Map<String, dynamic> json) {
    final rawMeta = json['additional_metadata'];
    final Map<String, dynamic> meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : const {};

    final audience = (meta['audience'] ?? '').toString().toLowerCase().trim();
    if (audience == 'shop' ||
        audience == 'merchant' ||
        audience == 'admin' ||
        audience == 'retailer' ||
        audience == 'erp') {
      return false;
    }
    if (meta['target_shop'] == true) {
      return false;
    }

    final rawType = (json['type'] ?? '').toString().toLowerCase().trim();
    if (rawType == 'customer_order_cancelled' || rawType == 'analytics_sync') {
      return false;
    }

    final channel = (meta['channel'] ?? '').toString().toLowerCase().trim();
    final origin = (meta['origin'] ?? meta['order_origin'] ?? '').toString().toUpperCase().trim();
    final metaType = (meta['type'] ?? '').toString().toLowerCase().trim();
    if (channel == 'pos' || origin == 'OFFLINE' || meta['is_online'] == false) {
      return false;
    }
    if (metaType == 'analytics_sync' ||
        meta.containsKey('purchase_id') ||
        meta.containsKey('product_id')) {
      return false;
    }

    final title = (json['title'] ?? '').toString().toLowerCase().trim();
    const blockedPrefixes = [
      'product created',
      'product updated',
      'product deleted',
      'purchase created',
      'purchase updated',
      'bulk inventory',
      'analytics sync',
      'new order placed',
      'new online order received',
      'new return request',
    ];
    for (final prefix in blockedPrefixes) {
      if (title.startsWith(prefix)) return false;
    }

    if (audience == 'customer') return true;

    final eventType = (meta['event_type'] ?? '').toString().toUpperCase().trim();
    const customerEvents = {
      'SHOP_ANNOUNCEMENT',
      'SHOP_VACATION_MODE',
      'ORDER_STATUS',
      'RETURN_REQUEST_CREATED',
      'RETURN_REQUEST_UPDATED',
      'RETURN_REQUEST_STATUS',
    };
    if (customerEvents.contains(eventType)) return true;

    final category = (meta['category'] ?? '').toString().toLowerCase().trim();
    if (category == 'digital_store' || channel == 'digital_store') {
      return true;
    }

    return false;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? DateTime.now().microsecondsSinceEpoch).toString();
    final title = (json['title'] ?? 'Notification').toString();
    final message = (json['message'] ?? '').toString();
    final rawType = (json['type'] ?? 'info').toString().toLowerCase();
    final rawMeta = json['additional_metadata'];
    final Map<String, dynamic> metadata = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : const {};
    final eventType = (metadata['event_type'] ?? '').toString().toUpperCase();

    DateTime? parsedDate;
    final rawCreatedAt = json['created_at']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      // Backend writes naive UTC timestamps via datetime.utcnow()
      final normalized = rawCreatedAt.endsWith('Z') || rawCreatedAt.contains('+')
          ? rawCreatedAt
          : '${rawCreatedAt}Z';
      parsedDate = DateTime.tryParse(normalized)?.toLocal();
    }

    IconData icon = Icons.notifications_outlined;
    Color color = const Color(0xFF2563EB);

    if (eventType == 'SHOP_ANNOUNCEMENT' || rawType == 'announcement' || rawType == 'promo') {
      icon = Icons.campaign_outlined;
      color = const Color(0xFFD97706);
    } else if (eventType == 'SHOP_VACATION_MODE') {
      final vacOn = metadata['vacation_mode'] == true;
      icon = vacOn ? Icons.beach_access_outlined : Icons.storefront_outlined;
      color = vacOn ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    } else if (eventType.startsWith('RETURN_REQUEST')) {
      icon = Icons.assignment_return_outlined;
      color = rawType == 'error'
          ? const Color(0xFFEF4444)
          : (rawType == 'success' ? const Color(0xFF10B981) : const Color(0xFFD97706));
    } else if (eventType == 'ORDER_STATUS' || rawType == 'order') {
      final orderStatus = (metadata['status'] ?? '').toString().toUpperCase();
      if (orderStatus == 'OUT_FOR_DELIVERY') {
        icon = Icons.local_shipping_outlined;
        color = const Color(0xFF2563EB);
      } else if (orderStatus == 'DELIVERED' || orderStatus == 'COMPLETED' || rawType == 'success') {
        icon = Icons.inventory_2_outlined;
        color = const Color(0xFF10B981);
      } else if (orderStatus == 'CANCELED' || orderStatus == 'CANCELLED' || orderStatus == 'REJECTED' || rawType == 'error') {
        icon = Icons.cancel_outlined;
        color = const Color(0xFFEF4444);
      } else {
        icon = Icons.shopping_bag_outlined;
        color = const Color(0xFF2563EB);
      }
    } else if (rawType == 'success') {
      icon = Icons.check_circle_outline;
      color = const Color(0xFF10B981);
    } else if (rawType == 'warning') {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFF59E0B);
    } else if (rawType == 'error') {
      icon = Icons.error_outline;
      color = const Color(0xFFEF4444);
    }

    return AppNotification(
      id: id,
      title: title,
      message: message,
      time: _formatRelativeTime(parsedDate),
      type: eventType.isNotEmpty ? eventType : rawType,
      icon: icon,
      color: color,
      createdAt: parsedDate,
      metadata: metadata,
      isRead: json['is_read'] == true,
    );
  }

  static String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
  }
}

class NotificationsProvider extends ChangeNotifier {
  static const String _prefEnabledKey = 'digitalstore_notifications_enabled';

  NotificationService? _service;
  TokenStorage? _tokenStorage;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  String? _error;
  String? _boundUserId;

  Timer? _pollTimer;
  WebSocket? _socket;
  bool _isDisposed = false;

  NotificationsProvider({
    NotificationService? service,
    TokenStorage? tokenStorage,
  })  : _service = service,
        _tokenStorage = tokenStorage {
    _loadPreference();
  }

  void configure({
    required NotificationService service,
    TokenStorage? tokenStorage,
  }) {
    _service = service;
    if (tokenStorage != null) {
      _tokenStorage = tokenStorage;
    }
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefEnabledKey);
      if (saved != null && saved != _notificationsEnabled) {
        _notificationsEnabled = saved;
        if (!_isDisposed) notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefEnabledKey, enabled);
    } catch (_) {}

    if (!enabled) {
      _stopLiveListeners();
    } else if (_boundUserId != null && _boundUserId!.isNotEmpty) {
      await fetchNotifications(_boundUserId!, silent: true);
      _startLiveListeners(_boundUserId!);
    }
  }

  Future<void> bindUser(String? userId) async {
    final cleanId = userId?.trim();
    if (cleanId == null || cleanId.isEmpty) {
      reset();
      return;
    }
    if (_boundUserId == cleanId) return;

    _boundUserId = cleanId;
    await fetchNotifications(cleanId, silent: _notifications.isNotEmpty);
    if (_notificationsEnabled) {
      _startLiveListeners(cleanId);
    }
  }

  Future<void> fetchNotifications(String userId, {bool silent = false}) async {
    if (_service == null || userId.trim().isEmpty) return;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final rawList = await _service!.fetchNotifications(userId.trim());
      _notifications = rawList
          .where(AppNotification.isDigitalStoreCustomerNotification)
          .map(AppNotification.fromJson)
          .toList();
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationsProvider] fetchNotifications error: $e');
      }
      if (!silent) {
        _error = 'Failed to load notifications.';
      }
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _startLiveListeners(String userId) {
    _stopLiveListeners();
    if (!_notificationsEnabled) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_boundUserId != null && _notificationsEnabled) {
        fetchNotifications(_boundUserId!, silent: true);
      }
    });

    if (!kIsWeb) {
      _connectWebSocket(userId);
    }
  }

  Future<void> _connectWebSocket(String userId) async {
    try {
      final token = await _tokenStorage?.getAccessToken();
      if (token == null || token.isEmpty || _boundUserId != userId) return;

      final uri = Uri.parse(ApiConfig.notificationsWs(userId)).replace(
        queryParameters: {
          'token': token,
          'scope': 'digital_store',
          'audience': 'customer',
        },
      );
      final ws = await WebSocket.connect(uri.toString()).timeout(
        const Duration(seconds: 6),
      );
      if (_boundUserId != userId || !_notificationsEnabled || _isDisposed) {
        await ws.close();
        return;
      }
      _socket = ws;
      ws.listen(
        (event) {
          if (event is String && event.trim().startsWith('{')) {
            try {
              final decoded = jsonDecode(event);
              if (decoded is Map<String, dynamic> &&
                  AppNotification.isDigitalStoreCustomerNotification(decoded)) {
                final incoming = AppNotification.fromJson(decoded);
                final existingIdx = _notifications.indexWhere((n) => n.id == incoming.id);
                if (existingIdx >= 0) {
                  _notifications[existingIdx] = incoming;
                } else {
                  _notifications.insert(0, incoming);
                }
                if (!_isDisposed) notifyListeners();
              }
            } catch (_) {}
          }
        },
        onError: (_) {},
        onDone: () {
          _socket = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      // Polling timer remains active as reliable fallback
    }
  }

  void _stopLiveListeners() {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  Future<void> markAllAsRead([String? userId]) async {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();

    final uid = userId ?? _boundUserId;
    if (_service != null && uid != null && uid.isNotEmpty) {
      await _service!.markAllAsRead(uid);
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    if (!_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _service?.markAsRead(id);
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((item) => item.id == id);
    notifyListeners();
    await _service?.deleteNotification(id);
  }

  void broadcastRegularOffer({
    required String storeName,
    required int regularCount,
    required String offerTitle,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: '$storeName regulars alert',
        message:
            '$offerTitle was sent to $regularCount regular customers from this retailer.',
        time: 'Just now',
        type: 'regulars',
        icon: Icons.campaign_outlined,
        color: const Color(0xFF2563EB),
      ),
    );
    notifyListeners();
  }

  void reset() {
    _stopLiveListeners();
    _boundUserId = null;
    _notifications = [];
    _isLoading = false;
    _error = null;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopLiveListeners();
    super.dispose();
  }
}

class SavedAddress {
  final String id;
  final String title;
  final String address;
  final String name;
  final String phone;

  SavedAddress({
    required this.id,
    required this.title,
    required this.address,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'address': address,
    'name': name,
    'phone': phone,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'],
    title: json['title'],
    address: json['address'],
    name: json['name'],
    phone: json['phone'],
  );
}

class LocationProvider with ChangeNotifier {
  String _currentAddressName = 'Locating...';
  String get currentAddressName => _currentAddressName;

  String _fullAddressName = 'Locating...';
  String get fullAddressName => _fullAddressName;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<SavedAddress> _savedAddresses = [];
  List<SavedAddress> get savedAddresses => _savedAddresses;

  SavedAddress? _selectedAddress;

  LocationProvider() {
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? addressesJson = prefs.getString('saved_addresses');
    if (addressesJson != null) {
      final List<dynamic> decoded = json.decode(addressesJson);
      _savedAddresses = decoded.map((e) => SavedAddress.fromJson(e)).toList();
    } else {
      // Default mock addresses
      _savedAddresses = [
        SavedAddress(id: '1', title: 'Home', address: '123 Maple Street, Springfield, IL', name: 'Deepak Roshan', phone: '+1 (217) 555-0123'),
        SavedAddress(id: '2', title: 'Office', address: '456 Business Hub, Suite 200, Chicago, IL', name: 'Deepak Roshan', phone: '+1 (312) 555-0199'),
      ];
      _saveAddressesToPrefs();
    }
    notifyListeners();
  }

  Future<void> _saveAddressesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_savedAddresses.map((e) => e.toJson()).toList());
    await prefs.setString('saved_addresses', encoded);
  }

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  Future<AddressModel?> requestLocationAndGeocode() async {
    _isLoading = true;
    notifyListeners();

    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddressName = '${place.name}, ${place.street}';
          // Clean up if name is same as street
          if (place.name == place.street || place.name == null || place.name!.isEmpty) {
            _currentAddressName = '${place.street}, ${place.subLocality ?? place.locality}';
          }
          if (_currentAddressName.startsWith(', ')) {
            _currentAddressName = _currentAddressName.substring(2);
          }
          
          _fullAddressName = '$_currentAddressName, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
          
          // Cap string length for header
          if (_currentAddressName.length > 25) {
            _currentAddressName = _currentAddressName.substring(0, 25) + '...';
          }

          return AddressModel(
            phone: '',
            fullAddress: _fullAddressName,
            city: place.locality ?? '',
            pincode: place.postalCode ?? '',
            state: place.administrativeArea ?? '',
          );
        } else {
          _currentAddressName = 'Location found';
          _fullAddressName = 'Location found';
        }
      } else {
        _currentAddressName = 'Location Permission Denied';
        _fullAddressName = 'Please enable location permissions in settings.';
      }
    } catch (e) {
      _currentAddressName = 'Enable Location Services';
      _fullAddressName = 'Could not fetch location. Please check your GPS.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  void selectAddress(SavedAddress address) {
    _selectedAddress = address;
    _fullAddressName = address.address;
    String shortAddr = address.address.split(',').first;
    if (shortAddr.length > 15) shortAddr = shortAddr.substring(0, 15) + '...';
    _currentAddressName = '${address.title} • $shortAddr';
    notifyListeners();
  }

  void selectAddressModel(AddressModel address) {
    _fullAddressName = address.fullAddress;
    String shortAddr = address.city.isNotEmpty ? address.city : address.fullAddress.split(',').first;
    if (shortAddr.length > 15) shortAddr = shortAddr.substring(0, 15) + '...';
    String title = address.isDefault ? 'Default' : 'Saved';
    _currentAddressName = '$title • $shortAddr';
    notifyListeners();
  }

  void addSavedAddress(SavedAddress address) {
    _savedAddresses.insert(0, address);
    _saveAddressesToPrefs();
    selectAddress(address); // Auto-select newly added address
  }
}
