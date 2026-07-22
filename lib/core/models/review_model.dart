// lib/core/models/review_model.dart
//
// Generated from OpenAPI ShopReviewSchema.
// Required: user_id, shop_id, rating (1-5)
// Optional: review_text (nullable)
//

class ShopReview {
  final String userId;
  final String shopId;
  final double rating;
  final String? reviewText;
  final DateTime? timestamp;

  const ShopReview({
    required this.userId,
    required this.shopId,
    required this.rating,
    this.reviewText,
    this.timestamp,
  });

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    return ShopReview(
      userId: json['user_id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      rating: _parseDouble(json['rating']),
      reviewText: json['review_text']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'shop_id': shopId,
    'rating': rating,
    if (reviewText != null) 'review_text': reviewText,
  };

  /// Validates that the review meets the schema requirements.
  String? validate() {
    if (userId.isEmpty) return 'User ID is required';
    if (shopId.isEmpty) return 'Shop ID is required';
    if (rating < 1 || rating > 5) return 'Rating must be between 1 and 5';
    return null;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
