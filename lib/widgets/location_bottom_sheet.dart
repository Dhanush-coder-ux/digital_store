import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/providers.dart';
import '../models/profile_provider.dart';
import '../models/shop_provider.dart';
import '../core/auth/auth_provider.dart';
import '../core/models/address_model.dart';

/// Shared location-selection bottom sheet.
/// Opens when the user taps the delivery location on Home or any other
/// location-aware surface. Uses existing providers and Nominatim geocoding.
class LocationBottomSheet extends StatefulWidget {
  const LocationBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationBottomSheet(),
    );
  }

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Search via Nominatim
  // ─────────────────────────────────────────────────────────────────
  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() { _isSearching = true; _suggestions = []; });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'digital_app'});
      if (resp.statusCode == 200 && mounted) {
        setState(() => _suggestions = json.decode(resp.body));
      }
    } catch (_) {
      // Silently ignore network errors; show no suggestions
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Use current location
  // ─────────────────────────────────────────────────────────────────
  Future<void> _useCurrentLocation() async {
    setState(() { _isLocating = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Location services are disabled. Please enable GPS.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() => _locationError = 'Location permission denied. You can search for your address below.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Location permission permanently denied. Please enable it in app settings, or search your address below.');
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() => _locationError = 'Could not determine location. Please search manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'digital_app'});
      if (resp.statusCode == 200 && mounted) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        _confirmFromNominatim(data, lat: lat, lon: lon);
      }
    } catch (_) {
      // Show fallback with coordinates
      if (mounted) {
        setState(() => _locationError = 'Reverse geocoding failed. Location captured at $lat, $lon. Please verify.');
        _confirmLocation(
          fullAddress: 'Current Location ($lat, $lon)',
          city: '',
          state: '',
          pincode: '',
          lat: lat,
          lon: lon,
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build address from Nominatim result
  // ─────────────────────────────────────────────────────────────────
  void _confirmFromNominatim(Map<String, dynamic> item, {double? lat, double? lon}) {
    final latVal = lat ?? double.tryParse(item['lat']?.toString() ?? '') ?? 0;
    final lonVal = lon ?? double.tryParse(item['lon']?.toString() ?? '') ?? 0;

    final addr = item['address'] as Map<String, dynamic>? ?? {};
    final road    = (addr['road'] ?? '').toString().trim();
    final suburb  = (addr['suburb'] ?? addr['neighbourhood'] ?? '').toString().trim();
    final city    = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '').toString().trim();
    final state   = (addr['state'] ?? '').toString().trim();
    final pincode = (addr['postcode'] ?? '').toString().trim();

    final lineParts = [road, suburb].where((p) => p.isNotEmpty).toList();
    final fullAddress = lineParts.isNotEmpty ? lineParts.join(', ') : (item['display_name'] ?? '').toString().split(',').first;

    _confirmLocation(
      fullAddress: _cleanAddress(fullAddress),
      city: city,
      state: state,
      pincode: pincode,
      lat: latVal,
      lon: lonVal,
    );
  }

  void _confirmLocation({
    required String fullAddress,
    required String city,
    required String state,
    required String pincode,
    required double lat,
    required double lon,
  }) {
    final address = AddressModel(
      fullAddress: fullAddress,
      city: city,
      state: state,
      pincode: pincode,
      phone: '',
      latitude: lat,
      longitude: lon,
    );

    final locProvider = context.read<LocationProvider>();
    locProvider.selectAddressModel(address);

    // Refresh shops with new location
    context.read<ShopProvider>().fetchAllShops(
      force: true,
      lat: lat,
      lng: lon,
    );

    if (mounted) Navigator.pop(context, address);
  }

  void _selectSavedAddress(AddressModel address) {
    final locProvider = context.read<LocationProvider>();
    locProvider.selectAddressModel(address);
    context.read<ShopProvider>().fetchAllShops(
      force: true,
      lat: address.latitude ?? locProvider.latitude,
      lng: address.longitude ?? locProvider.longitude,
    );
    Navigator.pop(context, address);
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────
  String _cleanAddress(String raw) {
    // Remove empty comma-separated segments like ", , "
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  String _formatAddressLine1(AddressModel a) {
    return _cleanAddress(a.fullAddress);
  }

  String _formatAddressLine2(AddressModel a) {
    final parts = [a.city, a.state, a.pincode].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final savedAddresses = auth.isAuthenticated ? profileProvider.addresses : <AddressModel>[];
    final currentAddr = context.watch<LocationProvider>().fullAddressName;

    return Container(
      margin: EdgeInsets.only(top: mq.size.height * 0.12),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppTheme.xl,
                right: AppTheme.xl,
                top: AppTheme.lg,
                bottom: mq.viewInsets.bottom + AppTheme.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text('Where should we deliver?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Choose a location to see nearby stores',
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.xl),

                  // Use current location button
                  _buildCurrentLocationButton(),

                  if (_locationError != null) ...[
                    const SizedBox(height: AppTheme.sm),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.md),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(children: [
                        const Icon(LucideIcons.alertCircle, color: AppTheme.errorRed, size: 16),
                        const SizedBox(width: AppTheme.sm),
                        Expanded(child: Text(_locationError!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: AppTheme.lg),

                  // Or divider
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
                      child: Text('or search', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: AppTheme.lg),

                  // Search field
                  _buildSearchField(),
                  if (_isSearching) ...[
                    const SizedBox(height: AppTheme.sm),
                    const LinearProgressIndicator(color: AppTheme.primaryBlue, backgroundColor: AppTheme.bgSecondary),
                  ],

                  // Search suggestions
                  if (_suggestions.isNotEmpty)
                    _buildSuggestions(),

                  // Saved addresses section
                  if (savedAddresses.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saved Addresses',
                          style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: AppTheme.md),
                    ...savedAddresses.map((a) => _buildSavedAddressRow(a, currentAddr)),
                  ],

                  if (savedAddresses.isEmpty && auth.isAuthenticated) ...[
                    const SizedBox(height: AppTheme.xl),
                    _buildEmptySavedAddresses(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: _isLocating ? null : _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.lg),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: _isLocating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.navigation, color: AppTheme.white, size: 20),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isLocating ? 'Detecting location...' : 'Use current location',
                    style: const TextStyle(
                      fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    )),
                  const SizedBox(height: 2),
                  Text('GPS-detected delivery address',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppTheme.primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final isFocused = _searchFocusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 50,
      decoration: BoxDecoration(
        color: isFocused ? AppTheme.white : AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? Colors.transparent : AppTheme.border.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isFocused
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : AppTheme.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                LucideIcons.search,
                size: 17,
                color: isFocused ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              autofocus: false,
              cursorColor: AppTheme.primary,
              cursorWidth: 2.0,
              cursorRadius: const Radius.circular(2),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search area, street, postal code...',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppTheme.textTertiary.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {});
                _searchAddress(val);
              },
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _suggestions = []);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isFocused ? AppTheme.bgSecondary : AppTheme.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.x, size: 14, color: AppTheme.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.sm),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.4)),
          itemBuilder: (_, i) {
            final item = _suggestions[i];
            final parts = item['display_name'].toString().split(', ');
            return InkWell(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _suggestions = []);
                _confirmFromNominatim(item);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.mapPin, color: AppTheme.primary, size: 15),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parts.first,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      if (parts.length > 1)
                        Text(parts.sublist(1).join(', '),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  )),
                  const Icon(LucideIcons.arrowUpRight, size: 15, color: AppTheme.textTertiary),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavedAddressRow(AddressModel address, String currentFullAddr) {
    final isSelected = address.fullAddress.isNotEmpty &&
        currentFullAddr.contains(address.fullAddress.substring(0, address.fullAddress.length.clamp(0, 30)));
    final label = address.isDefault ? 'Default' : 'Saved';

    return GestureDetector(
      onTap: () => _selectSavedAddress(address),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sm),
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.4) : AppTheme.veryLightGray,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.15) : AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              address.isDefault ? LucideIcons.home : LucideIcons.mapPin,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary, size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(label,
                  style: TextStyle(
                    fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                  )),
                if (address.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('DEFAULT',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.successGreen, letterSpacing: 0.5)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(_formatAddressLine1(address),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppTheme.textSecondary)),
              if (_formatAddressLine2(address).isNotEmpty)
                Text(_formatAddressLine2(address),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppTheme.textTertiary)),
            ],
          )),
          if (isSelected)
            const Icon(LucideIcons.checkCircle2, color: AppTheme.primaryBlue, size: 18),
        ]),
      ),
    );
  }

  Widget _buildEmptySavedAddresses() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.xl),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(children: [
        const Icon(LucideIcons.mapPin, color: AppTheme.textTertiary, size: 32),
        const SizedBox(height: AppTheme.sm),
        Text('No saved addresses', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('Add addresses from your profile for quick access.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
