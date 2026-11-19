import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import 'favorites_page.dart';
import 'my_orders_page.dart';
import 'my_return_requests_page.dart';
import 'saved_addresses_page.dart';
import 'package:provider/provider.dart';
import '../models/profile_provider.dart';
import '../models/favorites_api_provider.dart';
import '../models/providers.dart';
import '../core/auth/auth_provider.dart';
import '../l10n/app_translations.dart';
import '../models/language_provider.dart';
import 'support_faq_page.dart';
import 'terms_of_service_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_config.dart';
import '../models/user_order_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/review_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _defaultAvatarUrl =
      'https://img.freepik.com/free-vector/businessman-character-avatar-isolated_24877-60111.jpg';

  final ImagePicker _imagePicker = ImagePicker();
  String? _profileImagePath;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    // Ensure profile is fetched when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();
      final userId = authProvider.userId;
      if (userId != null) {
        if (!profileProvider.hasFetched) {
          profileProvider.fetchProfile(userId).then((_) {
            // Auto-create profile if it doesn't exist yet
            if (profileProvider.profile == null && profileProvider.error == null) {
              final displayName = authProvider.email?.split('@').first ?? 'User';
              profileProvider.createProfile(userId, displayName);
            }
          });
        }
        final orderProvider = context.read<UserOrderProvider>();
        if (!orderProvider.hasFetched) {
          orderProvider.fetchUserOrders(userId);
        }
        final favProvider = context.read<FavoritesApiProvider>();
        if (!favProvider.hasFetched) {
          favProvider.fetchFavorites(userId);
        }
        final reviewProvider = context.read<ReviewProvider>();
        reviewProvider.fetchUserReviews(userId);
      }
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImagePathKey);

    if (savedPath == null || savedPath.isEmpty) return;

    final imageFile = File(savedPath);
    if (!imageFile.existsSync()) {
      await prefs.remove(_profileImagePathKey);
      return;
    }

    if (!mounted) return;
    setState(() {
      _profileImagePath = savedPath;
    });
  }

  Future<void> _pickProfileImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, pickedFile.path);

      if (!mounted) return;
      setState(() {
        _profileImagePath = pickedFile.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick image right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  ImageProvider _profileImageProvider() {
    if (_profileImagePath != null) {
      final imageFile = File(_profileImagePath!);
      if (imageFile.existsSync()) {
        return FileImage(imageFile);
      }
    }

    return const NetworkImage(_defaultAvatarUrl);
  }

  Future<void> _onRefresh() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId != null) {
      await Future.wait([
        context.read<ProfileProvider>().fetchProfile(userId, force: true),
        context.read<UserOrderProvider>().fetchUserOrders(userId, force: true),
        context.read<FavoritesApiProvider>().fetchFavorites(userId, force: true),
        context.read<ReviewProvider>().fetchUserReviews(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverHeader(context),
            SliverToBoxAdapter(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.xl),
                _buildStatsRow(context),
                const SizedBox(height: AppTheme.xxl),
                _buildSectionLabel(context, context.tr('account')),
                const SizedBox(height: AppTheme.sm),
                _buildAccountSection(context),
                const SizedBox(height: AppTheme.xxl),
                _buildSectionLabel(context, context.tr('general')),
                const SizedBox(height: AppTheme.sm),
                _buildGeneralSection(context),
                const SizedBox(height: AppTheme.xxl),
                _buildSectionLabel(context, context.tr('preferences')),
                const SizedBox(height: AppTheme.sm),
                _buildPreferencesSection(context),
                const SizedBox(height: AppTheme.xxl),
                _buildLogoutButton(context),
                const SizedBox(height: AppTheme.xxxl),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    final profileImage = _profileImageProvider();

    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.white,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.veryLightGray, width: 2),
                          image: DecorationImage(image: profileImage, fit: BoxFit.cover),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                      ),
                      if (_isPickingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black26),
                            child: const Center(child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))),
                          ),
                        ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue, shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.white, width: 1.5),
                          ),
                          child: const Icon(LucideIcons.pencil, color: AppTheme.white, size: 10),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: AppTheme.md),
                  // Name + email
                  Expanded(
                    child: Consumer<ProfileProvider>(
                      builder: (context, profile, _) {
                        final auth = context.watch<AuthProvider>();
                        final name = profile.userName.isNotEmpty
                            ? profile.userName
                            : (auth.email?.split('@').first ?? 'Guest');
                        final contact = auth.email ?? auth.mobile ?? '';
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (contact.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(contact,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                            ),
                            child: const Text('Member',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
                                fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                          ),
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.veryLightGray),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final orderProvider = context.watch<UserOrderProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final favoritesProvider = context.watch<FavoritesApiProvider>();

    final ordersCount = orderProvider.orders.length.toString();
    final reviewsCount = reviewProvider.userReviews.length.toString();
    final favoritesCount = (favoritesProvider.favoriteProductIds.length +
            favoritesProvider.favoriteShopIds.length)
        .toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: FadeInUp(
        duration: AppDurations.normal,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            children: [
              _buildStat(
                context,
                ordersCount,
                context.tr('orders_stat'),
                LucideIcons.shoppingBag,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                  );
                },
              ),
              _buildStatDivider(),
              _buildStat(
                context,
                reviewsCount,
                context.tr('reviews_stat'),
                LucideIcons.star,
              ),
              _buildStatDivider(),
              _buildStat(
                context,
                favoritesCount,
                context.tr('favorites_stat'),
                LucideIcons.heart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 50, width: 1, color: AppTheme.veryLightGray);
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textTertiary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowSmall,
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: Column(
          children: [
            _buildListTile(
              context,
              icon: LucideIcons.receipt,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: context.tr('my_orders'),
              subtitle: context.tr('my_orders_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.rotateCcw,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: context.tr('return_requests'),
              subtitle: context.tr('return_requests_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReturnRequestsPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.mapPin,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: context.tr('saved_addresses'),
              subtitle: context.tr('saved_addresses_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowSmall,
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: Column(
          children: [
            _buildListTile(
              context,
              icon: LucideIcons.bell,
              iconBg: AppTheme.bgSecondary,
              iconColor: AppTheme.textPrimary,
              title: context.tr('notifications'),
              subtitle: context.tr('notifications_sub'),
              trailing: Consumer<NotificationsProvider>(
                builder: (context, notifProvider, _) => Switch(
                  value: notifProvider.notificationsEnabled,
                  onChanged: (val) => notifProvider.setNotificationsEnabled(val),
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.heart,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: context.tr('favorites'),
              subtitle: context.tr('favorites_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.headphones,
              iconBg: AppTheme.bgSecondary,
              iconColor: AppTheme.textPrimary,
              title: context.tr('support_faq'),
              subtitle: context.tr('support_faq_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportFaqPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.fileText,
              iconBg: AppTheme.bgSecondary,
              iconColor: AppTheme.textPrimary,
              title: context.tr('terms_of_service'),
              subtitle: context.tr('terms_of_service_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage(initialIndex: 0)),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.shieldCheck,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: context.tr('privacy_policy'),
              subtitle: context.tr('privacy_policy_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage(initialIndex: 1)),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.trash2,
              iconBg: AppTheme.errorRed.withOpacity(0.08),
              iconColor: AppTheme.errorRed,
              title: context.tr('delete_account'),
              subtitle: context.tr('delete_account_sub'),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowSmall,
          border: Border.all(color: AppTheme.veryLightGray),
        ),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            return Column(
              children: [
                _buildListTile(
                  context,
                  icon: LucideIcons.globe,
                  iconBg: AppTheme.bgSecondary,
                  iconColor: AppTheme.textPrimary,
                  title: context.tr('language'),
                  subtitle: languageProvider.currentLanguageName,
                  onTap: () => _showLanguageSelector(context, languageProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showLanguageSelector(BuildContext context, LanguageProvider provider) async {
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _LanguageSelectionSheet(provider: provider);
      },
    );

    if (selectedCode != null && selectedCode != provider.currentLocale.languageCode) {
      // Ensure the bottom sheet pop animation finishes and unmounts before rebuilding MaterialApp
      await Future.delayed(const Duration(milliseconds: 320));
      if (mounted) {
        await provider.setLanguage(selectedCode);
      }
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: GestureDetector(
        onTap: () async {
          // Reset user-specific providers before logging out
          context.read<ProfileProvider>().reset();
          context.read<FavoritesApiProvider>().reset();
          context.read<NotificationsProvider>().reset();
          context.read<UserOrderProvider>().reset();
          context.read<ApiCartProvider>().clearCart();
          context.read<ReviewProvider>().reset();
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.logOut,
                color: AppTheme.errorRed,
                size: 18,
              ),
              const SizedBox(width: AppTheme.sm),
              Text(
                context.tr('log_out'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: AppTheme.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Text(
                context.tr('delete_account_confirm_title'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('delete_account_confirm_msg'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.md),
              Container(
                padding: const EdgeInsets.all(AppTheme.md),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.veryLightGray),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Data to be deleted immediately:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '  Profile data, saved delivery addresses, search history, favorites & active session tokens.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Data retained for statutory compliance:',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '  Order transaction records and invoices retained as mandated by tax and commercial regulations.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.md),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(ApiConfig.accountDeletionUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                child: const Text(
                  'Web deletion portal: https://shopiq.inventq.in/account-deletion',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              context.tr('delete_account_cancel_btn'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _initiateAccountDeletionFlow();
            },
            child: Text(
              context.tr('delete_account_confirm_btn'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateAccountDeletionFlow() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again to delete your account.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Show loading progress overlay while generating & sending OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.errorRed,
                ),
              ),
              SizedBox(width: AppTheme.md),
              Expanded(
                child: Text(
                  'Sending verification code to Gmail...',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final res = await authProvider.requestDeleteAccountOtp();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      final maskedEmail = (res['email'] as String?) ??
          (authProvider.email != null
              ? '${authProvider.email!.substring(0, 2)}***@${authProvider.email!.split("@").last}'
              : 'your registered Gmail');

      _showOtpVerificationModal(maskedEmail);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        final errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showOtpVerificationModal(String maskedEmail) {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _OtpVerificationSheet(
          maskedEmail: maskedEmail,
          onCancel: () => Navigator.pop(modalCtx),
          onResendOtp: () async {
            await authProvider.requestDeleteAccountOtp();
          },
          onVerifyOtp: (enteredOtp) async {
            final userId = authProvider.userId;
            if (userId != null) {
              try {
                await profileProvider.deleteProfile(userId);
              } catch (_) {}
            }

            await authProvider.verifyDeleteAccountOtp(enteredOtp);

            if (mounted) {
              context.read<FavoritesApiProvider>().reset();
              context.read<NotificationsProvider>().reset();
              context.read<UserOrderProvider>().reset();
              context.read<ApiCartProvider>().clearCart();
              context.read<ReviewProvider>().reset();
              profileProvider.reset();
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_profileImagePathKey);

            if (modalCtx.mounted) {
              Navigator.pop(modalCtx);
            }

            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('delete_account_success')),
                  backgroundColor: AppTheme.textPrimary,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg,
          vertical: AppTheme.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textTertiary,
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: AppTheme.lg),
      child: Divider(height: 1, color: AppTheme.veryLightGray),
    );
  }
}


// ── Standalone Stateful Sheet Widgets (Prevent Controller Disposal Collisions) ──

class _LanguageSelectionSheet extends StatefulWidget {
  final LanguageProvider provider;

  const _LanguageSelectionSheet({required this.provider});

  @override
  State<_LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<_LanguageSelectionSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLanguages = LanguageProvider.supportedLanguages.where((lang) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = (lang['name'] ?? '').toLowerCase();
      final english = (lang['englishName'] ?? '').toLowerCase();
      final code = (lang['code'] ?? '').toLowerCase();
      return name.contains(q) || english.contains(q) || code.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppTheme.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.veryLightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
              child: Text(
                widget.provider.tr('select_language'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: widget.provider.tr('search_languages'),
                  hintStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppTheme.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.md),
            const Divider(height: 1, color: AppTheme.veryLightGray),
            Expanded(
              child: filteredLanguages.isEmpty
                  ? Center(
                      child: Text(
                        widget.provider.tr('no_languages_found'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredLanguages.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: AppTheme.xl,
                        endIndent: AppTheme.xl,
                        color: AppTheme.veryLightGray,
                      ),
                      itemBuilder: (context, index) {
                        final lang = filteredLanguages[index];
                        final code = lang['code']!;
                        final nativeName = lang['name']!;
                        final englishName = lang['englishName'] ?? nativeName;
                        final isSelected =
                            widget.provider.currentLocale.languageCode == code;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.xl,
                            vertical: 2,
                          ),
                          title: Text(
                            nativeName,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: englishName != nativeName
                              ? Text(
                                  englishName,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  color: AppTheme.primaryBlue,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context, code);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpVerificationSheet extends StatefulWidget {
  final String maskedEmail;
  final VoidCallback onCancel;
  final Future<void> Function() onResendOtp;
  final Future<void> Function(String otp) onVerifyOtp;

  const _OtpVerificationSheet({
    required this.maskedEmail,
    required this.onCancel,
    required this.onResendOtp,
    required this.onVerifyOtp,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  late final TextEditingController _otpController;
  bool _isVerifying = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.shieldAlert,
                      color: AppTheme.errorRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Account Deletion',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Security verification required',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.veryLightGray),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.mail,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'A 6-digit confirmation code was sent to '),
                            TextSpan(
                              text: widget.maskedEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const TextSpan(text: '. Enter it below to complete deletion.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    letterSpacing: 12,
                    color: AppTheme.textSecondary.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgSecondary,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.veryLightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.veryLightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                  ),
                ),
                onChanged: (_) {
                  if (_localError != null) {
                    setState(() => _localError = null);
                  }
                },
              ),
              if (_localError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _localError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      LucideIcons.info,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Personal profile, saved addresses and favorites will be permanently removed. Order records remain archived for merchant bookkeeping and tax compliance.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the email?",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _isVerifying
                        ? null
                        : () async {
                            try {
                              await widget.onResendOtp();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('A fresh verification code was sent to your Gmail.'),
                                    backgroundColor: AppTheme.textPrimary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _localError = 'Failed to resend code: $e';
                                });
                              }
                            }
                          },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: AppTheme.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onPressed: _isVerifying
                    ? null
                    : () async {
                        final enteredOtp = _otpController.text.trim();
                        if (enteredOtp.length != 6) {
                          setState(() {
                            _localError = 'Please enter the complete 6-digit verification code.';
                          });
                          return;
                        }

                        setState(() {
                          _isVerifying = true;
                          _localError = null;
                        });

                        try {
                          await widget.onVerifyOtp(enteredOtp);
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isVerifying = false;
                              String raw = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '').trim();
                              if (raw.contains('description:')) {
                                final match = RegExp(r'description:\s*([^,}]+)').firstMatch(raw);
                                if (match != null && match.group(1) != null) {
                                  raw = match.group(1)!.trim();
                                }
                              } else if (raw.contains('detail:')) {
                                final match = RegExp(r'detail:\s*([^,}]+)').firstMatch(raw);
                                if (match != null && match.group(1) != null) {
                                  raw = match.group(1)!.trim();
                                }
                              }
                              _localError = raw;
                            });
                          }
                        }
                      },
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text(
                        'Verify & Permanently Delete',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isVerifying ? null : widget.onCancel,
                child: Text(
                  context.tr('delete_account_cancel_btn'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
