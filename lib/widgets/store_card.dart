import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/review_provider.dart';

class StoreCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String shopId;
  final String time;
  final String distance;
  final List<String> categories;
  final bool isOpen;
  final bool isVerified;
  final VoidCallback? onTap;
  final String? heroTag;

  const StoreCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.shopId,
    required this.time,
    required this.distance,
    required this.categories,
    this.isOpen = true,
    this.isVerified = false,
    this.onTap,
    this.heroTag,
  });

  @override
  State<StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
            border: Border.all(color: AppTheme.veryLightGray, width: 1),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppTheme.radiusXxl),
                      ),
                      child: widget.heroTag != null
                          ? Hero(
                              tag: widget.heroTag!,
                              child: _buildImage(),
                            )
                          : _buildImage(),
                    ),
                    // Open/Closed badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildStatusBadge(),
                    ),
                  ],
                ),
              ),
              // Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(LucideIcons.checkCircle, color: AppTheme.primaryBlue, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Rating & Categories
                      Row(
                        children: [
                          _buildRatingChip(context),
                          if (widget.categories.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.categories.join(' • '),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Info chips row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(context, LucideIcons.clock, widget.time),
                          _buildInfoChip(context, LucideIcons.mapPin, widget.distance),
                          _buildFreeDeliveryChip(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppTheme.veryLightGray,
        child: const Center(
          child: Icon(
            LucideIcons.store,
            color: AppTheme.textTertiary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: widget.isOpen
            ? AppTheme.successGreen.withOpacity(0.85)
            : AppTheme.errorRed.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Text(
        widget.isOpen ? 'OPEN' : 'CLOSED',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRatingChip(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        final rating = provider.averageRatingForShop(widget.shopId);
        final count = provider.reviewCountForShop(widget.shopId);
        
        if (count == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.sm,
            vertical: AppTheme.xs,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '($count)',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sm,
        vertical: AppTheme.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeDeliveryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sm,
        vertical: AppTheme.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.truck, size: 12, color: AppTheme.successGreen),
          const SizedBox(width: 4),
          Text(
            'Free',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}
