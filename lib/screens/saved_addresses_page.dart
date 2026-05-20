import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> addresses = [
      {
        "title": "Home",
        "address": "123 Maple Street, Springfield, IL 62704",
        "name": "Deepak Roshan",
        "phone": "+1 (217) 555-0123"
      },
      {
        "title": "Office",
        "address": "456 Business Hub, Suite 200, Chicago, IL 60601",
        "name": "Deepak Roshan",
        "phone": "+1 (312) 555-0199"
      },
      {
        "title": "Parent's House",
        "address": "789 Oak Lane, Naperville, IL 60540",
        "name": "Deepak Roshan",
        "phone": "+1 (630) 555-0456"
      }
    ];

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
      body: SingleChildScrollView(
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
                        color: const Color(0xFFA855F7), // purple theme from icon
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
              ...List.generate(addresses.length, (index) {
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * (index + 1)),
                  child: _buildAddressCard(addresses[index], index),
                );
              }),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildAddNewAddressBtn(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.mapPin, color: Color(0xFFA855F7), size: 20),
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
                      address['title'],
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Icon(LucideIcons.moreVertical, color: Colors.grey.shade400, size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address['address'],
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
                    Text(
                      address['name'],
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(LucideIcons.phone, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      address['phone'],
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
    );
  }

  Widget _buildAddNewAddressBtn() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFA855F7).withOpacity(0.4),
            width: 1,
            style: BorderStyle.solid, 
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.plusCircle, color: Color(0xFFA855F7), size: 20),
            const SizedBox(width: 8),
            Text(
              "Add New Address",
              style: GoogleFonts.outfit(
                color: const Color(0xFFA855F7),
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
