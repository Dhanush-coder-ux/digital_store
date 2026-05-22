import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';/// Product model
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
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationsProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Order Delivered!',
      message: 'Your order from Fresh Mart has been delivered successfully.',
      time: 'Just now',
      type: 'order',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF10B981),
    ),
    AppNotification(
      id: '2',
      title: 'Special Offer',
      message: 'Get 20% off on your next grocery purchase. Use code: GROCERY20',
      time: '2 hours ago',
      type: 'promo',
      icon: Icons.local_offer_outlined,
      color: const Color(0xFFF59E0B),
    ),
    AppNotification(
      id: '3',
      title: 'Store Update',
      message: "Your favorite store 'Grace Super Market' added new items.",
      time: 'Yesterday',
      type: 'update',
      icon: Icons.storefront_outlined,
      color: const Color(0xFF0EA5E9),
      isRead: true,
    ),
  ];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _notifications[index].isRead = true;
    notifyListeners();
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

  Future<void> requestLocationAndGeocode() async {
    _isLoading = true;
    notifyListeners();

    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
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
  }

  void selectAddress(SavedAddress address) {
    _selectedAddress = address;
    _fullAddressName = address.address;
    String shortAddr = address.address.split(',').first;
    if (shortAddr.length > 15) shortAddr = shortAddr.substring(0, 15) + '...';
    _currentAddressName = '${address.title} • $shortAddr';
    notifyListeners();
  }

  void addSavedAddress(SavedAddress address) {
    _savedAddresses.insert(0, address);
    _saveAddressesToPrefs();
    selectAddress(address); // Auto-select newly added address
  }
}
