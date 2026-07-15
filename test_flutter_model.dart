import 'dart:convert';
import 'lib/models/product_model.dart';

void main() {
  String jsonStr = """{
    "_id": "6a5356115113424c61ee04d5",
    "id": "53206a37-c6e5-5267-92c6-3fe241b8c024",
    "name": "crcokatile T-shirt",
    "batch_infos": [
        {
            "id": "becbe249-49bf-5abc-902d-0b4db854454b",
            "stock_infos": {
                "available_stocks": 68.99
            },
            "pricing_infos": {
                "sell_price": 1230.0
            }
        }
    ]
  }""";
  
  final productData = jsonDecode(jsonStr);
  final product = ApiProduct.fromJson(productData);
  
  print("Product Name: ${product.name}");
  print("Selling Price: ${product.sellingPrice}");
  print("Available Qty: ${product.availableQty}");
  print("Is In Stock: ${product.isInStock}");
}
