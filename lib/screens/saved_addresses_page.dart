// lib/screens/saved_addresses_page.dart
//
// Saved Addresses page — backed by the DigitalStore User Profile API.
// Addresses are stored in the user profile document on the backend.
// Add / Delete / Set-Default all sync to the server via ProfileProvider.
//

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_provider.dart';
import '../core/auth/auth_provider.dart';
import '../core/models/address_model.dart';
import '../theme/app_theme.dart';
import '../models/providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  @override
  void initState() {
    super.initState();
    // Ensure profile (which contains addresses) is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();
      if (authProvider.userId != null && !profileProvider.hasFetched) {
        profileProvider.fetchProfile(authProvider.userId!);
      }
    });
  }

  Future<void> _onRefresh() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    if (authProvider.userId != null) {
      await profileProvider.fetchProfile(authProvider.userId!, force: true);
    }
  }

  void _showAddAddressModal(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAddressModal(userId: authProvider.userId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Saved Addresses",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.error != null) {
            return Center(
              child: Text(
                profileProvider.error!,
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            );
          }

          final addresses = profileProvider.addresses;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ALL ADDRESSES",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          "${addresses.length} Found",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (addresses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "No saved addresses yet.",
                              style: GoogleFonts.outfit(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add an address to get started",
                              style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(addresses.length, (index) {
                      return FadeInUp(
                        delay: Duration(milliseconds: 100 * (index + 1)),
                        child: _buildAddressCard(context, addresses[index], profileProvider),
                      );
                    }),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildAddNewAddressBtn(context),
                  ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address, ProfileProvider profileProvider) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId ?? '';
    final isDefault = address.isDefault;

    return GestureDetector(
      onTap: () {
        context.read<LocationProvider>().selectAddressModel(address);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.grey.shade200,
            width: isDefault ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        children: [
          // Header with default badge
          if (isDefault)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle2, size: 13, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    'Default Address',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.fullAddress,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${address.city}, ${address.state} — ${address.pincode}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(LucideIcons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            address.phone,
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (address.addressId != null) {
                          await profileProvider.setDefaultAddress(userId, address.addressId!);
                        }
                      },
                      icon: const Icon(LucideIcons.star, size: 14),
                      label: Text('Set Default', style: GoogleFonts.outfit(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (!isDefault) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Delete Address', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          content: Text('Remove this address?', style: GoogleFonts.outfit()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: GoogleFonts.outfit()),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && address.addressId != null) {
                        await profileProvider.removeAddress(userId, address.addressId!);
                      }
                    },
                    icon: const Icon(LucideIcons.trash2, size: 14),
                    label: Text('Delete', style: GoogleFonts.outfit(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildAddNewAddressBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddAddressModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plusCircle, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              "Add New Address",
              style: GoogleFonts.outfit(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressModal extends StatefulWidget {
  final String userId;
  const _AddAddressModal({required this.userId});

  @override
  State<_AddAddressModal> createState() => _AddAddressModalState();
}

class _AddAddressModalState extends State<_AddAddressModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _searchLocationCtrl = TextEditingController();
  final MapController _mapController = MapController();

  bool _isDefault = false;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _isGettingLocation = false;
  
  List<dynamic> _suggestions = [];
  String _displayAddress = '';

  double? _latitude;
  double? _longitude;

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');
      final response = await http.get(url, headers: {'User-Agent': 'digital_app'});
      if (response.statusCode == 200) {
        setState(() {
          _suggestions = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'digital_app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _handleSelection(data);
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  void _handleSelection(Map<String, dynamic> item) {
    final lat = double.parse(item['lat'].toString());
    final lon = double.parse(item['lon'].toString());
    
    final addr = item['address'] ?? {};
    final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '';
    final state = addr['state'] ?? '';
    final pincode = addr['postcode'] ?? '';
    final road = addr['road'] ?? '';
    final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? '';
    
    final formattedAddress = [road, suburb, city].where((e) => e.toString().isNotEmpty).join(', ');
    final dAddress = item['display_name'] ?? '';

    setState(() {
      _suggestions = [];
      _searchLocationCtrl.clear();
      _latitude = lat;
      _longitude = lon;
      _displayAddress = dAddress;
      
      _fullAddressCtrl.text = formattedAddress.isNotEmpty ? formattedAddress : dAddress.split(',').first;
      _cityCtrl.text = city;
      _stateCtrl.text = state;
      _pincodeCtrl.text = pincode;
    });
    
    try {
      _mapController.move(LatLng(lat, lon), 16.0);
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _searchLocationCtrl.dispose();
    _fullAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Address',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.md),
                // Search Location Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchLocationCtrl,
                    onChanged: (val) {
                      if (val.length > 2) _searchLocation(val);
                      else setState(() => _suggestions = []);
                    },
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: "Search for area, street, or location",
                      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primaryBlue, size: 18),
                      suffixIcon: _isSearching
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(LucideIcons.x, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchLocationCtrl.clear();
                                setState(() => _suggestions = []);
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        final parts = item['display_name'].toString().split(', ');
                        return ListTile(
                          leading: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue, size: 18),
                          title: Text(parts.isNotEmpty ? parts.first : '', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(parts.length > 1 ? parts.sublist(1).join(', ') : '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12)),
                          onTap: () => _handleSelection(item),
                        );
                      },
                    ),
                  ),
                
                if (_latitude != null && _longitude != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_latitude!, _longitude!),
                          initialZoom: 16.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.digital_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_latitude!, _longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(LucideIcons.mapPin, color: Colors.red, size: 30),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppTheme.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(LucideIcons.navigation, size: 18),
                    label: Text(_isGettingLocation ? 'Getting location...' : 'Use Current Location', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.xl),
                _buildTextField(
                  controller: _fullAddressCtrl,
                  hint: 'Full Address (Flat, Street, Area)',
                  icon: LucideIcons.mapPin,
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityCtrl,
                        hint: 'City',
                        icon: LucideIcons.building2,
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateCtrl,
                        hint: 'State',
                        icon: LucideIcons.map,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _pincodeCtrl,
                        hint: 'Pincode',
                        icon: LucideIcons.hash,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneCtrl,
                        hint: 'Phone',
                        icon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.lg),
                // Set as default toggle
                Row(
                  children: [
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeColor: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Set as default address',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Address',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppTheme.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.outfit(color: AppTheme.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, size: 16, color: AppTheme.textTertiary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      // Check if this is the first address (auto-set as default)
      final isFirstAddress = profileProvider.addresses.isEmpty;

      final address = AddressModel(
        addressId: const Uuid().v4(), // Generate unique ID client-side
        phone: _phoneCtrl.text.trim(),
        fullAddress: _fullAddressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault || isFirstAddress,
      );

      final success = await profileProvider.addAddress(widget.userId, address);

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address saved!', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to save address', style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
