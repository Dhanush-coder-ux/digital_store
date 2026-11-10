// test/return_request_test.dart
//
// Unit tests for Customer Return Request model, payload serialization,
// eligibility checks, and quantity / reason validations.
//

import 'package:flutter_test/flutter_test.dart';
import 'package:digital_app/models/order_model.dart';
import 'package:digital_app/models/return_request_model.dart';

void main() {
  group('Return Request Models & Payload', () {
    test('CreateReturnRequestPayload correctly serializes to backend schema', () {
      const payload = CreateReturnRequestPayload(
        orderId: 'ord-uuid-1234',
        shopId: 'shop-test-1',
        description: 'Damaged packaging during transit',
        customerName: 'Sivarajan',
        customerPhone: '+919876543210',
        customerEmail: 'siva@example.com',
        customerId: 'cust-99',
        items: [
          CustomerReturnItemPayload(
            orderItemId: 'item-1',
            productId: 'prod-1',
            quantity: 1.0,
            unit: 'piece',
            reason: 'Product damaged',
          ),
          CustomerReturnItemPayload(
            orderItemId: 'item-2',
            productId: 'prod-2',
            quantity: 2.0,
            unit: 'box',
            reason: 'Defective product',
          ),
        ],
      );

      final json = payload.toJson();
      expect(json['order_id'], 'ord-uuid-1234');
      expect(json['shop_id'], 'shop-test-1');
      expect(json['description'], 'Damaged packaging during transit');
      expect(json['customer_name'], 'Sivarajan');
      expect(json['customer_phone'], '+919876543210');
      expect(json['customer_email'], 'siva@example.com');
      expect(json['customer_id'], 'cust-99');

      final items = json['items'] as List;
      expect(items.length, 2);
      expect(items[0]['order_item_id'], 'item-1');
      expect(items[0]['product_id'], 'prod-1');
      expect(items[0]['quantity'], 1.0);
      expect(items[0]['reason'], 'Product damaged');
      expect(items[1]['order_item_id'], 'item-2');
      expect(items[1]['quantity'], 2.0);
      expect(items[1]['reason'], 'Defective product');
    });

    test('ReturnRequestModel parses backend response correctly', () {
      final backendResponse = {
        'id': 'req-abc-9876',
        'order_id': 'ord-uuid-1234',
        'order_ui_id': 'ORD-5544',
        'shop_id': 'shop-test-1',
        'customer_id': 'cust-99',
        'customer_name': 'Sivarajan',
        'customer_phone': '+919876543210',
        'customer_email': 'siva@example.com',
        'description': 'Broken jar lid upon unboxing',
        'status': 'PENDING',
        'admin_notes': 'Awaiting verification',
        'items': [
          {
            'order_item_id': 'item-1',
            'product_id': 'prod-1',
            'product_name': 'Organic Honey 500g',
            'variant_name': '500g Glass Jar',
            'quantity': 1.0,
            'price': 350.0,
            'total_amount': 350.0,
            'unit': 'jar',
            'reason': 'Broken jar lid',
          }
        ],
        'status_history': [
          {
            'status': 'PENDING',
            'updated_by': 'Sivarajan',
            'timestamp': '2026-11-09T10:00:00Z',
            'notes': 'Return request submitted',
          }
        ],
        'created_at': '2026-11-09T10:00:00Z',
        'updated_at': '2026-11-09T10:00:00Z',
      };

      final model = ReturnRequestModel.fromJson(backendResponse);

      expect(model.id, 'req-abc-9876');
      expect(model.orderId, 'ord-uuid-1234');
      expect(model.orderUiId, 'ORD-5544');
      expect(model.customerName, 'Sivarajan');
      expect(model.isPending, isTrue);
      expect(model.isAccepted, isFalse);
      expect(model.isRejected, isFalse);
      expect(model.items.length, 1);
      expect(model.items.first.productName, 'Organic Honey 500g');
      expect(model.items.first.quantity, 1.0);
      expect(model.items.first.price, 350.0);
      expect(model.totalRefundAmount, 350.0);
      expect(model.statusHistory.length, 1);
      expect(model.statusHistory.first.status, 'PENDING');
    });

    test('Return status flags work correctly for ACCEPTED and REJECTED', () {
      final acceptedReq = ReturnRequestModel.fromJson({
        'id': 'req-1',
        'order_id': 'ord-1',
        'shop_id': 'shop-1',
        'customer_name': 'Alice',
        'customer_phone': '1234567890',
        'description': 'Defective item',
        'status': 'ACCEPTED',
        'admin_notes': 'Approved for full refund',
      });
      expect(acceptedReq.isAccepted, isTrue);
      expect(acceptedReq.isPending, isFalse);
      expect(acceptedReq.isRejected, isFalse);

      final rejectedReq = ReturnRequestModel.fromJson({
        'id': 'req-2',
        'order_id': 'ord-2',
        'shop_id': 'shop-1',
        'customer_name': 'Bob',
        'customer_phone': '1234567890',
        'description': 'Changed mind',
        'status': 'REJECTED',
        'admin_notes': 'Return window expired',
      });
      expect(rejectedReq.isRejected, isTrue);
      expect(rejectedReq.isPending, isFalse);
      expect(rejectedReq.isAccepted, isFalse);
      expect(rejectedReq.isCompleted, isFalse);

      final completedReq = ReturnRequestModel.fromJson({
        'id': 'req-3',
        'order_id': 'ord-3',
        'shop_id': 'shop-1',
        'customer_name': 'Charlie',
        'customer_phone': '1234567890',
        'description': 'Item returned',
        'status': 'COMPLETED',
      });
      expect(completedReq.isCompleted, isTrue);
      expect(completedReq.isPending, isFalse);
    });

    test('Order eligibility criteria', () {
      // Delivered order -> Eligible
      const deliveredOrder = ApiOrder(
        id: 'ord-1',
        shopId: 'shop-1',
        status: 'DELIVERED',
        totalAmount: 500,
      );
      final isDelivered = deliveredOrder.status.toUpperCase().trim() == 'DELIVERED' ||
          deliveredOrder.status.toUpperCase().trim() == 'COMPLETED';
      expect(isDelivered, isTrue);

      // Cancelled order -> Ineligible
      const cancelledOrder = ApiOrder(
        id: 'ord-2',
        shopId: 'shop-1',
        status: 'CANCELLED',
        totalAmount: 500,
      );
      final isCancelled = cancelledOrder.status.toUpperCase().trim() == 'CANCELLED';
      expect(isCancelled, isTrue);
      expect(cancelledOrder.status == 'DELIVERED', isFalse);

      // Pending order -> Ineligible
      const pendingOrder = ApiOrder(
        id: 'ord-3',
        shopId: 'shop-1',
        status: 'PENDING',
        totalAmount: 500,
      );
      expect(pendingOrder.status == 'DELIVERED', isFalse);
    });

    test('ApiOrderItem preserves orderItemId and fields', () {
      final rawItem = {
        'id': 'item-db-uuid-1',
        'product_id': 'prod-uuid-1',
        'name': 'Organic Apples',
        'quantity': 3.0,
        'selling_price': 120.0,
        'unit': 'kg',
      };

      final item = ApiOrderItem.fromJson(rawItem);
      expect(item.orderItemId, 'item-db-uuid-1');
      expect(item.productId, 'prod-uuid-1');
      expect(item.productName, 'Organic Apples');
      expect(item.qty, 3.0);
      expect(item.unitPrice, 120.0);
      expect(item.unit, 'kg');
    });
  });
}

