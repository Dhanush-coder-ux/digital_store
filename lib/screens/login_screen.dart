// lib/screens/login_screen.dart
//
// OAuth login & onboarding screen with warm faded yellow-orange / caramel ShopiQ branding.
// Displays app logo, storefront illustration, animated waves, and OAuth login handler.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLaunching = false;
  late AnimationController _pinController;
  late Animation<double> _pinBobAnimation;

  @override
  void initState() {
    super.initState();
    // Gentle floating animation for the location pin
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pinBobAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _pinController, curve: Curves.easeInOut),
    );

    // Listen for auth state changes (deep link callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (authProvider.error != null && authProvider.error!.isNotEmpty) {
      _showError(authProvider.error!);
      authProvider.clearError();
    }

    if (authProvider.isAuthenticated) {
      authProvider.removeListener(_onAuthStateChanged);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _handleSignIn() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final loginUrl = await authProvider.getLoginUrl();

      if (loginUrl != null && loginUrl.isNotEmpty) {
        final uri = Uri.parse(loginUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showError('Could not open login page.');
        }
      } else {
        _showError(authProvider.error ?? 'Failed to get login URL.');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  /// Skip login and continue as guest.
  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    try {
      context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          // ── Top-Left Faded Amber Organic Curve ───────────────
          Positioned(
            top: -75,
            left: -75,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightBlue.withValues(alpha: 0.6),
                    AppTheme.skyBlue.withValues(alpha: 0.4),
                    AppTheme.bgSecondary,
                  ],
                ),
              ),
            ),
          ),

          // ── Top-Left Translucent Floating Accent Circle ──────────────
          Positioned(
            top: 150,
            left: 28,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.softPeach.withValues(alpha: 0.65),
              ),
            ),
          ),

          // ── Top-Right Dot Matrix Grid ────────────────────────────────
          const Positioned(
            top: 72,
            right: 28,
            child: _DotMatrixDecoration(),
          ),

          // ── Midground Storefront Illustration & Bottom Wave ─────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pinBobAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ShopiQStoreIllustrationPainter(
                    pinOffsetY: _pinBobAnimation.value,
                  ),
                );
              },
            ),
          ),

          // ── Main UI Content Layer ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── App Logo ──────────────────────────────────────────
                  FadeInDown(
                    duration: const Duration(milliseconds: 750),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withValues(alpha: 0.28),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/Vivid S-Cart Shopping Icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Welcome to ShopiQ Headings ──────────────────────
                  FadeInUp(
                    duration: const Duration(milliseconds: 650),
                    delay: const Duration(milliseconds: 150),
                    child: Column(
                      children: [
                        Text(
                          'Welcome to',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ShopiQ',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryBlue,
                            letterSpacing: -0.8,
                            height: 1.12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subtitle ──────────────────────────────────────────
                  FadeInUp(
                    duration: const Duration(milliseconds: 650),
                    delay: const Duration(milliseconds: 280),
                    child: Text(
                      'Discover local shops, browse products,\nand order with ease.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),

                  // Flexible spacer allows content to adapt across screen sizes
                  const Spacer(),

                  // ── Action Buttons (Over Bottom Faded Yellow-Orange Wave)
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 400),
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final loading = _isLaunching || auth.isLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: loading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryBlue,
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
                              elevation: 4,
                              shadowColor: AppTheme.textPrimary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(color: AppTheme.veryLightGray),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        LucideIcons.logIn,
                                        size: 20,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Sign In',
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryBlue,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Continue as Guest ────────────────────────────────
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 500),
                    child: TextButton(
                      onPressed: _continueAsGuest,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Continue as Guest',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.85),
                          decorationThickness: 1.5,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.035),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5x5 Dot Matrix decorative element in soft yellow-orange
class _DotMatrixDecoration extends StatelessWidget {
  const _DotMatrixDecoration();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: List.generate(5, (_) {
              return Container(
                margin: const EdgeInsets.only(right: 7),
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// CustomPainter rendering the storefront, flanking trees,
/// floating location pin, and layered faded yellow-orange waves.
class _ShopiQStoreIllustrationPainter extends CustomPainter {
  final double pinOffsetY;

  _ShopiQStoreIllustrationPainter({required this.pinOffsetY});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Anchor the storefront around 54% of screen height
    final shopCenterY = h * 0.54;
    final shopCenterX = w * 0.49;

    // ── 1. Soft Background Town Silhouettes ───────────────────────────
    final bgBuildingPaint = Paint()
      ..color = AppTheme.softPeach.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Left building with gabled roof
    final leftHousePath = Path()
      ..moveTo(w * 0.22, shopCenterY)
      ..lineTo(w * 0.22, shopCenterY - 60)
      ..lineTo(w * 0.28, shopCenterY - 80)
      ..lineTo(w * 0.34, shopCenterY - 60)
      ..lineTo(w * 0.34, shopCenterY)
      ..close();
    canvas.drawPath(leftHousePath, bgBuildingPaint);

    // Right building with flat parapet
    final rightHousePath = Path()
      ..moveTo(w * 0.65, shopCenterY)
      ..lineTo(w * 0.65, shopCenterY - 65)
      ..lineTo(w * 0.77, shopCenterY - 65)
      ..lineTo(w * 0.77, shopCenterY)
      ..close();
    canvas.drawPath(rightHousePath, bgBuildingPaint);

    // ── 2. Flanking Trees ────────────────────────────────────────────
    final trunkPaint = Paint()
      ..color = const Color(0xFF8C6549)
      ..style = PaintingStyle.fill;

    final treeFoliagePaint = Paint()
      ..color = const Color(0xFFF2C07D).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Left tree
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.19, shopCenterY - 35, 6, 35),
        const Radius.circular(3),
      ),
      trunkPaint,
    );
    canvas.drawCircle(Offset(w * 0.17, shopCenterY - 45), 20, treeFoliagePaint);
    canvas.drawCircle(Offset(w * 0.22, shopCenterY - 48), 18, treeFoliagePaint);
    canvas.drawCircle(Offset(w * 0.19, shopCenterY - 62), 16, treeFoliagePaint);

    // Right tree
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.78, shopCenterY - 35, 6, 35),
        const Radius.circular(3),
      ),
      trunkPaint,
    );
    canvas.drawCircle(Offset(w * 0.76, shopCenterY - 45), 18, treeFoliagePaint);
    canvas.drawCircle(Offset(w * 0.81, shopCenterY - 45), 20, treeFoliagePaint);
    canvas.drawCircle(Offset(w * 0.78, shopCenterY - 60), 16, treeFoliagePaint);

    // ── 3. Storefront Main Body ──────────────────────────────────────
    const shopW = 142.0;
    const shopH = 78.0;
    final shopLeft = shopCenterX - (shopW / 2);
    final shopTop = shopCenterY - shopH;

    // Base store wall
    final wallPaint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;

    final wallShadowPaint = Paint()
      ..color = const Color(0xFFFFE8B0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final wallRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(shopLeft, shopTop, shopW, shopH),
      const Radius.circular(8),
    );
    canvas.drawRRect(wallRect, wallPaint);
    canvas.drawRRect(wallRect, wallShadowPaint);

    // Store Door
    final doorRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(shopLeft + 16, shopTop + 24, 38, shopH - 24),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    final doorPaint = Paint()
      ..color = const Color(0xFFF0B369)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(doorRect, doorPaint);

    // Door knob
    canvas.drawCircle(
      Offset(shopLeft + 46, shopTop + 48),
      2.5,
      Paint()..color = const Color(0xFF8C5020),
    );

    // Store Display Window
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(shopLeft + 64, shopTop + 24, 62, 42),
      const Radius.circular(6),
    );
    final windowPaint = Paint()
      ..color = const Color(0xFFFFD88C)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(windowRect, windowPaint);

    // Window Glass Reflection Slash
    final glassReflection = Path()
      ..moveTo(shopLeft + 80, shopTop + 26)
      ..lineTo(shopLeft + 90, shopTop + 26)
      ..lineTo(shopLeft + 74, shopTop + 62)
      ..lineTo(shopLeft + 68, shopTop + 62)
      ..close();
    canvas.drawPath(
      glassReflection,
      Paint()..color = const Color(0xFFFFFBF4).withValues(alpha: 0.65),
    );

    // Window sill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shopLeft + 62, shopTop + 66, 66, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE0922F),
    );

    // ── 4. Striped Store Awning ──────────────────────────────────────
    const awningW = 160.0;
    const awningH = 34.0;
    final awningLeft = shopCenterX - (awningW / 2);
    final awningTop = shopTop - 14;

    // Awning drop shadow on the wall
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shopLeft + 4, shopTop, shopW - 8, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0x205C3A21),
    );

    // 6 Scalloped Stripes (Alternating Faded Yellow-Orange and Cream)
    const stripeCount = 6;
    final stripeW = awningW / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final isAccent = i % 2 == 0;
      final x1 = awningLeft + (i * stripeW);
      final x2 = x1 + stripeW;
      final stripeColor = isAccent ? const Color(0xFFE0922F) : const Color(0xFFFFFDF8);

      final stripePath = Path()
        ..moveTo(x1 + 3, awningTop)
        ..lineTo(x2 - 3, awningTop)
        ..lineTo(x2, awningTop + awningH)
        ..arcToPoint(
          Offset(x1, awningTop + awningH),
          radius: Radius.circular(stripeW / 2),
          clockwise: false,
        )
        ..close();

      canvas.drawPath(
        stripePath,
        Paint()..color = stripeColor,
      );
    }

    // ── 5. Floating Location Pin & Dotted Trail ──────────────────────
    final pinCenterX = shopCenterX + 70;
    final pinCenterY = shopTop - 36 + pinOffsetY;

    // Subtle curved dotted trajectory behind the pin
    final dotTrailPaint = Paint()
      ..color = const Color(0xFFE0A352).withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    final trailPoints = [
      Offset(pinCenterX + 44, pinCenterY - 26),
      Offset(pinCenterX + 32, pinCenterY - 18),
      Offset(pinCenterX + 20, pinCenterY - 11),
      Offset(pinCenterX + 9, pinCenterY - 5),
    ];
    for (final pt in trailPoints) {
      canvas.drawCircle(pt, 2.2, dotTrailPaint);
    }

    // Pin shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pinCenterX, shopCenterY - 2),
        width: 14,
        height: 6,
      ),
      Paint()..color = const Color(0x242A1708),
    );

    // Pin shape
    const pinRadius = 16.0;
    final pinPath = Path()
      ..moveTo(pinCenterX, pinCenterY + pinRadius + 8) // Tip pointing down
      ..quadraticBezierTo(
        pinCenterX - pinRadius,
        pinCenterY + 4,
        pinCenterX - pinRadius,
        pinCenterY,
      )
      ..arcToPoint(
        Offset(pinCenterX + pinRadius, pinCenterY),
        radius: const Radius.circular(pinRadius),
        clockwise: true,
      )
      ..quadraticBezierTo(
        pinCenterX + pinRadius,
        pinCenterY + 4,
        pinCenterX,
        pinCenterY + pinRadius + 8,
      )
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = AppTheme.primary // Warm Tangerine
        ..style = PaintingStyle.fill,
    );

    // Inner white circle of location pin
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      6.5,
      Paint()..color = Colors.white,
    );

    // ── 6. Secondary Soft Wave Layer ─────────────────────────────────
    final secondaryWavePath = Path()
      ..moveTo(0, h * 0.53)
      ..cubicTo(w * 0.28, h * 0.50, w * 0.45, h * 0.58, w * 0.72, h * 0.53)
      ..cubicTo(w * 0.86, h * 0.50, w * 0.94, h * 0.54, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      secondaryWavePath,
      Paint()..color = AppTheme.softPeach.withValues(alpha: 0.55),
    );

    // ── 7. Primary Bottom Warm Tangerine Wave ────────────────────────
    final wavePath = Path()
      ..moveTo(0, shopCenterY + 8)
      ..cubicTo(
        w * 0.22,
        shopCenterY + 20,
        w * 0.42,
        h * 0.64,
        w * 0.70,
        h * 0.68,
      )
      ..cubicTo(
        w * 0.85,
        h * 0.70,
        w * 0.93,
        h * 0.65,
        w,
        h * 0.62,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final waveShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primary,     // Warm Tangerine
        AppTheme.primaryDark, // Primary pressed/dark
        Color(0xFFB8560F),    // Rich deep amber
      ],
    ).createShader(Rect.fromLTWH(0, shopCenterY, w, h - shopCenterY));

    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = waveShader
        ..style = PaintingStyle.fill,
    );

    // ── 8. Soft Floating Glowing Bubbles on Wave ─────────────────────
    final bubblePaint = Paint()
      ..color = AppTheme.softPeach.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.08, h * 0.78), 24, bubblePaint);
    canvas.drawCircle(Offset(w * 0.90, h * 0.74), 18, bubblePaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.83), 11, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant _ShopiQStoreIllustrationPainter oldDelegate) {
    return oldDelegate.pinOffsetY != pinOffsetY;
  }
}
