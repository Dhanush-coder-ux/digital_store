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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
    );
  }

  SliverAppBar _buildSliverHeader(BuildContext context) {
    final profileImage = _profileImageProvider();

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.settings,
                              color: AppTheme.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.xl),
                      FadeInLeft(
                        duration: AppDurations.normal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickProfileImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.white.withOpacity(0.5),
                                        width: 3,
                                      ),
                                      boxShadow: AppTheme.shadowLarge,
                                      image: DecorationImage(
                                        image: profileImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (_isPickingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.28),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppTheme.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.mutedCyan,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        LucideIcons.pencil,
                                        color: AppTheme.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deepak Roshan',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '+91 88380 7xxxx',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: AppTheme.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.sm,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          LucideIcons.diamond,
                                          color: AppTheme.paleCyan,
                                          size: 11,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Gold Member',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            color: AppTheme.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              iconBg: AppTheme.infoBlue.withOpacity(0.1),
              iconColor: AppTheme.infoBlue,
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
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9333EA),
              title: 'Saved Addresses',
              subtitle: 'Home, Office, Parents',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
              ),
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.creditCard,
              iconBg: AppTheme.successGreen.withOpacity(0.1),
              iconColor: AppTheme.successGreen,
              title: 'Payment Methods',
              subtitle: 'Visa â€¢â€¢4242',
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
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFF97316),
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
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFE11D48),
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
              iconBg: AppTheme.mutedCyan.withOpacity(0.1),
              iconColor: AppTheme.mutedCyan,
              title: 'Support & FAQ',
              subtitle: 'Help center, chat',
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
        child: Column(
          children: [
            _buildListTile(
              context,
              icon: LucideIcons.globe,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
              title: 'Language',
              subtitle: 'English (US)',
            ),
            _buildDivider(),
            _buildListTile(
              context,
              icon: LucideIcons.shield,
              iconBg: AppTheme.primaryBlue.withOpacity(0.08),
              iconColor: AppTheme.primaryBlue,
              title: 'Privacy & Security',
              subtitle: 'Password, permissions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl),
      child: GestureDetector(
        onTap: () {},
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
