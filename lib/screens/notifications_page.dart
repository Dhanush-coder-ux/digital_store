import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Dummy notification data
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "title": "Order Delivered!",
      "message": "Your order from Fresh Mart has been delivered successfully.",
      "time": "Just now",
      "isRead": false,
      "type": "order",
      "icon": LucideIcons.packageCheck,
      "color": AppTheme.successGreen,
    },
    {
      "id": "2",
      "title": "Special Offer \u{1F389}",
      "message": "Get 20% off on your next grocery purchase. Use code: GROCERY20",
      "time": "2 hours ago",
      "isRead": false,
      "type": "promo",
      "icon": LucideIcons.tag,
      "color": AppTheme.warningOrange,
    },
    {
      "id": "3",
      "title": "Payment Successful",
      "message": "We've received your payment of \$45.00 for order #84920.",
      "time": "Yesterday",
      "isRead": true,
      "type": "payment",
      "icon": LucideIcons.creditCard,
      "color": AppTheme.primaryBlue,
    },
    {
      "id": "4",
      "title": "Store Update",
      "message": "Your favorite store 'Grace Super Market' added new items.",
      "time": "Yesterday",
      "isRead": true,
      "type": "update",
      "icon": LucideIcons.store,
      "color": AppTheme.mutedCyan,
    },
    {
      "id": "5",
      "title": "Account Security",
      "message": "A new login was detected from Chrome on Windows.",
      "time": "May 18, 2026",
      "isRead": true,
      "type": "security",
      "icon": LucideIcons.shieldAlert,
      "color": AppTheme.errorRed,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Read All',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.white),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              physics: const BouncingScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 50 * index),
                  child: _buildNotificationItem(notification, index),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final bool isRead = notification['isRead'];
    
    return GestureDetector(
      onTap: () => _markAsRead(index),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.xl,
          vertical: AppTheme.sm,
        ),
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.white : AppTheme.primaryBlue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isRead ? AppTheme.veryLightGray : AppTheme.primaryBlue.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isRead ? AppTheme.shadowSmall : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: notification['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: AppTheme.sm),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Text(
                    notification['message'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    notification['time'] as String,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            Text(
              'No Notifications Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              'We will notify you when something arrives.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
