import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class OrderProcessingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const OrderProcessingOverlay({super.key, required this.onComplete});

  @override
  State<OrderProcessingOverlay> createState() => _OrderProcessingOverlayState();
}

class _OrderProcessingOverlayState extends State<OrderProcessingOverlay>
    with SingleTickerProviderStateMixin {

  int _step = 0; // 0=processing, 1=paid, 2=confirmed
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _steps = [
    _OrderStep(
      icon: LucideIcons.creditCard,
      label: 'Processing Payment',
      sublabel: 'Verifying your card...',
    ),
    _OrderStep(
      icon: LucideIcons.checkCircle2,
      label: 'Payment Successful',
      sublabel: 'Transaction complete!',
    ),
    _OrderStep(
      icon: LucideIcons.packageCheck,
      label: 'Order Confirmed',
      sublabel: 'Your order is being prepared.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _step = 1);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _step = 2);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_step];
    final isSuccess = _step > 0;
    final isDone = _step == 2;

    return Material(
      color: AppTheme.darkGray.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.xxxl),
          padding: const EdgeInsets.all(AppTheme.xxxl),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXxl + 8),
            boxShadow: AppTheme.shadowXlarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon area
              ScaleTransition(
                scale: isSuccess ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
                child: AnimatedSwitcher(
                  duration: AppDurations.normal,
                  switchInCurve: Curves.elasticOut,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey<int>(_step),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppTheme.successGreen.withOpacity(0.12)
                          : isSuccess
                              ? AppTheme.successGreen.withOpacity(0.12)
                              : AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentStep.icon,
                      size: 36,
                      color: isDone || isSuccess
                          ? AppTheme.successGreen
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              // Step label
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Text(
                  currentStep.label,
                  key: ValueKey<String>(currentStep.label),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.xs),
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: Text(
                  currentStep.sublabel,
                  key: ValueKey<String>(currentStep.sublabel),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.xxl),
              // Step progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isActive = i == _step;
                  final isDone = i < _step;
                  return AnimatedContainer(
                    duration: AppDurations.normal,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? AppTheme.successGreen
                          : AppTheme.veryLightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStep {
  final IconData icon;
  final String label;
  final String sublabel;

  const _OrderStep({
    required this.icon,
    required this.label,
    required this.sublabel,
  });
}
