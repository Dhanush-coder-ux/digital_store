// lib/core/models/search_history_model.dart
//
// Generated from OpenAPI SearchHistorySchema.
// Required: user_id, search_term
//

class SearchHistoryEntry {
  final String userId;
  final String searchTerm;
  final DateTime? timestamp;
  final int count;

  const SearchHistoryEntry({
    required this.userId,
    required this.searchTerm,
    this.timestamp,
    this.count = 1,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      userId: json['user_id']?.toString() ?? '',
      searchTerm: json['search_term']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      count: json['count'] is int ? json['count'] : 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'search_term': searchTerm,
  };
}
