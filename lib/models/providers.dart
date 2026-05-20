import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

/// Product model
class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? image;
  final double? rating;
  final String? description;
  
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.image,
    this.rating,
    this.description,
  });
  
  Product.fromMap(Map<String, dynamic> map)
    : id = map['id'] ?? '',
      name = map['name'] ?? '',
      category = map['category'] ?? '',
      price = (map['price'] is double) ? map['price'] : double.tryParse(map['price'].toString()) ?? 0.0,
      image = map['image'],
      rating = map['rating'],
      description = map['description'];
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'image': image,
    'rating': rating,
    'description': description,
  };
  
  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? image,
    double? rating,
    String? description,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    image: image ?? this.image,
    rating: rating ?? this.rating,
    description: description ?? this.description,
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
  
  CartItem({
    required this.product,
    required this.storeName,
    this.quantity = 1,
  });
  
  double get subtotal => product.price * quantity;
  
  CartItem.fromMap(Map<String, dynamic> map)
    : product = Product.fromMap(map['product']),
      storeName = map['storeName'] ?? '',
      quantity = map['quantity'] ?? 1;
  
  Map<String, dynamic> toMap() => {
    'product': product.toMap(),
    'storeName': storeName,
    'quantity': quantity,
  };
  
  CartItem copyWith({
    Product? product,
    String? storeName,
    int? quantity,
  }) => CartItem(
    product: product ?? this.product,
    storeName: storeName ?? this.storeName,
    quantity: quantity ?? this.quantity,
  );
}

/// Cart Provider - Manages shopping cart state
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  
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
  void addToCart(Product product, String storeName, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.storeName == storeName,
    );
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        storeName: storeName,
        quantity: quantity,
      ));
    }
    notifyListeners();
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
