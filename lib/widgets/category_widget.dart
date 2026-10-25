// lib/widgets/category_widget.dart
//
// Blinkit & Zepto-inspired realistic product category components
// Featuring realistic imagery, soft peach/cream backgrounds, Warm Tangerine theme integration,
// and optimized caching via CachedNetworkImage.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';

/// Horizontally scrollable category item for Home and Store pages.
class CategoryRowItem extends StatelessWidget {
  final CategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double containerSize;
  final EdgeInsetsGeometry margin;

  const CategoryRowItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.containerSize = 60.0,
    this.margin = const EdgeInsets.only(right: 14.0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: margin,
        width: containerSize + 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Container with realistic product thumbnail
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.softPeach : const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCategoryImage(item),
              ),
            ),
            const SizedBox(height: 6),
            // Category Name Label
            Text(
              item.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                height: 1.15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryDark : AppTheme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(CategoryItem item) {
    if (item.assetPath != null && item.assetPath!.isNotEmpty) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(item),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFF2ECE1),
        highlightColor: Colors.white,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _buildFallback(item),
    );
  }

  Widget _buildFallback(CategoryItem item) {
    return Container(
      color: AppTheme.softPeach,
      alignment: Alignment.center,
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '•',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

/// Attractive responsive category card for the All Categories page grid.
class CategoryGridCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback onTap;

  const CategoryGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Container with soft cream background
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF6F0),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(item),
                  ),
                ),
              ),
              // Category Details
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
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

  Widget _buildImage(CategoryItem item) {
    if (item.assetPath != null && item.assetPath!.isNotEmpty) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(item),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: const Color(0xFFF2ECE1),
        highlightColor: Colors.white,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _buildFallback(item),
    );
  }

  Widget _buildFallback(CategoryItem item) {
    return Container(
      color: AppTheme.softPeach,
      alignment: Alignment.center,
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '•',
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

/// Compact chip / pill item with realistic mini thumbnail for filter rows
class CategoryPillItem extends StatelessWidget {
  final CategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryPillItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.softPeach : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini realistic thumbnail
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.softPeach),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.softPeach),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              item.name,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryDark : AppTheme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
