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
import 'saved_addresses_page.dart';
import 'package:provider/provider.dart';
import '../models/profile_provider.dart';
import '../models/favorites_api_provider.dart';
import '../core/auth/auth_provider.dart';
import '../models/language_provider.dart';
import 'support_faq_page.dart';
import 'terms_of_service_page.dart';

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
      if (userId != null && !profileProvider.hasFetched) {
        profileProvider.fetchProfile(userId).then((_) {
          // Auto-create profile if it doesn't exist yet
          if (profileProvider.profile == null && profileProvider.error == null) {
            final displayName = authProvider.email?.split('@').first ?? 'User';
            profileProvider.createProfile(userId, displayName);
          }
        });
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
      await context.read<ProfileProvider>().fetchProfile(userId, force: true);
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
                _buildSectionLabel(context, 'ACCOUNT'),
                const SizedBox(height: AppTheme.sm),
                _buildAccountSection(context),
                const SizedBox(height: AppTheme.xxl),
                _buildSectionLabel(context, 'GENERAL'),
                const SizedBox(height: AppTheme.sm),
                _buildGeneralSection(context),
                const SizedBox(height: AppTheme.xxl),
                _buildSectionLabel(context, 'PREFERENCES'),
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
              _buildStat(context, '12', 'Orders', LucideIcons.shoppingBag),
              _buildStatDivider(),
              _buildStat(context, '5', 'Reviews', LucideIcons.star),
              _buildStatDivider(),
              _buildStat(context, '8', 'Favorites', LucideIcons.heart),
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
    IconData icon,
  ) {
    return Expanded(
      child: Column(
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
      ),
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
              title: 'My Orders',
              subtitle: 'Track & reorder',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.mapPin,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: 'Saved Addresses',
              subtitle: 'Home, Office, Parents',
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
              title: 'Notifications',
              subtitle: 'Deals, order updates',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.heart,
              iconBg: AppTheme.lightBlue,
              iconColor: AppTheme.primaryBlue,
              title: 'Favorites',
              subtitle: 'Liked stores & items',
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
              title: 'Support & FAQ',
              subtitle: 'Help center, chat',
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
              title: 'Terms of Service',
              subtitle: 'Shopper terms & privacy policy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              ),
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
                  title: 'Language',
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

  void _showLanguageSelector(BuildContext context, LanguageProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                const Divider(color: AppTheme.veryLightGray),
                ...LanguageProvider.supportedLanguages.map((lang) {
                  final isSelected = provider.currentLocale.languageCode == lang['code'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(LucideIcons.check, color: AppTheme.primaryBlue)
                        : null,
                    onTap: () {
                      provider.setLanguage(lang['code']!);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: GestureDetector(
        onTap: () async {
          // Reset user-specific providers before logging out
          context.read<ProfileProvider>().reset();
          context.read<FavoritesApiProvider>().reset();
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
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
                'Log Out',
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
