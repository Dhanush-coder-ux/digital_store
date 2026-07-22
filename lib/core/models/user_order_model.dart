// lib/core/models/user_order_model.dart
//
// Generated from OpenAPI UserOrderSchema and PaymentInfoSchema.
// Links an order to a user in the DigitalStore service.
//

/// Payment information attached to an order.
/// From PaymentInfoSchema: required: transaction_id, provider, amount
class PaymentInfo {
  final String transactionId;
  final String provider;
  final double amount;

  const PaymentInfo({
    required this.transactionId,
    required this.provider,
    required this.amount,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      transactionId: json['transaction_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'transaction_id': transactionId,
    'provider': provider,
    'amount': amount,
  };

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

/// Links an order to a user with optional payment info.
/// From UserOrderSchema: required: user_id, order_id
class UserOrderLink {
  final String userId;
  final String orderId;
  final PaymentInfo? paymentInfo;
  final DateTime? timestamp;

  const UserOrderLink({
    required this.userId,
    required this.orderId,
    this.paymentInfo,
    this.timestamp,
  });

  factory UserOrderLink.fromJson(Map<String, dynamic> json) {
    return UserOrderLink(
      userId: json['user_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      paymentInfo: json['payment_info'] is Map<String, dynamic>
          ? PaymentInfo.fromJson(json['payment_info'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'order_id': orderId,
    if (paymentInfo != null) 'payment_info': paymentInfo!.toJson(),
  };
}
