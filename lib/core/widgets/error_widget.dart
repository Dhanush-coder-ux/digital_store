// lib/core/widgets/error_widget.dart
//
// Reusable error display with retry button.
// Supports various error types: no internet, server, auth, not found.
//

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.actionLabel,
    this.onRetry,
    this.icon = LucideIcons.alertTriangle,
  });

  /// Predefined error for no internet
  factory AppErrorWidget.noInternet({VoidCallback? onRetry}) => AppErrorWidget(
    message: 'No internet connection.\nCheck your network and try again.',
    icon: LucideIcons.wifiOff,
    onRetry: onRetry,
  );

  /// Predefined error for server errors
  factory AppErrorWidget.server({VoidCallback? onRetry}) => AppErrorWidget(
    message: 'Something went wrong on our end.\nPlease try again later.',
    icon: LucideIcons.serverCrash,
    onRetry: onRetry,
  );

  /// Predefined error for unauthorized
  factory AppErrorWidget.unauthorized({VoidCallback? onRetry}) => AppErrorWidget(
    message: 'Your session has expired.\nPlease log in again.',
    icon: LucideIcons.logIn,
    actionLabel: 'Log In',
    onRetry: onRetry,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.errorRed, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionLabel ?? 'Try Again',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
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
