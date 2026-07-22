// lib/screens/login_screen.dart
//
// OAuth login screen with modern branding.
// Opens browser for Debugger Auth login, handles deep link callback.
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/auth/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
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
    try {
      context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.softRoyalBlue,
              AppTheme.deepBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome text
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 150),
                  child: const Text(
                    'Welcome to\nDigiStore',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Discover local shops, browse products,\nand order with ease.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      color: AppTheme.white.withOpacity(0.65),
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                // Sign In button
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 500),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final loading = _isLaunching || auth.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.white,
                            foregroundColor: AppTheme.primaryBlue,
                            disabledBackgroundColor: AppTheme.white.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primaryBlue,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.logIn, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                // Guest option
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 650),
                  child: TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.white.withOpacity(0.6),
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
