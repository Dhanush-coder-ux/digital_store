import '../core/network/api_client.dart';
import 'api_config.dart';

class CustomerService {
  final ApiClient _client;

  const CustomerService(this._client);

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

    try {
      final body = await _client.post(
        ApiConfig.customerCreate,
        body: payload,
        requiresAuth: true,
      );

      // Attempt to extract the customer ID from the response
      if (body is Map<String, dynamic>) {
        if (body.containsKey('id')) {
          return body['id'].toString();
        } else if (body.containsKey('data') && body['data'] is Map && body['data'].containsKey('id')) {
          return body['data']['id'].toString();
        }
      }
      
      throw Exception('Failed to parse customer ID from response.');
    } catch (e) {
      // If customer creation fails (e.g. 400 Bad Request because mobile number already exists),
      // we try to fetch the existing customer's ID.
      final existingId = await getCustomerByPhone(shopId, mobileNumber);
      if (existingId != null) {
        return existingId;
      }
      throw Exception('Failed to create customer and could not fetch existing one: $e');
    }
  }

  /// Fetches an existing customer by their phone number for a specific shop.
  Future<String?> getCustomerByPhone(String shopId, String phone) async {
    final url = '${ApiConfig.customerByShop(shopId)}?q=$phone';
    try {
      final body = await _client.get(url, requiresAuth: true);
      if (body is Map<String, dynamic> && body['data'] != null) {
        final data = body['data'];
        if (data is List && data.isNotEmpty) {
          // Return the ID of the first matching customer
          return data[0]['id'].toString();
        }
      }
    } catch (_) {
      // Ignore errors here, we'll return null below
    }
    return null;
  }
}
