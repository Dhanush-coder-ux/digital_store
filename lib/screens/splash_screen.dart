import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/auth/auth_provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late Timer _statementTimer;
  int _currentStatementIndex = 0;
  bool _isLoading = false;

  final List<String> _statements = [
    'Your neighbourhood\'s trusted stores, in one place.',
    'Regional specialities, delivered across India.',
    'Local shops you\'ll love—discover and follow.',
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
      duration: const Duration(milliseconds: 1500),
    );

    _haloScale = Tween<double>(begin: 1.0, end: 1.85).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );
    _haloOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _haloController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _haloController.forward();
    });
    
    // We check session in background after first frame but don't auto-navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkSessionInBackground();
    });
  }

  Future<void> _checkSessionInBackground() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkSession();
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
    _haloController.dispose();
    super.dispose();
  }

  void _enterApp(bool toLogin) async {
    setState(() => _isLoading = true);
    
    // Add a slight delay for a smooth transition out effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => toLogin ? const LoginScreen() : const MainScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _isLoading ? 0.0 : 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.52, 1.0],
              colors: [
                Color(0xFFE0922F),
                Color(0xFFD4842B),
                Color(0xFFC27726),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow Effect
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
                child: FadeIn(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 1600),
                  child: Container(
                    width: 520,
                    height: 520,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFE8B0).withOpacity(0.42),
                          const Color(0xFFFFD88C).withOpacity(0.14),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.66],
                      ),
                    ),
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    
                    // Logo Section
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo
                          AnimatedBuilder(
                            animation: _haloController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _haloScale.value,
                                child: Opacity(
                                  opacity: _haloOpacity.value,
                                  child: Container(
                                    width: 94,
                                    height: 94,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFFFFFBF4).withOpacity(0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Logo Mark
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            duration: const Duration(milliseconds: 900),
                            from: 20,
                            child: Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF3D2310), Color(0xFF2A1708)],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x733C1E08),
                                    blurRadius: 44,
                                    offset: Offset(0, 18),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFFFDCA0).withOpacity(0.22),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(LucideIcons.shoppingBag, color: Color(0xFFE0A33E), size: 42),
                                  FadeIn(
                                    delay: const Duration(milliseconds: 750),
                                    duration: const Duration(milliseconds: 500),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFE6B0),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Name
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 700),
                      from: 20,
                      child: Text(
                        'Digital Store',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 58,
                          color: const Color(0xFFFFFBF4),
                          fontWeight: FontWeight.w400,
                          shadows: const [
                            Shadow(
                              color: Color(0x403C1E08),
                              blurRadius: 16,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Underline
                    FadeIn(
                      delay: const Duration(milliseconds: 1100),
                      duration: const Duration(milliseconds: 900),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 30, top: 4),
                        height: 2,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFFBF4).withOpacity(0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rotating Statements
                    SizedBox(
                      height: 60,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.5),
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
                          style: GoogleFonts.geist(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFFFBF4).withOpacity(0.82),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),

                    // Progress Dots
                    FadeIn(
                      delay: const Duration(milliseconds: 1900),
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_statements.length, (index) {
                          bool isActive = index == _currentStatementIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 7,
                            width: isActive ? 22 : 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFFFBF4)
                                  : const Color(0xFFFFFBF4).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),

                    const Spacer(flex: 4),
                    
                    // Bottom CTA
                    FadeInUp(
                      delay: const Duration(milliseconds: 2500),
                      duration: const Duration(milliseconds: 700),
                      from: 20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ElevatedButton(
                          onPressed: () => _enterApp(false),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF3D2310), // espresso-2 roughly
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 10,
                            shadowColor: const Color(0x663C1E08),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Explore stores near you',
                                style: GoogleFonts.geist(
                                  color: const Color(0xFFFFFBF4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 18, color: Color(0xFFFFFBF4)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trust text
                    FadeIn(
                      delay: const Duration(milliseconds: 2900),
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, size: 14, color: Color(0xFFFFFBF4)),
                          const SizedBox(width: 6),
                          Text(
                            'Supporting local businesses near you',
                            style: GoogleFonts.geist(
                              fontSize: 12,
                              color: const Color(0xFFFFFBF4).withOpacity(0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Signin Line
                    FadeIn(
                      delay: const Duration(milliseconds: 2700),
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.geist(
                              fontSize: 13.5,
                              color: const Color(0xFFFFFBF4).withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _enterApp(true),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.geist(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFFFBF4),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
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
