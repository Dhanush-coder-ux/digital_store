// lib/services/notification_service.dart
//
// Service layer for fetching, marking as read, and deleting
// real-time & persisted notifications via Hyperlocal-Notification-Service.
//

import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import 'api_config.dart';

class NotificationService {
  final ApiClient _client;

  const NotificationService(this._client);

  Future<List<Map<String, dynamic>>> fetchNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 100,
  }) async {
    final body = await _client.get(
      ApiConfig.notificationsList,
      queryParams: {
        'user_id': userId,
        'unread_only': unreadOnly.toString(),
        'limit': limit.toString(),
        'scope': 'digital_store',
        'audience': 'customer',
      },
      requiresAuth: true,
    );

    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['notifications'] ?? body['items'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client.patch(
        ApiConfig.notificationMarkRead(notificationId),
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] markAsRead error: $e');
      }
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      await _client.patch(
        ApiConfig.notificationsMarkAllRead,
        queryParams: {'user_id': userId},
        body: {'user_id': userId},
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] markAllAsRead error: $e');
      }
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.delete(
        ApiConfig.notificationDelete(notificationId),
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] deleteNotification error: $e');
      }
      return false;
    }
  }

  Future<bool> clearAllNotifications(String userId) async {
    try {
      await _client.delete(
        ApiConfig.notificationsClearAll,
        queryParams: {'user_id': userId},
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] clearAllNotifications error: $e');
      }
      return false;
    }
  }
}

