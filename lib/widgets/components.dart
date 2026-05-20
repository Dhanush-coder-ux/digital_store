import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// RESPONSIVE CONTAINER
// ═══════════════════════════════════════════════════════════════════════════

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool centered;
  
  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.centered = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? AppTheme.lg : AppTheme.xl,
      vertical: isMobile ? AppTheme.lg : AppTheme.xxl,
    );
    
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: padding ?? screenPadding,
        child: centered
          ? Center(child: child)
          : child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// APP BAR - Premium Header
// ═══════════════════════════════════════════════════════════════════════════

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final double? elevation;
  
  const PremiumAppBar({
    Key? key,
    required this.title,
    this.onBack,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.elevation = 0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor ?? AppTheme.white,
      elevation: elevation ?? 0,
      leading: showBackButton
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: onBack ?? () => Navigator.pop(context),
          )
        : null,
      actions: actions,
      centerTitle: false,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(64);
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CARD - Glassmorphism Component
// ═══════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Border? border;
  
  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.lg),
    this.backgroundColor,
    this.borderRadius = AppTheme.radiusXl,
    this.onTap,
    this.shadows,
    this.border,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(
            color: AppTheme.veryLightGray.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: shadows ?? AppTheme.shadowMedium,
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final LinearGradient? gradient;
  final bool isOutlined;
  final IconData? icon;
  
  const GradientButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.gradient,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);
  
  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(_) {
    _controller.forward();
  }
  
  void _handleTapUp(_) {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: OutlinedButton(
          onPressed: widget.isEnabled && !widget.isLoading
            ? widget.onPressed
            : null,
          child: widget.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon),
                    const SizedBox(width: AppTheme.sm),
                  ],
                  Text(widget.label),
                ],
              ),
        ),
      );
    }
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          gradient: widget.gradient ?? AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: widget.isEnabled ? AppTheme.shadowMedium : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: widget.isEnabled ? _handleTapDown : null,
            onTapUp: widget.isEnabled ? _handleTapUp : null,
            onTapCancel: _controller.reverse,
            onTap: widget.isEnabled && !widget.isLoading
              ? widget.onPressed
              : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.lg,
                vertical: AppTheme.md,
              ),
              child: Center(
                child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: AppTheme.white),
                          const SizedBox(width: AppTheme.sm),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class LoadingState extends StatelessWidget {
  final String? message;
  
  const LoadingState({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.lg),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.lightGray.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xxl),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppTheme.xxl),
              GradientButton(
                label: actionLabel!,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════════════════════

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  
  const ErrorState({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.xl),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.xxl),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.xxl),
              GradientButton(
                label: retryLabel ?? AppStrings.retry,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING
// ═══════════════════════════════════════════════════════════════════════════

class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  
  const ShimmerLoading({
    Key? key,
    this.itemCount = 3,
    this.height = 100,
    this.borderRadius = AppTheme.radiusLg,
    this.padding = const EdgeInsets.symmetric(
      vertical: AppTheme.md,
      horizontal: AppTheme.lg,
    ),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: padding,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SNACKBAR
// ═══════════════════════════════════════════════════════════════════════════

void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.white),
          const SizedBox(width: AppTheme.lg),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppTheme.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
  );
}

void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.white),
          const SizedBox(width: AppTheme.lg),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppTheme.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
  );
}

void showInfoSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.white),
          const SizedBox(width: AppTheme.lg),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.infoBlue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppTheme.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DIVIDER WITH TEXT
// ═══════════════════════════════════════════════════════════════════════════

class DividerWithText extends StatelessWidget {
  final String text;
  
  const DividerWithText({Key? key, required this.text}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INPUT FIELD
// ═══════════════════════════════════════════════════════════════════════════

class PremiumTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  
  const PremiumTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
  }) : super(key: key);
  
  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  late bool _isObscured;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isObscured = widget.obscureText;
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.sm),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: _isObscured,
          maxLines: _isObscured ? 1 : widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon)
              : null,
            suffixIcon: widget.suffixIcon != null
              ? widget.suffixIcon == Icons.visibility
                ? IconButton(
                    icon: Icon(
                      _isObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _isObscured = !_isObscured);
                    },
                  )
                : IconButton(
                    icon: Icon(widget.suffixIcon),
                    onPressed: widget.onSuffixTap,
                  )
              : null,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGE
// ═══════════════════════════════════════════════════════════════════════════

class PremiumBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  
  const PremiumBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: (backgroundColor ?? AppTheme.primaryBlue).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor ?? AppTheme.primaryBlue),
            const SizedBox(width: AppTheme.xs),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
