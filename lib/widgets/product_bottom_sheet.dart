// lib/widgets/product_bottom_sheet.dart
//
// Instagram-style draggable bottom sheet for product browsing.
// Implements three states: collapsed (peek), expanded, and search-focused.
// Uses Flutter's DraggableScrollableSheet with custom gesture handling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Sheet position state
enum ProductSheetState {
  collapsed,      // Docked peek bar at bottom of mobile (~0.11 viewport)
  half,           // Half screen product discovery (~0.55 viewport)
  expanded,       // Nearly full screen product catalog (~0.93 viewport)
  searchFocused,  // Full screen with search input focused
}

/// Controller exposed to parent to imperatively control the sheet.
class ProductSheetController {
  _ProductBottomSheetState? _state;

  void expand() => _state?._animateTo(ProductSheetState.expanded);
  void expandToHalf() => _state?._animateTo(ProductSheetState.half);
  void collapse() => _state?._animateTo(ProductSheetState.collapsed);

  /// Returns true if the sheet was expanded (and therefore collapsed instead
  /// of navigating back). Parents should call this on back-button press.
  bool handleBackPress() {
    if (_state == null) return false;
    final current = currentState;
    if (current == ProductSheetState.expanded ||
        current == ProductSheetState.half ||
        current == ProductSheetState.searchFocused) {
      _state!._animateTo(ProductSheetState.collapsed);
      return true;
    }
    return false;
  }

  ProductSheetState get currentState =>
      _state?._targetState ?? _state?._sheetState ?? ProductSheetState.collapsed;
}

/// The draggable bottom sheet widget.
///
/// [collapsedFraction] – how much of the viewport the sheet occupies when docked at bottom (default 0.11).
/// [midFraction]       – how much of the viewport the sheet occupies in half-open state (default 0.55).
/// [expandedFraction]  – how much of the viewport the sheet occupies when expanded (default 0.93).
class ProductBottomSheet extends StatefulWidget {
  final ProductSheetController controller;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    ProductSheetState sheetState,
  ) contentBuilder;

  /// The search bar widget, pinned at the top of the sheet.
  final Widget Function(
    BuildContext context,
    ProductSheetState sheetState,
    VoidCallback onTap,
  ) searchBarBuilder;

  /// Optional category filter row, pinned below search.
  final Widget? categoryFilter;

  /// Height of the [categoryFilter] widget in logical pixels.
  /// Must match the actual rendered height to avoid overflow.
  final double categoryFilterHeight;

  /// Shop name shown in the compact expanded header.
  final String shopName;

  /// Snap fractions (proportion of full screen height).
  final double collapsedFraction;
  final double midFraction;
  final double expandedFraction;

  const ProductBottomSheet({
    super.key,
    required this.controller,
    required this.contentBuilder,
    required this.searchBarBuilder,
    required this.shopName,
    this.categoryFilter,
    this.categoryFilterHeight = 56.0,
    this.collapsedFraction = 0.11,
    this.midFraction = 0.55,
    this.expandedFraction = 0.93,
  });

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────
  ProductSheetState _sheetState = ProductSheetState.collapsed;
  ProductSheetState? _targetState;

  // The DraggableScrollableController drives the sheet size (0..1).
  late final DraggableScrollableController _draggableController;

  // Animation controller for spring-like snapping.
  late final AnimationController _springController;
  Animation<double>? _springAnimation;

  // Animation controller for the subtle bounce & pulsing glow indicator.
  late final AnimationController _indicatorController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _glowAnimation;

  // Animation controller for the initial gentle fade-in of the hint text.
  late final AnimationController _fadeController;
  late final Animation<double> _fadeInAnimation;

  // Track if user has interacted with the sheet (stops animation and hides hint).
  bool _hasUserInteracted = false;

  // Whether the inner list is scrolled to its top (controls collapsing).
  bool _innerAtTop = true;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;

    _draggableController = DraggableScrollableController();
    _draggableController.addListener(_onDraggableChanged);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Subtle bounce and pulse indicator (1400ms duration, smooth easeInOut)
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -3.5).animate(
      CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Initial gentle fade-in for the hint text (700ms)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      if (_indicatorController.isAnimating) {
        _indicatorController.stop();
      }
    } else if (!_hasUserInteracted && !_indicatorController.isAnimating) {
      _indicatorController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _draggableController.removeListener(_onDraggableChanged);
    _draggableController.dispose();
    _springController.dispose();
    _indicatorController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onUserInteracted() {
    if (_hasUserInteracted) return;
    _hasUserInteracted = true;
    if (_indicatorController.isAnimating) {
      _indicatorController.stop();
    }
    if (mounted) {
      setState(() {});
    }
  }

  // ── Listeners ────────────────────────────────────────────────────────

  void _onDraggableChanged() {
    if (!_draggableController.isAttached) return;
    final size = _draggableController.size;

    // Detect user dragging the sheet to dismiss hint permanently
    if (!_hasUserInteracted && size > widget.collapsedFraction + 0.015) {
      _onUserInteracted();
    }

    final halfPoint = (widget.collapsedFraction + widget.midFraction) / 2;
    final expandedPoint = (widget.midFraction + widget.expandedFraction) / 2;

    final ProductSheetState newState;
    if (size >= expandedPoint) {
      newState = ProductSheetState.expanded;
    } else if (size >= halfPoint) {
      newState = ProductSheetState.half;
    } else {
      newState = ProductSheetState.collapsed;
    }

    if (newState != _sheetState &&
        _sheetState != ProductSheetState.searchFocused) {
      setState(() => _sheetState = newState);
      HapticFeedback.lightImpact();
    }
  }

  // ── Public control ───────────────────────────────────────────────────

  void _animateTo(ProductSheetState target) {
    if (target != ProductSheetState.collapsed) {
      _onUserInteracted();
    }
    if (_sheetState == target || _targetState == target) return;

    final double targetFraction;
    switch (target) {
      case ProductSheetState.collapsed:
        targetFraction = widget.collapsedFraction;
        break;
      case ProductSheetState.half:
        targetFraction = widget.midFraction;
        break;
      case ProductSheetState.expanded:
      case ProductSheetState.searchFocused:
        targetFraction = widget.expandedFraction;
        break;
    }

    if (!_draggableController.isAttached) return;

    _targetState = target;
    final startFraction = _draggableController.size;
    final endFraction = targetFraction;

    // Use smooth easeOutCubic curve for organic feel.
    _springController.reset();
    _springAnimation = Tween<double>(
      begin: startFraction,
      end: endFraction,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));

    _springAnimation!.addListener(() {
      if (_draggableController.isAttached) {
        _draggableController.jumpTo(_springAnimation!.value);
      }
    });

    _springController.forward().then((_) {
      if (mounted) {
        setState(() {
          _sheetState = target;
          _targetState = null;
        });
      }
    });
  }

  void _onSearchTap() {
    _onUserInteracted();
    if (_sheetState != ProductSheetState.expanded &&
        _sheetState != ProductSheetState.searchFocused) {
      _animateTo(ProductSheetState.expanded);
    }
    if (mounted) setState(() => _sheetState = ProductSheetState.searchFocused);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isDesktop = screenWidth >= 1024;

    // On desktop, render inline instead of as a draggable sheet.
    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: widget.collapsedFraction,
      minChildSize: widget.collapsedFraction,
      maxChildSize: widget.expandedFraction,
      snap: true,
      snapSizes: [
        widget.collapsedFraction,
        widget.midFraction,
        widget.expandedFraction,
      ],
      snapAnimationDuration: const Duration(milliseconds: 320),
      builder: (context, scrollController) {
        // Track whether the inner list is at top.
        scrollController.addListener(() {
          final atTop = scrollController.offset <= 0;
          if (atTop != _innerAtTop && mounted) {
            setState(() => _innerAtTop = atTop);
          }
        });

        return _buildSheetContent(scrollController);
      },
    );
  }

  Widget _buildSheetContent(ScrollController scrollController) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGray.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: CustomScrollView(
          controller: scrollController,
          physics: _innerAtTop
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          slivers: [
            // ── Sticky header (drag handle + search + categories) ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _SheetHeaderDelegate(
                sheetState: _sheetState,
                shopName: widget.shopName,
                searchBar: widget.searchBarBuilder(
                    context, _sheetState, _onSearchTap),
                categoryFilter: widget.categoryFilter,
                categoryFilterHeight: widget.categoryFilterHeight,
                onCollapse: () => _animateTo(ProductSheetState.collapsed),
                onExpand: () => _animateTo(ProductSheetState.half),
                bounceAnimation: _bounceAnimation,
                glowAnimation: _glowAnimation,
                fadeInAnimation: _fadeInAnimation,
                hasUserInteracted: _hasUserInteracted,
                disableAnimations: disableAnimations,
              ),
            ),

            // ── Product content ──
            widget.contentBuilder(context, scrollController, _sheetState),

            // Extra bottom padding for cart bar clearance.
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    // On desktop, show products in a normal scrollable section (no sheet).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        widget.searchBarBuilder(context, ProductSheetState.expanded, () {}),
        if (widget.categoryFilter != null) widget.categoryFilter!,
        Expanded(
          child: widget.contentBuilder(
            context,
            ScrollController(),
            ProductSheetState.expanded,
          ),
        ),
      ],
    );
  }
}

// ── SliverPersistentHeaderDelegate for the sticky sheet header ─────────

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProductSheetState sheetState;
  final String shopName;
  final Widget searchBar;
  final Widget? categoryFilter;
  final double categoryFilterHeight;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;
  final Animation<double> bounceAnimation;
  final Animation<double> glowAnimation;
  final Animation<double> fadeInAnimation;
  final bool hasUserInteracted;
  final bool disableAnimations;

  const _SheetHeaderDelegate({
    required this.sheetState,
    required this.shopName,
    required this.searchBar,
    required this.categoryFilter,
    required this.categoryFilterHeight,
    required this.onCollapse,
    required this.onExpand,
    required this.bounceAnimation,
    required this.glowAnimation,
    required this.fadeInAnimation,
    required this.hasUserInteracted,
    required this.disableAnimations,
  });

  static const double _dragHandleArea = 32.0;
  static const double _searchBarArea = 56.0;
  static const double _expandedHeaderArea = 46.0;

  double get _total {
    final bool isExpanded = sheetState == ProductSheetState.expanded ||
        sheetState == ProductSheetState.searchFocused;
    final bool isHalf = sheetState == ProductSheetState.half;

    double h = (isExpanded ? _expandedHeaderArea : _dragHandleArea) +
        _searchBarArea;
    // Category filter is visible in half and expanded states, but hidden when docked at bottom
    if (categoryFilter != null && (isExpanded || isHalf)) {
      h += categoryFilterHeight;
    }
    return h;
  }

  @override
  double get maxExtent => _total;

  @override
  double get minExtent => _total;

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate old) =>
      old.sheetState != sheetState ||
      old.shopName != shopName ||
      old.categoryFilter != categoryFilter ||
      old.categoryFilterHeight != categoryFilterHeight ||
      old.hasUserInteracted != hasUserInteracted ||
      old.disableAnimations != disableAnimations ||
      old.bounceAnimation != bounceAnimation ||
      old.glowAnimation != glowAnimation ||
      old.fadeInAnimation != fadeInAnimation;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isExpanded = sheetState == ProductSheetState.expanded ||
        sheetState == ProductSheetState.searchFocused;
    final isHalf = sheetState == ProductSheetState.half;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: overlapsContent
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.veryLightGray,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle OR expanded compact header
          if (!isExpanded)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (sheetState == ProductSheetState.collapsed) {
                  onExpand();
                } else if (sheetState == ProductSheetState.half) {
                  onCollapse();
                }
              },
              child: SizedBox(
                height: _dragHandleArea,
                child: _buildDragHandleContent(context),
              ),
            )
          else
            _buildExpandedCompactHeader(context),

          // Search bar
          SizedBox(
            height: _searchBarArea,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: searchBar,
            ),
          ),

          // Category filter row (visible in half and expanded states)
          if (categoryFilter != null && (isExpanded || isHalf))
            SizedBox(
              height: categoryFilterHeight,
              child: categoryFilter!,
            ),
        ],
      ),
    );
  }

  Widget _buildDragHandleContent(BuildContext context) {
    // If user has interacted or sheet is not collapsed, show clean static handle
    if (hasUserInteracted || sheetState != ProductSheetState.collapsed) {
      return _buildStaticHandle();
    }

    // If user prefers reduced motion, show static indicator with label (no animation)
    if (disableAnimations) {
      return _buildStaticIndicator();
    }

    // Subtle animated indicator with pulsing glow and float
    return AnimatedBuilder(
      animation: bounceAnimation,
      builder: (context, _) => _buildAnimatedIndicator(),
    );
  }

  Widget _buildStaticHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0D6CC),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStaticIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD6C8BB),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 13,
              color: AppTheme.primaryBlue.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 2),
            Text(
              'Swipe up to explore products',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: AppTheme.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedIndicator() {
    final glow = glowAnimation.value;
    final bounce = bounceAnimation.value;

    return Transform.translate(
      offset: Offset(0, bounce),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Drag handle pill with subtle glow pulse
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFFD6C8BB),
                AppTheme.primaryBlue,
                0.35 * glow,
              ),
              borderRadius: BorderRadius.circular(2.5),
              boxShadow: glow > 0.05
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.20 * glow),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 3),
          // Subtle label with mini upward chevron and gentle fade-in
          FadeTransition(
            opacity: fadeInAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 13,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 2),
                Text(
                  'Swipe up to explore products',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    color: AppTheme.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCompactHeader(BuildContext context) {
    return SizedBox(
      height: _expandedHeaderArea,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            // Back/Collapse button
            GestureDetector(
              onTap: onCollapse,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                shopName,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
