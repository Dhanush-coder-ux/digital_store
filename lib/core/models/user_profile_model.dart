// lib/core/models/user_profile_model.dart
//
// Generated from OpenAPI UserProfileSchema and UpdateUserProfileSchema.
//

import 'address_model.dart';

/// Full user profile — used for create and read.
/// From UserProfileSchema: required: user_id, name
class UserProfile {
  final String userId;
  final String name;
  final List<AddressModel> addresses;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.userId,
    required this.name,
    this.addresses = const [],
    this.preferences = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<AddressModel> parseAddresses(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => AddressModel.fromJson(e))
            .toList();
      }
      return [];
    }

    return UserProfile(
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      addresses: parseAddresses(json['addresses']),
      preferences: json['preferences'] is Map<String, dynamic>
          ? json['preferences'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'addresses': addresses.map((a) => a.toJson()).toList(),
    'preferences': preferences,
  };

  UserProfile copyWith({
    String? userId,
    String? name,
    List<AddressModel>? addresses,
    Map<String, dynamic>? preferences,
  }) => UserProfile(
    userId: userId ?? this.userId,
    name: name ?? this.name,
    addresses: addresses ?? this.addresses,
    preferences: preferences ?? this.preferences,
  );

  /// Gets the default address, or the first if none is default.
  AddressModel? get defaultAddress {
    final def = addresses.where((a) => a.isDefault).firstOrNull;
    return def ?? (addresses.isNotEmpty ? addresses.first : null);
  }
}

/// Partial update profile — all fields optional.
/// From UpdateUserProfileSchema.
class UpdateUserProfile {
  final String? name;
  final List<AddressModel>? addresses;
  final Map<String, dynamic>? preferences;

  const UpdateUserProfile({
    this.name,
    this.addresses,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (addresses != null) {
      map['addresses'] = addresses!.map((a) => a.toJson()).toList();
    }
    if (preferences != null) map['preferences'] = preferences;
    return map;
  }
}
