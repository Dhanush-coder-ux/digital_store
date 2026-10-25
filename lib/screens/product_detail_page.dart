// lib/screens/product_detail_page.dart
//
// Compatibility wrapper delegating to the unified ApiProductDetailPage.
//

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import 'api_product_detail_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final String storeName;
  final String storeId;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.storeName,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context) {
    // Construct ApiProduct from map
    final apiProduct = ApiProduct.fromJson(product);
    final shop = Shop(
      id: storeId,
      name: storeName,
      categories: const [],
    );

    return ApiProductDetailPage(
      product: apiProduct,
      shop: shop,
    );
  }
}
