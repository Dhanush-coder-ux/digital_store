// lib/core/models/favorite_models.dart
//
// Generated from OpenAPI FavoriteProductSchema and FavoriteShopSchema.
//

/// Request body for favoriting a product.
/// From FavoriteProductSchema: required: user_id, product_id
class FavoriteProductRequest {
  final String userId;
  final String productId;

  const FavoriteProductRequest({
    required this.userId,
    required this.productId,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'product_id': productId,
  };
}

/// Request body for favoriting a shop.
/// From FavoriteShopSchema: required: user_id, shop_id
class FavoriteShopRequest {
  final String userId;
  final String shopId;

  const FavoriteShopRequest({
    required this.userId,
    required this.shopId,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'shop_id': shopId,
  };
}
