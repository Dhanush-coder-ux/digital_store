import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import 'payment_method_page.dart';
import '../models/providers.dart';
import 'saved_addresses_page.dart'; // We could import this to navigate to Add New Address if we want.

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({super.key});

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  int _selectedAddressIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delivery Address',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
        ),
        centerTitle: true,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          final addresses = locationProvider.savedAddresses;

          // Ensure index doesn't go out of bounds if addresses are deleted
          if (_selectedAddressIndex >= addresses.length && addresses.isNotEmpty) {
            _selectedAddressIndex = 0;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAVED ADDRESSES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${addresses.length} Found',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
                if (addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No saved addresses yet.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  ...List.generate(addresses.length, (index) {
                    return FadeInUp(
                      delay: Duration(milliseconds: 80 * index),
                      child: _buildAddressCard(addresses[index], index),
                    );
                  }),
                const SizedBox(height: AppTheme.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildAddNewAddressBtn(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildAddressCard(SavedAddress address, int index) {
    final bool isSelected = _selectedAddressIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedAddressIndex = index),
      child: AnimatedContainer(
        duration: AppDurations.normal,
        margin: const EdgeInsets.only(bottom: AppTheme.lg),
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.04) : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [] : AppTheme.shadowSmall,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        address.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(LucideIcons.pencil, color: AppTheme.textTertiary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.md),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        address.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: AppTheme.lg),
                      Icon(LucideIcons.phone, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        address.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressBtn() {
    return GestureDetector(
      onTap: () {
        // Just route to the Saved Addresses page where they can add it via the beautiful modal
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavedAddressesPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plusCircle, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add New Address',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.xl),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.shadowXlarge,
          border: Border(top: BorderSide(color: AppTheme.veryLightGray)),
        ),
        child: GestureDetector(
          onTap: () {
            final provider = context.read<LocationProvider>();
            if (provider.savedAddresses.isNotEmpty) {
              // Update the global selected address to match what they picked in checkout!
              provider.selectAddress(provider.savedAddresses[_selectedAddressIndex]);
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentMethodPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.softRoyalBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Confirm Delivery Address',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                const Icon(LucideIcons.arrowRight, color: AppTheme.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
