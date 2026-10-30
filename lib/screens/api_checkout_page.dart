// lib/screens/api_checkout_page.dart
//
// Premium Flutter Cart & Checkout Screen — Light, Interactive, Production-Ready
//
// Highlights:
// 1. Slim, elegant light-themed app bar with subtle checkout progress indicator.
// 2. Compact shop identity summary row (preserves vertical screen real estate).
// 3. Polished, compact order items list with responsive stepper controls and delete actions.
// 4. Interactive delivery options with clean radio indicators, badges, and instant fee updates.
// 5. Expandable "Delivery fee details" (default collapsed, removing duplicate calculation clutter).
// 6. Free delivery progress banner with threshold tracking.
// 7. Clean delivery address section with saved address bottom sheet and manual editing.
// 8. Streamlined payment method selector.
// 9. Compact, multiline order note input with light-cream surface.
// 10. Transparent, single-source-of-truth order summary (no repeated equation boxes).
// 11. Fixed sticky bottom checkout bar with prominent amber "Place Order" button.
//

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shop_model.dart';
import '../models/shop_provider.dart';
import '../models/api_cart_provider.dart';
import '../models/cart_session_model.dart';
import '../models/profile_provider.dart';
import '../models/providers.dart';
import '../core/auth/auth_provider.dart';
import '../core/models/address_model.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import 'order_success_page.dart';
import 'main_screen.dart';
import 'saved_addresses_page.dart';
import '../services/delivery_eligibility_service.dart';

class ApiCheckoutPage extends StatefulWidget {
  final Shop shop;
  final bool isTab;

  const ApiCheckoutPage({
    super.key,
    required this.shop,
    this.isTab = false,
  });

  @override
  State<ApiCheckoutPage> createState() => _ApiCheckoutPageState();
}

class _ApiCheckoutPageState extends State<ApiCheckoutPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedPayment = 'Cash on Delivery';
  AddressModel? _selectedAddress;
  bool _isManualAddress = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
  ];

  List<ShopDeliveryOption> _deliveryOptions = [];
  ShopDeliveryOption? _selectedDeliveryOption;
  static const _eligibilityService = DeliveryEligibilityService();
  bool _isLoadingDeliveryOptions = false;

  // ── Warm Tangerine Contemporary Palette ──────────────────────────────
  static const Color _bg = AppTheme.background;             // Main warm background #FCFAF6
  static const Color _surface = AppTheme.surface;           // Pure white card background #FFFFFF
  static const Color _surfaceSecondary = AppTheme.softCream;// Secondary light-cream surface #F7F1E7
  static const Color _amberPrimary = AppTheme.primary;      // Primary warm tangerine #F28C28
  static const Color _amberLight = AppTheme.softPeach;      // Soft peach highlight #FFF3E3
  static const Color _amberBorder = Color(0xFFFCD5B5);      // Soft tangerine border
  static const Color _textPrimary = AppTheme.primaryText;   // Primary deep warm text #493629
  static const Color _textSecondary = AppTheme.secondaryText;// Secondary warm neutral text #8A7664
  static const Color _textTertiary = AppTheme.textTertiary; // Subtle tertiary text
  static const Color _borderSubtle = AppTheme.border;       // Delicate border #E9E2D8
  static const Color _successGreen = AppTheme.success;      // Serene success green #258A68
  static const Color _successBg = AppTheme.successBackground;// Soft success background #E9F7EF
  static const Color _errorRed = AppTheme.error;            // Accessible error red #DC2626
  static const Color _errorBg = AppTheme.errorBackground;   // Soft error background #FEF2F2

  @override
  void initState() {
    super.initState();

    // Initialize delivery options from shop configuration
    final opts = widget.shop.parsedDeliveryOptions.where((o) => o.enabled).toList();
    if (opts.isNotEmpty) {
      _deliveryOptions = opts;
    } else if (widget.shop.deliveryOptions.isNotEmpty) {
      _deliveryOptions = widget.shop.parsedDeliveryOptions;
    } else {
      _deliveryOptions = [
        ShopDeliveryOption.defaultStandard(
          deliveryCharge: widget.shop.minDeliveryCharge > 0
              ? widget.shop.minDeliveryCharge
              : AppNumbers.deliveryFee,
        )
      ];
    }

    // Default select first available delivery method (prefer non-pickup)
    _selectedDeliveryOption = _deliveryOptions.firstWhere(
      (o) => !o.isPickup,
      orElse: () => _deliveryOptions.first,
    );

    // Refresh cart items, load user profile & default address, and fetch live backend delivery options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiCartProvider>().refreshCart();
      _loadProfileAndDefaultAddress();
      _loadShopDeliveryOptions();
    });
  }

  Future<void> _loadShopDeliveryOptions() async {
    if (!mounted) return;
    setState(() => _isLoadingDeliveryOptions = true);
    try {
      final service = context.read<ShopProvider>().service;
      final opts = await service.fetchShopDeliveryOptions(widget.shop.id);
      if (mounted) {
        final deduplicated = _deduplicateDeliveryOptions(opts.isNotEmpty ? opts : _deliveryOptions);
        setState(() {
          _deliveryOptions = deduplicated;
          final currentType = _selectedDeliveryOption?.type;
          _selectedDeliveryOption = deduplicated.firstWhere(
            (o) => o.type == currentType,
            orElse: () => deduplicated.firstWhere(
              (o) => !o.isPickup,
              orElse: () => deduplicated.isNotEmpty ? deduplicated.first : ShopDeliveryOption.defaultStandard(),
            ),
          );
          _isLoadingDeliveryOptions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live delivery options for checkout: $e');
      if (mounted) setState(() => _isLoadingDeliveryOptions = false);
    }
  }

  List<ShopDeliveryOption> _deduplicateDeliveryOptions(List<ShopDeliveryOption> options) {
    return _eligibilityService.deduplicateOptions(options);
  }

  Future<void> _loadProfileAndDefaultAddress({bool force = false}) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();

      if (authProvider.userId != null) {
        if (!profileProvider.hasFetched || force) {
          await profileProvider.fetchProfile(authProvider.userId!, force: force);
        }
      }

      if (mounted) {
        _applyProfileAndAddress(profileProvider, authProvider);
      }
    } catch (e) {
      debugPrint('Error loading profile and address: $e');
    }
  }

  void _applyProfileAndAddress(ProfileProvider profileProvider, AuthProvider authProvider, {bool overwrite = false}) {
    final defaultAddr = profileProvider.defaultAddress;

    setState(() {
      if (_selectedAddress == null || overwrite) {
        _selectedAddress = defaultAddr;
      }

      // Name: populate if empty or overwrite
      if (_nameController.text.isEmpty || overwrite) {
        final profileName = profileProvider.userName.trim();
        if (profileName.isNotEmpty) {
          _nameController.text = profileName;
        } else if (authProvider.email != null && authProvider.email!.isNotEmpty) {
          _nameController.text = authProvider.email!.split('@').first;
        }
      }

      // Phone: populate from selected address or profile or auth mobile
      final addrPhone = _selectedAddress?.phone ?? defaultAddr?.phone ?? '';
      if ((_phoneController.text.isEmpty || overwrite) && addrPhone.isNotEmpty) {
        _phoneController.text = addrPhone;
      } else if (_phoneController.text.isEmpty && authProvider.mobile != null && authProvider.mobile!.isNotEmpty) {
        _phoneController.text = authProvider.mobile!;
      }

      // Address: populate if empty or overwrite
      if ((_addressController.text.isEmpty || overwrite) && _selectedAddress != null) {
        _addressController.text = _formatAddress(_selectedAddress!);
      }
    });
  }

  String _formatAddress(AddressModel addr) {
    final parts = [
      if (addr.fullAddress.trim().isNotEmpty) addr.fullAddress.trim(),
      if (addr.city.trim().isNotEmpty) addr.city.trim(),
      if (addr.state.trim().isNotEmpty) addr.state.trim(),
      if (addr.pincode.trim().isNotEmpty) 'PIN: ${addr.pincode.trim()}',
    ];
    return parts.join(', ');
  }

  void _selectSavedAddress(AddressModel addr) {
    setState(() {
      _selectedAddress = addr;
      _isManualAddress = false;
      _addressController.text = _formatAddress(addr);
      if (addr.phone.isNotEmpty) {
        _phoneController.text = addr.phone;
      }
    });
    try {
      context.read<LocationProvider>().selectAddressModel(addr);
    } catch (_) {}
  }

  Future<void> _openAddAddress(BuildContext context) async {
    final result = await Navigator.push<AddressModel?>(
      context,
      MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
    );

    if (mounted) {
      await _loadProfileAndDefaultAddress(force: true);
      if (result != null) {
        _selectSavedAddress(result);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Calculates effective distance between customer and shop (in km)
  double? _getEffectiveDistance() {
    if (widget.shop.distance != null && widget.shop.distance! > 0) {
      return widget.shop.distance;
    }

    try {
      final profileProvider = context.read<ProfileProvider>();
      final locationProvider = context.read<LocationProvider>();
      final activeAddress = _selectedAddress ?? profileProvider.defaultAddress;

      final double? userLat = activeAddress?.latitude ?? locationProvider.latitude;
      final double? userLng = activeAddress?.longitude ?? locationProvider.longitude;

      final shopAddr = widget.shop.address;
      if (shopAddr != null && userLat != null && userLng != null) {
        final double? shopLat = double.tryParse(
            shopAddr['latitude']?.toString() ?? shopAddr['lat']?.toString() ?? '');
        final double? shopLng = double.tryParse(
            shopAddr['longitude']?.toString() ?? shopAddr['lng']?.toString() ?? '');

        if (shopLat != null && shopLng != null) {
          return _calculateDistanceKm(userLat, userLng, shopLat, shopLng);
        }
      }
    } catch (_) {}

    return null;
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<void> _placeOrder({
    required ApiCartProvider cart,
    required double deliveryFee,
    required ShopDeliveryOption selectedOption,
  }) async {
    final profileProvider = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final activeAddress = _selectedAddress ?? profileProvider.defaultAddress;

    String name = _nameController.text.trim();
    if (name.isEmpty) {
      name = profileProvider.userName.trim();
    }
    if (name.isEmpty && auth.email != null && auth.email!.isNotEmpty) {
      name = auth.email!.split('@').first;
    }
    if (name.isEmpty) {
      name = 'Customer';
    }

    String phone = _phoneController.text.trim();
    if (phone.isEmpty && activeAddress != null && activeAddress.phone.trim().isNotEmpty) {
      phone = activeAddress.phone.trim();
    }
    if (phone.isEmpty && auth.mobile != null && auth.mobile!.isNotEmpty) {
      phone = auth.mobile!;
    }

    // 1. Minimum order value validation check
    if (selectedOption.minOrderAmount > 0 && cart.subtotal < selectedOption.minOrderAmount) {
      final double diff = selectedOption.minOrderAmount - cart.subtotal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Minimum order for ${selectedOption.title} is ₹${selectedOption.minOrderAmount.toStringAsFixed(0)}. Please add ₹${diff.toStringAsFixed(0)} more.',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 2. Service radius check
    final distance = _getEffectiveDistance();
    if (!selectedOption.isPickup && selectedOption.radius > 0 && distance != null && distance > selectedOption.radius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your delivery address is outside the service radius (${selectedOption.radius.toStringAsFixed(0)} km limit). Please choose Store Pickup or another address.',
          ),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 3. Delivery address validation (for non-pickup)
    if (!selectedOption.isPickup && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a delivery address'),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final String? selectedAddressId = (!_isManualAddress)
        ? (_selectedAddress?.addressId ?? profileProvider.defaultAddress?.addressId)
        : null;

    Map<String, dynamic>? deliveryAddress;

    if (activeAddress != null && !_isManualAddress) {
      deliveryAddress = {
        'address_id': ?selectedAddressId,
        'full_address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : activeAddress.fullAddress,
        'city': activeAddress.city,
        'pincode': activeAddress.pincode,
        'state': activeAddress.state,
        if ((activeAddress.latitude ?? locationProvider.latitude) != null)
          'latitude': activeAddress.latitude ?? locationProvider.latitude,
        if ((activeAddress.longitude ?? locationProvider.longitude) != null)
          'longitude': activeAddress.longitude ?? locationProvider.longitude,
      };
    } else if (_addressController.text.trim().isNotEmpty) {
      deliveryAddress = {
        'full_address': _addressController.text.trim(),
        if (locationProvider.latitude != null) 'latitude': locationProvider.latitude,
        if (locationProvider.longitude != null) 'longitude': locationProvider.longitude,
      };
    }

    final success = await cart.placeOrder(
      shopId: widget.shop.id,
      customerName: name,
      customerPhone: phone.isNotEmpty ? phone : null,
      paymentMethod: _selectedPayment,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      deliveryAddress: selectedOption.isPickup ? null : deliveryAddress,
      userId: auth.userId,
      addressId: selectedOption.isPickup ? null : selectedAddressId,
      fullAddress: selectedOption.isPickup
          ? null
          : (_addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : activeAddress?.fullAddress),
      city: selectedOption.isPickup ? null : activeAddress?.city,
      pincode: selectedOption.isPickup ? null : activeAddress?.pincode,
      state: selectedOption.isPickup ? null : activeAddress?.state,
      latitude: selectedOption.isPickup
          ? null
          : (activeAddress?.latitude ?? locationProvider.latitude),
      longitude: selectedOption.isPickup
          ? null
          : (activeAddress?.longitude ?? locationProvider.longitude),
      deliveryFee: deliveryFee,
      deliveryOptionInfo: selectedOption.toPayload(deliveryFee),
    );

    if (success && mounted) {
      if (widget.isTab) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(
              order: cart.lastOrder,
              shopName: widget.shop.name,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(
              order: cart.lastOrder,
              shopName: widget.shop.name,
            ),
          ),
        );
      }
    } else if (!success && mounted && cart.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.error!),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      cart.clearError();
    }
  }

  // ── Main Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiCartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.subtotal;
        final distance = _getEffectiveDistance();
        // Evaluate eligible options based on customer location and cart subtotal
        final deduplicated = _eligibilityService.deduplicateOptions(_deliveryOptions);
        final results = _eligibilityService.evaluateOptions(
          options: deduplicated,
          customerDistance: distance,
          subtotal: subtotal,
          alreadyDeduplicated: true,
        );
        final eligible = results.where((r) => r.isEligible).toList();

        // Automatically determine the selected option:
        // 1. If customer previously selected an option and it is still eligible, keep it.
        // 2. Otherwise prefer best home-delivery (non-pickup) option.
        // 3. If only pickup is available, select pickup.
        // 4. If none eligible, fallback to first deduplicated or default standard.
        ShopDeliveryOption selectedOption;
        if (_selectedDeliveryOption != null &&
            eligible.any((r) => r.option.type == _selectedDeliveryOption!.type)) {
          selectedOption = eligible.firstWhere((r) => r.option.type == _selectedDeliveryOption!.type).option;
        } else {
          final nonPickup = eligible.where((r) => !r.option.isPickup).toList();
          if (nonPickup.isNotEmpty) {
            selectedOption = nonPickup.first.option;
          } else if (eligible.isNotEmpty) {
            selectedOption = eligible.first.option;
          } else {
            selectedOption = deduplicated.isNotEmpty ? deduplicated.first : ShopDeliveryOption.defaultStandard();
          }
        }

        final selectedResult = results.firstWhere(
          (r) => r.option.type == selectedOption.type,
          orElse: () => DeliveryEligibilityResult(
            option: selectedOption,
            isEligible: false,
            calc: selectedOption.calculate(subtotal: subtotal, distance: distance),
            customerDistance: distance,
          ),
        );
        final deliveryCalc = selectedResult.calc ?? selectedOption.calculate(
          subtotal: subtotal,
          distance: distance,
        );
        final deliveryFee = deliveryCalc.fee;
        final total = subtotal + deliveryFee;

        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: cart.isLoading && cart.items.isEmpty
              ? _buildLoading()
              : cart.isEmpty
                  ? _buildEmptyCart()
                  : _buildContent(
                      cart: cart,
                      distance: distance,
                      selectedOption: selectedOption,
                      deliveryCalc: deliveryCalc,
                      deliveryFee: deliveryFee,
                      total: total,
                    ),
          bottomNavigationBar: cart.isEmpty
              ? null
              : _buildPlaceOrderButton(
                  cart: cart,
                  total: total,
                  deliveryFee: deliveryFee,
                  selectedOption: selectedOption,
                  distance: distance,
                ),
        );
      },
    );
  }

  // ── 1. Slim, Elegant Light Navigation Bar ───────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: widget.isTab
          ? null
          : IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _surfaceSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderSubtle),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: _textPrimary, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Checkout',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepIndicator('Cart', isDone: true),
              _buildStepDivider(),
              _buildStepIndicator('Delivery', isDone: true),
              _buildStepDivider(),
              _buildStepIndicator('Review', isActive: true),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _borderSubtle, height: 1),
      ),
    );
  }

  Widget _buildStepIndicator(String label, {bool isDone = false, bool isActive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? _amberPrimary
                : (isDone ? _successGreen : _textTertiary),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? _amberPrimary
                : (isDone ? _textSecondary : _textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        width: 8,
        height: 1,
        color: _borderSubtle,
      ),
    );
  }

  // ── States: Loading & Empty ─────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: _amberPrimary, strokeWidth: 2.5),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _amberLight,
                border: Border.all(color: _amberBorder),
              ),
              child: const Icon(LucideIcons.shoppingBag, size: 38, color: _amberPrimary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items from your favorite store to proceed with order checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.isTab) {
                  MainScreen.pageIndexNotifier.value = 0;
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amberPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content Scroll View ─────────────────────────────────────────────

  Widget _buildContent({
    required ApiCartProvider cart,
    required double? distance,
    required ShopDeliveryOption selectedOption,
    required DeliveryCalculationResult deliveryCalc,
    required double deliveryFee,
    required double total,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Compact Shop Identity Summary
          _buildShopSummaryRow(),
          const SizedBox(height: 12),

          // 2. Order Items List
          _buildCartItemsSection(cart),
          const SizedBox(height: 12),

          // 3. Interactive Delivery Selection
          _buildDeliverySection(
            cart: cart,
            distance: distance,
            selectedOption: selectedOption,
            calc: deliveryCalc,
          ),
          const SizedBox(height: 12),

          // 4. Delivery Address or Store Pickup Notice
          if (!selectedOption.isPickup) ...[
            _buildAddressSection(distance: distance, selectedOption: selectedOption),
            const SizedBox(height: 12),
          ] else ...[
            _buildPickupInfoSection(),
            const SizedBox(height: 12),
          ],

          // 5. Payment Method Selection
          _buildPaymentSection(),
          const SizedBox(height: 12),

          // 6. Optional Order Note
          _buildNoteSection(),
          const SizedBox(height: 12),

          // 7. Transparent Consolidated Pricing Summary
          _buildPriceSummary(
            subtotal: cart.subtotal,
            deliveryFee: deliveryFee,
            total: total,
            calc: deliveryCalc,
            selectedOption: selectedOption,
          ),
        ],
      ),
    );
  }

  // ── 2. Compact Shop Identity Summary Row ────────────────────────────

  Widget _buildShopSummaryRow() {
    final hasLogo = widget.shop.logoUrl != null && widget.shop.logoUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: widget.shop.logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        LucideIcons.store,
                        color: _amberPrimary,
                        size: 18,
                      ),
                    )
                  : const Icon(
                      LucideIcons.store,
                      color: _amberPrimary,
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.shop.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: _amberPrimary),
                  ],
                ),
                Text(
                  widget.shop.displayAddress.isNotEmpty
                      ? widget.shop.displayAddress
                      : (widget.shop.city.isNotEmpty ? widget.shop.city : 'Verified Local Store'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5,
                    color: _textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: _surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderSubtle),
            ),
            child: const Text(
              'Store Order',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Order Items Section ──────────────────────────────────────────

  Widget _buildCartItemsSection(ApiCartProvider cart) {
    return _sectionCard(
      title: 'Order Items',
      icon: LucideIcons.shoppingBag,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: _surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _borderSubtle),
        ),
        child: Text(
          '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
      ),
      child: Column(
        children: [
          ...cart.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _CartItemRow(item: item, cart: cart),
                if (i < cart.items.length - 1)
                  const Divider(color: _borderSubtle, height: 18),
              ],
            );
          }),
          // Local fallback items if synced before backend response
          if (cart.items.isEmpty)
            ...cart.localItems.map((e) => _LocalItemRow(entry: e)),
        ],
      ),
    );
  }

  // ── 4. Automatically Determined Delivery Section ──────────────────────

  Widget _buildDeliverySection({
    required ApiCartProvider cart,
    required double? distance,
    required ShopDeliveryOption selectedOption,
    required DeliveryCalculationResult calc,
  }) {
    final subtotal = cart.subtotal;
    final deduplicated = _eligibilityService.deduplicateOptions(_deliveryOptions);
    final results = _eligibilityService.evaluateOptions(
      options: deduplicated,
      customerDistance: distance,
      subtotal: subtotal,
      alreadyDeduplicated: true,
    );
    final eligible = results.where((r) => r.isEligible).toList();
    final isSelectedFree = calc.isFree || selectedOption.isPickup;

    IconData getOptionIcon(ShopDeliveryOption opt) {
      if (opt.isPickup) return LucideIcons.shoppingBag;
      if (opt.isInstant) return LucideIcons.zap;
      if (opt.isNationwide) return LucideIcons.globe;
      return LucideIcons.truck;
    }

    Color getOptionColor(ShopDeliveryOption opt) {
      if (opt.isPickup) return _successGreen;
      if (opt.isInstant) return _amberPrimary;
      if (opt.isNationwide) return const Color(0xFF6366F1);
      return _amberPrimary;
    }

    return _sectionCard(
      title: 'Delivery',
      icon: LucideIcons.truck,
      trailing: distance != null && distance > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.mapPin, size: 11, color: _amberPrimary),
                  const SizedBox(width: 4),
                  Text(
                    '~${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingDeliveryOptions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _amberPrimary),
                ),
              ),
            )
          else if (distance != null && deduplicated.isNotEmpty && eligible.isEmpty)
            // No eligible delivery option for this location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _errorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 18, color: _errorRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Not Available',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _errorRed,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'This store does not deliver to your address (${DeliveryEligibilityService.formatDistance(distance)} away). Please choose a different address or contact the store.',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            color: Color(0xFF991B1B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Primary Determined Delivery Option
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _amberLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _amberBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      getOptionIcon(selectedOption),
                      size: 16,
                      color: getOptionColor(selectedOption),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Option Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isSelectedFree && !selectedOption.isPickup
                                    ? 'Free ${selectedOption.title}'
                                    : selectedOption.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _amberPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Determined',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _amberPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedOption.isPickup
                              ? (selectedOption.speed.isNotEmpty ? selectedOption.speed : 'Ready same day')
                              : (selectedOption.speed.isNotEmpty
                                  ? selectedOption.speed
                                  : 'Standard dispatch'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Fee Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isSelectedFree ? _successBg : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelectedFree ? const Color(0xFFA7F3D0) : _borderSubtle,
                      ),
                    ),
                    child: Text(
                      isSelectedFree ? 'FREE' : '₹${calc.fee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelectedFree ? _successGreen : _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Multiple Eligible Options Switcher (clean tabs, no raw admin parameters)
            if (eligible.length > 1) ...[
              const SizedBox(height: 10),
              const Text(
                'Other Available Options',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: eligible.map((r) {
                  final opt = r.option;
                  final isSelected = opt.type == selectedOption.type;
                  final feeStr = r.calc?.isFree == true || opt.isPickup
                      ? 'FREE'
                      : '₹${(r.calc?.fee ?? opt.deliveryCharge).toStringAsFixed(0)}';
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDeliveryOption = opt;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _amberLight : _surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _amberPrimary : _borderSubtle,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.title,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? _amberPrimary : _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            feeStr,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: feeStr == 'FREE' ? _successGreen : _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],

          // Minimum Order Requirement Notice
          if (selectedOption.minOrderAmount > 0 && subtotal < selectedOption.minOrderAmount) ...[
            const SizedBox(height: 8),
            _buildMinOrderWarning(subtotal, selectedOption.minOrderAmount),
          ],

          // Free Delivery Incentive Progress Bar
          if (!selectedOption.isPickup && selectedOption.freeShippingAmount > 0) ...[
            const SizedBox(height: 8),
            if (calc.isFreeThresholdReached)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _successBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.checkCircle2, size: 14, color: _successGreen),
                    SizedBox(width: 6),
                    Text(
                      'Free delivery unlocked on this order!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _successGreen,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.gift, size: 13, color: _amberPrimary),
                            const SizedBox(width: 6),
                            Text(
                              'Add ₹${(selectedOption.freeShippingAmount - subtotal).toStringAsFixed(0)} more for FREE delivery',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${selectedOption.freeShippingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (subtotal / selectedOption.freeShippingAmount).clamp(0.0, 1.0),
                        backgroundColor: _borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(_amberPrimary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinOrderWarning(double subtotal, double minAmount) {
    final diff = minAmount - subtotal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Minimum order ₹${minAmount.toStringAsFixed(0)} required. Add ₹${diff.toStringAsFixed(0)} more.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Delivery Address / Store Pickup Location ─────────────────────

  Widget _buildPickupInfoSection() {
    return _sectionCard(
      title: 'Store Pickup Location',
      icon: LucideIcons.shoppingBag,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _successBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(LucideIcons.store, size: 16, color: _successGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shop.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.shop.displayAddress.isNotEmpty
                        ? widget.shop.displayAddress
                        : 'Collect directly in-store after order confirmation.',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No delivery address required for store pickup.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _successGreen,
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

  Widget _buildAddressSection({
    required double? distance,
    required ShopDeliveryOption selectedOption,
  }) {
    final profileProvider = context.watch<ProfileProvider>();
    final addresses = profileProvider.addresses;
    final activeAddress = _selectedAddress ?? profileProvider.defaultAddress;

    final isOutsideRadius = selectedOption.radius > 0 &&
        distance != null &&
        distance > selectedOption.radius;

    return _sectionCard(
      title: 'Delivery Address',
      icon: LucideIcons.mapPin,
      trailing: (addresses.isNotEmpty)
          ? GestureDetector(
              onTap: () => _showAddressSelectionSheet(context, profileProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.repeat, size: 11, color: _amberPrimary),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _amberPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeAddress != null && !_isManualAddress) ...[
            // Selected Saved Address Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeAddress.isDefault ? _successBg : _amberLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: activeAddress.isDefault ? const Color(0xFFA7F3D0) : _amberBorder,
                          ),
                        ),
                        child: Text(
                          activeAddress.isDefault ? 'DEFAULT' : 'SAVED',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: activeAddress.isDefault ? _successGreen : _amberPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (activeAddress.phone.isNotEmpty)
                        Text(
                          activeAddress.phone,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeAddress.fullAddress,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeAddress.city}, ${activeAddress.state} - ${activeAddress.pincode}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Warning if outside radius
            if (isOutsideRadius) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 14, color: _errorRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address (~${distance.toStringAsFixed(1)} km) is outside the service area limit (${selectedOption.radius.toStringAsFixed(0)} km).',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _showAddressSelectionSheet(context, profileProvider),
                  child: Text(
                    'Choose from saved (${addresses.length})',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _amberPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isManualAddress = true;
                    });
                  },
                  child: const Text(
                    'Edit manually',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      color: _textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Manual Address Entry Fields
            TextField(
              controller: _addressController,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter complete street address...',
                hintStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  color: _textTertiary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _amberPrimary),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Contact phone number',
                hintStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  color: _textTertiary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: _surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _amberPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            if (addresses.isNotEmpty) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  if (activeAddress != null) {
                    _selectSavedAddress(activeAddress);
                  } else {
                    _showAddressSelectionSheet(context, profileProvider);
                  }
                },
                child: const Text(
                  'Use saved address instead',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _amberPrimary,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _openAddAddress(context),
                child: const Text(
                  '+ Add and save address',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _amberPrimary,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showAddressSelectionSheet(BuildContext context, ProfileProvider profileProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final addresses = profileProvider.addresses;
        final currentSelected = _selectedAddress ?? profileProvider.defaultAddress;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Delivery Address',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18, color: _textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _borderSubtle),
              Flexible(
                child: addresses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No saved addresses yet',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(14),
                        itemCount: addresses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final addr = addresses[index];
                          final isSelected = currentSelected != null &&
                              (addr.addressId == currentSelected.addressId ||
                                  (addr.fullAddress == currentSelected.fullAddress &&
                                      addr.pincode == currentSelected.pincode));

                          return GestureDetector(
                            onTap: () {
                              _selectSavedAddress(addr);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? _amberLight : _surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _amberPrimary : _borderSubtle,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? _amberPrimary : _borderSubtle,
                                          width: isSelected ? 4.5 : 1.5,
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (addr.isDefault)
                                              Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: _successBg,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: const Text(
                                                  'DEFAULT',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: _successGreen,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              addr.displayShort,
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          addr.fullAddress,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: _textSecondary,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1, color: _borderSubtle),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openAddAddress(context);
                        },
                        icon: const Icon(LucideIcons.plus, size: 15),
                        label: const Text('Add New Address'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _amberPrimary,
                          side: const BorderSide(color: _amberPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isManualAddress = true;
                        });
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: const BorderSide(color: _borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      child: const Text('Manual'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 6. Payment Method Section ───────────────────────────────────────

  Widget _buildPaymentSection() {
    return _sectionCard(
      title: 'Payment Method',
      icon: LucideIcons.creditCard,
      child: Column(
        children: _paymentMethods.map((method) {
          final isSelected = method == _selectedPayment;
          return GestureDetector(
            onTap: () => setState(() => _selectedPayment = method),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? _amberLight : _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _amberPrimary : _borderSubtle,
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _amberPrimary : _borderSubtle,
                        width: isSelected ? 5.5 : 1.5,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _surfaceSecondary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(LucideIcons.banknote, size: 16, color: _amberPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        const Text(
                          'Pay in cash or UPI upon delivery / pickup',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 7. Optional Order Note ──────────────────────────────────────────

  Widget _buildNoteSection() {
    return _sectionCard(
      title: 'Order Note (optional)',
      icon: LucideIcons.fileText,
      child: TextField(
        controller: _noteController,
        maxLines: 2,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          color: _textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Any special instructions for this order?',
          hintStyle: const TextStyle(
            fontFamily: 'Outfit',
            color: _textTertiary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: _surfaceSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _amberPrimary),
          ),
          contentPadding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  // ── 8. Consolidated Order Summary & Total ───────────────────────────

  Widget _buildPriceSummary({
    required double subtotal,
    required double deliveryFee,
    required double total,
    required DeliveryCalculationResult calc,
    required ShopDeliveryOption selectedOption,
  }) {
    final cart = context.watch<ApiCartProvider>();
    return _sectionCard(
      title: 'Order Summary',
      icon: LucideIcons.receipt,
      child: Column(
        children: [
          _summaryRow(
            'Items Subtotal (${cart.itemCount})',
            '₹${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee (${selectedOption.isPickup ? 'Pickup' : selectedOption.title})',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
              if (calc.isFree)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (calc.isFreeThresholdReached && calc.originalFee > 0) ...[
                      Text(
                        '₹${calc.originalFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          decoration: TextDecoration.lineThrough,
                          color: _textTertiary,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    const Text(
                      'FREE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _successGreen,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '₹${deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
            ],
          ),
          if (selectedOption.minOrderAmount > 0 && subtotal < selectedOption.minOrderAmount) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Min. Order Required',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFFD97706)),
                ),
                Text(
                  '₹${selectedOption.minOrderAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: _borderSubtle, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _amberPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  // ── 9. Premium Sticky Checkout Action Bar ───────────────────────────

  Widget _buildPlaceOrderButton({
    required ApiCartProvider cart,
    required double total,
    required double deliveryFee,
    required ShopDeliveryOption selectedOption,
    required double? distance,
  }) {
    final isPlacing = cart.state == CartState.placingOrder;
    final bool isBelowMinOrder =
        selectedOption.minOrderAmount > 0 && cart.subtotal < selectedOption.minOrderAmount;
    final double minOrderDiff =
        isBelowMinOrder ? (selectedOption.minOrderAmount - cart.subtotal) : 0.0;

    final bool isOutsideRadius = !selectedOption.isPickup &&
        selectedOption.radius > 0 &&
        distance != null &&
        distance > selectedOption.radius;

    final eligibilityCheck = _eligibilityService.evaluateOptions(
      options: _deliveryOptions,
      customerDistance: distance,
      subtotal: cart.subtotal,
      alreadyDeduplicated: true,
    );
    final hasAnyEligible = eligibilityCheck.any((r) => r.isEligible);
    final bool noDeliveryAvailable = _deliveryOptions.isNotEmpty && !hasAnyEligible;

    final bool isMissingAddress = !selectedOption.isPickup &&
        _selectedAddress == null &&
        _addressController.text.trim().isEmpty;

    final bool canPlace = !isPlacing &&
        !isBelowMinOrder &&
        !isOutsideRadius &&
        !noDeliveryAvailable &&
        !isMissingAddress;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(top: BorderSide(color: _borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Amount Summary
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total to Pay',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Button
          Expanded(
            flex: 6,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canPlace
                    ? () => _placeOrder(
                          cart: cart,
                          deliveryFee: deliveryFee,
                          selectedOption: selectedOption,
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBelowMinOrder
                      ? const Color(0xFFD97706)
                      : (isMissingAddress
                          ? const Color(0xFFD97706)
                          : (isOutsideRadius || noDeliveryAvailable ? _errorRed : _amberPrimary)),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _borderSubtle,
                  disabledForegroundColor: _textTertiary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isPlacing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Placing Order...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : isBelowMinOrder
                        ? Text(
                            'Add ₹${minOrderDiff.toStringAsFixed(0)} more',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : isMissingAddress
                            ? const Text(
                                'Select Delivery Address',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : (isOutsideRadius || noDeliveryAvailable)
                                ? Text(
                                    noDeliveryAvailable ? 'Delivery Not Available' : 'Outside Radius',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(LucideIcons.shoppingBag, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Place Order',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Section Card Container ─────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _amberPrimary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Cart Item Row ────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartSessionItem item;
  final ApiCartProvider cart;

  const _CartItemRow({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.softPeach,
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.productImage != null
              ? CachedNetworkImage(
                  imageUrl: item.productImage!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(
                    LucideIcons.package,
                    color: Color(0xFFAFA293),
                    size: 20,
                  ),
                )
              : const Icon(LucideIcons.package, color: Color(0xFFAFA293), size: 20),
        ),
        const SizedBox(width: 10),

        // Product Name & Variant info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF493629),
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.variantName != null || item.batchName != null || item.serialName != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.variantName != null) item.variantName,
                    if (item.batchName != null) item.batchName,
                    if (item.serialName != null) item.serialName,
                  ].join(' • '),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 3),
              Text(
                '₹${item.sellingPrice.toStringAsFixed(2)}${item.unit != null ? ' / ${item.unit}' : ''}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5,
                  color: Color(0xFF8A7664),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Line Total & Quantity Stepper
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${item.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF493629),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (item.qty <= 1) {
                        await cart.removeItem(
                          productId: item.productId,
                          variantId: item.variantId,
                          batchId: item.batchId,
                        );
                      } else {
                        await cart.updateQuantity(item, item.qty.round() - 1);
                      }
                    },
                    child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      item.qty <= 1 ? LucideIcons.trash2 : LucideIcons.minus,
                      size: 13,
                      color: item.qty <= 1 ? const Color(0xFFDC2626) : const Color(0xFF8A7664),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.qty.round()}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF493629),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await cart.updateQuantity(item, item.qty.round() + 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(LucideIcons.plus, size: 13, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
}

// ── Local Cart Entry Row ─────────────────────────────────────────────

class _LocalItemRow extends StatelessWidget {
  final dynamic entry;

  const _LocalItemRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.softPeach,
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text(
              entry.product.name.isNotEmpty ? entry.product.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.product.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF493629),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'Qty: ${entry.qty} • ₹${entry.product.displayPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5,
                  color: Color(0xFF8A7664),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${(entry.product.displayPrice * entry.qty).toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF493629),
          ),
        ),
      ],
    );
  }
}
