// lib/core/models/address_model.dart
//
// Generated from OpenAPI AddressModel schema.
// Required: phone, full_address, city, pincode, state
// Optional: address_id (nullable), is_default (nullable, default false)
//

class AddressModel {
  final String? addressId;
  final String phone;
  final String fullAddress;
  final String city;
  final String pincode;
  final String state;
  final bool isDefault;

  const AddressModel({
    this.addressId,
    required this.phone,
    required this.fullAddress,
    required this.city,
    required this.pincode,
    required this.state,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      addressId: json['address_id']?.toString(),
      phone: json['phone']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (addressId != null) 'address_id': addressId,
    'phone': phone,
    'full_address': fullAddress,
    'city': city,
    'pincode': pincode,
    'state': state,
    'is_default': isDefault,
  };

  AddressModel copyWith({
    String? addressId,
    String? phone,
    String? fullAddress,
    String? city,
    String? pincode,
    String? state,
    bool? isDefault,
  }) => AddressModel(
    addressId: addressId ?? this.addressId,
    phone: phone ?? this.phone,
    fullAddress: fullAddress ?? this.fullAddress,
    city: city ?? this.city,
    pincode: pincode ?? this.pincode,
    state: state ?? this.state,
    isDefault: isDefault ?? this.isDefault,
  );

  /// Short display string for address selection UI.
  String get displayShort {
    final parts = [city, state].where((p) => p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : fullAddress;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          addressId == other.addressId;

  @override
  int get hashCode => addressId.hashCode;
}
