import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CustomerService {
  const CustomerService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  /// Creates a customer using the Hyperlocal-Customer-Service
  /// Returns the newly created customer's ID, or throws on error.
  Future<String> createCustomer({
    required String shopId,
    required String name,
    required String mobileNumber,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    // Parse delivery address if provided, otherwise use dummy values
    // to satisfy the required LocationInfos schema.
    final String zipcode = deliveryAddress?['zipcode']?.toString() ?? '000000';
    final String country = deliveryAddress?['country']?.toString() ?? 'India';
    final String state = deliveryAddress?['state']?.toString() ?? 'TN';
    final String fullAddress = deliveryAddress?['address']?.toString() ?? 'Unknown Address';

    final payload = {
      'shop_id': shopId,
      'name': name,
      'contact_infos': {
        'mobile_number': mobileNumber,
      },
      'location_infos': {
        'zipcode': zipcode,
        'country': country,
        'state': state,
        'full_address': fullAddress,
      },
      'can_have_credit': false,
    };

    final response = await http
        .post(
          Uri.parse(ApiConfig.customerCreate),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      
      // Attempt to extract the customer ID from the response
      if (body is Map<String, dynamic>) {
        if (body.containsKey('id')) {
          return body['id'].toString();
        } else if (body.containsKey('data') && body['data'] is Map && body['data'].containsKey('id')) {
          return body['data']['id'].toString();
        }
      }
      
      throw Exception('Failed to parse customer ID from response.');
    } else {
      String errorDetail = 'Failed to create customer (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          errorDetail = body['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorDetail);
    }
  }
}
