// lib/core/models/review_model.dart
//
// Generated from OpenAPI ShopReviewSchema.
// Required: user_id, shop_id, rating (1-5)
// Optional: review_text, user_name, timestamp
//

class ShopReview {
  final String userId;
  final String shopId;
  final double rating;
  final String? reviewText;
  final String? userName;
  final DateTime? timestamp;

  const ShopReview({
    required this.userId,
    required this.shopId,
    required this.rating,
    this.reviewText,
    this.userName,
    this.timestamp,
  });

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    return ShopReview(
      userId: json['user_id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      rating: _parseDouble(json['rating']),
      reviewText: json['review_text']?.toString(),
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? json['author_name']?.toString(),
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
    if (userName != null) 'user_name': userName,
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

class ShopReviewSummary {
  final String shopId;
  final double averageRating;
  final int reviewCount;
  final Map<int, int> starCounts; // 5 -> count, 4 -> count, etc.

  const ShopReviewSummary({
    required this.shopId,
    required this.averageRating,
    required this.reviewCount,
    this.starCounts = const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  });

  factory ShopReviewSummary.fromJson(Map<String, dynamic> json) {
    final rawStars = json['star_counts'] as Map<String, dynamic>? ?? {};
    final counts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      counts[i] = int.tryParse(rawStars[i.toString()]?.toString() ?? '0') ?? 0;
    }
    return ShopReviewSummary(
      shopId: json['shop_id']?.toString() ?? '',
      averageRating: _parseDouble(json['average_rating'] ?? json['avg_rating']),
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
      starCounts: counts,
    );
  }

  double percentageForStar(int star) {
    if (reviewCount <= 0) return 0.0;
    final c = starCounts[star] ?? 0;
    return (c / reviewCount).clamp(0.0, 1.0);
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
