import 'dart:convert';
import 'dart:io';

double parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

List<Map<String, dynamic>> parseListOfMaps(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
}

void main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse("http://127.0.0.1:8900/api/inventories/inventories/by/shop/766188f9-3fa3-5a1a-931d-07c4eeced506"));
  final response = await request.close();
  final resBody = await response.transform(utf8.decoder).join();
  
  final json = jsonDecode(resBody);
  final List data = json["data"] ?? [];
  
  for (var productData in data) {
    print("--- Product: \${productData['name']} ---");
    
    List<Map<String, dynamic>> parsedVariants = [];
    if (productData["variants"] is Map) {
      final vMap = productData["variants"] as Map;
      parsedVariants = vMap.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (productData["variants"] is List) {
      parsedVariants = parseListOfMaps(productData["variants"]);
    }
    List<Map<String, dynamic>> parsedBatches = parseListOfMaps(productData["batch_infos"] ?? productData["batches"]);
    
    print("Parsed variants: \${parsedVariants.length}");
    print("Parsed batches: \${parsedBatches.length}");
    
    double extractedSellingPrice = parseDouble(productData["selling_price"] ?? productData["price"]);
    double extractedQty = 0;

    final topPricing = productData["pricing_infos"] is Map ? productData["pricing_infos"] as Map : {};
    if (topPricing.containsKey("sell_price")) {
      extractedSellingPrice = parseDouble(topPricing["sell_price"]);
    }

    final topStock = productData["stock_infos"] is Map ? productData["stock_infos"] as Map : {};
    if (topStock.containsKey("available_stocks")) {
      extractedQty = parseDouble(topStock["available_stocks"]);
    }

    if ((extractedSellingPrice == 0 || extractedQty == 0) && parsedBatches.isNotEmpty) {
      final b = parsedBatches.first;
      final bPricing = b["pricing_infos"] is Map ? b["pricing_infos"] as Map : {};
      final bStock = b["stock_infos"] is Map ? b["stock_infos"] as Map : {};
      if (extractedSellingPrice == 0 && bPricing.containsKey("sell_price")) {
        extractedSellingPrice = parseDouble(bPricing["sell_price"]);
      }
      if (extractedQty == 0 && bStock.containsKey("available_stocks")) {
        extractedQty = parseDouble(bStock["available_stocks"]);
      }
    }
    
    if ((extractedSellingPrice == 0 || extractedQty == 0) && parsedVariants.isNotEmpty) {
      final v = parsedVariants.first;
      final vPricing = v["pricing_infos"] is Map ? v["pricing_infos"] as Map : {};
      final vStock = v["stock_infos"] is Map ? v["stock_infos"] as Map : {};
      if (extractedSellingPrice == 0 && vPricing.containsKey("sell_price")) {
        extractedSellingPrice = parseDouble(vPricing["sell_price"]);
      }
      if (extractedQty == 0 && vStock.containsKey("available_stocks")) {
        extractedQty = parseDouble(vStock["available_stocks"]);
      }
    }
    
    print("Price: \$extractedSellingPrice");
    print("Qty: \$extractedQty");
  }
}
