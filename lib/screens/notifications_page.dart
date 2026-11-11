import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';
import '../l10n/app_translations.dart';
import '../models/providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'my_orders_page.dart';
import 'my_return_requests_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null && userId.isNotEmpty) {
      await context.read<NotificationsProvider>().fetchNotifications(
        userId,
        silent: context.read<NotificationsProvider>().notifications.isNotEmpty,
      );
    }
  }

  void _markAllAsRead() {
    final userId = context.read<AuthProvider>().userId;
    context.read<NotificationsProvider>().markAllAsRead(userId);
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      context.read<NotificationsProvider>().markAsRead(notification.id);
    }
    final eventType = notification.type.toUpperCase();
    if (eventType.startsWith('RETURN_REQUEST')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyReturnRequestsPage()),
      );
    } else if (eventType == 'ORDER_STATUS') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('notifications'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              context.tr('read_all'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.veryLightGray, height: 1),
        ),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, notificationsProvider, _) {
          final notifications = notificationsProvider.notifications;

          if (notificationsProvider.isLoading && notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          if (notificationsProvider.error != null && notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.wifiOff,
                      size: 40,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: AppTheme.md),
                    Text(
                      context.tr('could_not_load_notifications'),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.md),
                    ElevatedButton.icon(
                      onPressed: _refreshNotifications,
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(context.tr('retry')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              color: AppTheme.primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: _buildEmptyState(),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: AppTheme.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.xl,
                      vertical: AppTheme.sm,
                    ),
                    padding: const EdgeInsets.only(right: AppTheme.xl),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      color: AppTheme.errorRed,
                    ),
                  ),
                  onDismissed: (_) {
                    context.read<NotificationsProvider>().deleteNotification(
                      notification.id,
                    );
                  },
                  child: FadeInUp(
                    delay: Duration(milliseconds: 30 * (index > 10 ? 10 : index)),
                    child: _buildNotificationItem(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final bool isRead = notification.isRead;

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
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
                color: notification.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
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
                          notification.title,
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
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    notification.time,
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
              context.tr('no_notifications_title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              context.tr('no_notifications_sub'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
