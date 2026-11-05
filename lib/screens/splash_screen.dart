import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late Timer _statementTimer;
  Timer? _autoNavTimer;
  int _currentStatementIndex = 0;
  bool _isLoading = false;

  final List<String> _statements = [
    'Your neighbourhood\'s trusted stores, in one place.',
    'Discover local shops, browse products, and order with ease.',
    'Regional specialities, delivered right to your door.',
  ];

  late AnimationController _haloController;
  late Animation<double> _haloScale;
  late Animation<double> _haloOpacity;

  @override
  void initState() {
    super.initState();
    _startStatementRotation();

    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _haloScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );
    _haloOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );

    // Check session in background after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkSessionInBackground();
    });
  }

  Future<void> _checkSessionInBackground() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkSession();

    if (!mounted) return;

    // Smooth auto-transition after 3.2 seconds
    _autoNavTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted && !_isLoading) {
        _enterApp(authProvider.isAuthenticated ? false : true);
      }
    });
  }

  void _startStatementRotation() {
    _statementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentStatementIndex = (_currentStatementIndex + 1) % _statements.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _statementTimer.cancel();
    _autoNavTimer?.cancel();
    _haloController.dispose();
    super.dispose();
  }

  void _enterApp(bool toLogin) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            toLogin ? const LoginScreen() : const MainScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: GestureDetector(
        onTap: () {
          final auth = context.read<AuthProvider>();
          _enterApp(auth.isAuthenticated ? false : true);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: _isLoading ? 0.0 : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Top-Left Ambient Warm Glow ────────────────────────────
              Positioned(
                top: -90,
                left: -90,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.lightBlue.withValues(alpha: 0.5),
                        AppTheme.bgPrimary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom-Right Ambient Warm Glow ───────────────────────
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.bgSecondary.withValues(alpha: 0.8),
                        AppTheme.bgPrimary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main Content Column ──────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ── App Logo with Pulsing Halo ─────────────────────
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gentle Halo Animation
                          AnimatedBuilder(
                            animation: _haloController,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: _haloScale.value,
                                child: Opacity(
                                  opacity: _haloOpacity.value,
                                  child: Container(
                                    width: 106,
                                    height: 106,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Hero App Logo Card
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            duration: const Duration(milliseconds: 700),
                            from: 20,
                            child: Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppTheme.veryLightGray, width: 1.2),
                                boxShadow: AppTheme.shadowLarge,
                              ),
                              child: Image.asset(
                                'assets/Vivid S-Cart Shopping Icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── App Name ───────────────────────────────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 600),
                      from: 16,
                      child: Text(
                        'ShopIQ',
                        style: GoogleFonts.outfit(
                          fontSize: 44,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),

                    // ── Amber Accent Pill ──────────────────────────────
                    FadeIn(
                      delay: const Duration(milliseconds: 550),
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24, top: 8),
                        height: 3,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),

                    // ── Rotating Statements ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: SizedBox(
                        height: 56,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _statements[_currentStatementIndex],
                            key: ValueKey<int>(_currentStatementIndex),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Progress Dots ──────────────────────────────────
                    FadeIn(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_statements.length, (index) {
                          bool isActive = index == _currentStatementIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 20 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primaryBlue
                                  : AppTheme.veryLightGray,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // ── Bottom Action Button ───────────────────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 600),
                      from: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              final auth = context.read<AuthProvider>();
                              _enterApp(auth.isAuthenticated ? false : false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: AppTheme.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Explore stores near you',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.arrowRight,
                                  size: 18,
                                  color: AppTheme.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Sign In Navigation Link ────────────────────────
                    FadeIn(
                      delay: const Duration(milliseconds: 1200),
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _enterApp(true),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
