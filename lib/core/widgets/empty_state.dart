// lib/core/widgets/empty_state.dart
//
// Reusable empty state widget for when lists have no data.
// Provides predefined states for common scenarios.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  factory EmptyStateWidget.noShops({VoidCallback? onRetry}) => EmptyStateWidget(
    icon: LucideIcons.store,
    title: 'No Shops Available',
    subtitle: 'There are no shops near you right now.\nCheck back later!',
    actionLabel: 'Refresh',
    onAction: onRetry,
  );

  factory EmptyStateWidget.noProducts() => const EmptyStateWidget(
    icon: LucideIcons.package2,
    title: 'No Products Yet',
    subtitle: 'This shop hasn\'t added any products yet.',
  );

  factory EmptyStateWidget.noOrders() => const EmptyStateWidget(
    icon: LucideIcons.shoppingBag,
    title: 'No Orders Yet',
    subtitle: 'Your order history will appear here\nafter your first purchase.',
  );

  factory EmptyStateWidget.noFavorites() => const EmptyStateWidget(
    icon: LucideIcons.heart,
    title: 'No Favorites Yet',
    subtitle: 'Products and shops you love\nwill appear here.',
  );

  factory EmptyStateWidget.noReviews() => const EmptyStateWidget(
    icon: LucideIcons.messageSquare,
    title: 'No Reviews Yet',
    subtitle: 'Be the first to review this shop!',
  );

  factory EmptyStateWidget.noSearchResults() => const EmptyStateWidget(
    icon: LucideIcons.search,
    title: 'No Results Found',
    subtitle: 'Try a different search term.',
  );

  factory EmptyStateWidget.noAddresses({VoidCallback? onAdd}) => EmptyStateWidget(
    icon: LucideIcons.mapPin,
    title: 'No Saved Addresses',
    subtitle: 'Add a delivery address to get started.',
    actionLabel: 'Add Address',
    onAction: onAdd,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue.withOpacity(0.5),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: BorderSide(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
