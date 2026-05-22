import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../models/providers.dart';
import '../theme/app_theme.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  void _showAddAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddAddressModal(),
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
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          final addresses = locationProvider.savedAddresses;
          
          return SingleChildScrollView(
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
                        child: Text(
                          "No saved addresses yet.",
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...List.generate(addresses.length, (index) {
                      return FadeInUp(
                        delay: Duration(milliseconds: 100 * (index + 1)),
                        child: _buildAddressCard(context, addresses[index], locationProvider),
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
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, SavedAddress address, LocationProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.selectAddress(address);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address changed to ${address.title}'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        address.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.address,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF475569),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(LucideIcons.phone, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address.phone,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
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
  const _AddAddressModal();

  @override
  State<_AddAddressModal> createState() => _AddAddressModalState();
}

class _AddAddressModalState extends State<_AddAddressModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  
  String _title = 'Home';
  String _name = '';
  String _phone = '';

  @override
  void dispose() {
    _addressController.dispose();
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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: AppTheme.xl),
              _buildTextField('Title (e.g. Home, Office)', (v) => _title = v, initial: _title),
              const SizedBox(height: AppTheme.lg),
              _buildTextField('Full Address (Flat, Street, Area)', (v) { }, controller: _addressController),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final provider = context.read<LocationProvider>();
                  // Optionally show a quick loading snackbar or just await
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Locating...'), duration: Duration(seconds: 1)),
                  );
                  await provider.requestLocationAndGeocode();
                  setState(() {
                    _addressController.text = provider.fullAddressName;
                  });
                },
                child: Row(
                  children: [
                    const Icon(LucideIcons.navigation, color: AppTheme.primaryBlue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Use current location',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              _buildTextField('Contact Name', (v) => _name = v),
              const SizedBox(height: AppTheme.lg),
              _buildTextField('Phone Number', (v) => _phone = v, keyboardType: TextInputType.phone),
              const SizedBox(height: AppTheme.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newAddress = SavedAddress(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _title,
                        address: _addressController.text,
                        name: _name,
                        phone: _phone,
                      );
                      context.read<LocationProvider>().addSavedAddress(newAddress);
                      Navigator.pop(context); // Close modal
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
    );
  }

  Widget _buildTextField(String hint, Function(String) onSave, {TextEditingController? controller, String initial = '', TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initial : null,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.outfit(color: AppTheme.textTertiary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      onSaved: (newValue) => onSave(newValue!),
    );
  }
}
