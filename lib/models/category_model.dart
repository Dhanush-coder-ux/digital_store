// lib/models/category_model.dart
//
// Realistic Category Catalog & Model for Digital Store
// Inspired by Blinkit & Zepto modern quick-commerce product imagery.
// Supports custom image URLs, local asset configurations, and realistic photo fallbacks.

import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final String imageUrl;
  final String? assetPath;
  final String? subtitle;
  final Color backgroundColor;
  final Color borderColor;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.assetPath,
    this.subtitle,
    this.backgroundColor = const Color(0xFFFFF7ED), // Warm soft peach / cream
    this.borderColor = const Color(0xFFE9E2D8),
  });

  CategoryItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? assetPath,
    String? subtitle,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      subtitle: subtitle ?? this.subtitle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}

class CategoryCatalog {
  /// User-configurable asset overrides (e.g. {'fruits': 'assets/categories/fruits.png'})
  static final Map<String, String> customAssetMap = {};

  /// User-configurable URL overrides (e.g. {'bakery': 'https://...'})
  static final Map<String, String> customUrlMap = {};

  // ── Curated Realistic Product Images (Blinkit & Zepto Style) ───────────────

  static const String imgAll =
      'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80';
  static const String imgFruits =
      'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=400&q=80';
  static const String imgVegetables =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=400&q=80';
  static const String imgDairy =
      'https://images.unsplash.com/photo-1528750997573-59b89d56f4f7?auto=format&fit=crop&w=400&q=80';
  static const String imgBakery =
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80';
  static const String imgGrocery =
      'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=400&q=80';
  static const String imgBeverages =
      'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=400&q=80';
  static const String imgSnacks =
      'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=400&q=80';
  static const String imgPharmacy =
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80';
  static const String imgElectronics =
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80';
  static const String imgFashion =
      'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=400&q=80';
  static const String imgBeauty =
      'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80';
  static const String imgMeat =
      'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=400&q=80';
  static const String imgHome =
      'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?auto=format&fit=crop&w=400&q=80';
  static const String imgBaby =
      'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=400&q=80';
  static const String imgPet =
      'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=400&q=80';
  static const String imgCleaning =
      'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=400&q=80';
  static const String imgStationery =
      'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=400&q=80';
  static const String imgToys =
      'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?auto=format&fit=crop&w=400&q=80';
  static const String imgOrganic =
      'https://images.unsplash.com/photo-1509358271058-acd22cc93898?auto=format&fit=crop&w=400&q=80';

  // ── Curated Standard Category List ─────────────────────────────────────────

  static const List<CategoryItem> standardCategories = [
    CategoryItem(
      id: 'all',
      name: 'All',
      subtitle: 'All Stores & Items',
      imageUrl: imgAll,
    ),
    CategoryItem(
      id: 'fruits',
      name: 'Fruits',
      subtitle: 'Fresh & Crisp',
      imageUrl: imgFruits,
    ),
    CategoryItem(
      id: 'vegetables',
      name: 'Vegetables',
      subtitle: 'Farm Fresh',
      imageUrl: imgVegetables,
    ),
    CategoryItem(
      id: 'dairy',
      name: 'Dairy & Eggs',
      subtitle: 'Milk, Butter & Cheese',
      imageUrl: imgDairy,
    ),
    CategoryItem(
      id: 'bakery',
      name: 'Bakery',
      subtitle: 'Artisan Bread & Bakes',
      imageUrl: imgBakery,
    ),
    CategoryItem(
      id: 'grocery',
      name: 'Grocery',
      subtitle: 'Atta, Rice & Staples',
      imageUrl: imgGrocery,
    ),
    CategoryItem(
      id: 'pharmacy',
      name: 'Pharmacy',
      subtitle: 'Wellness & Medicine',
      imageUrl: imgPharmacy,
    ),
    CategoryItem(
      id: 'snacks',
      name: 'Snacks & Munchies',
      subtitle: 'Chips, Biscuits & Sweets',
      imageUrl: imgSnacks,
    ),
    CategoryItem(
      id: 'beverages',
      name: 'Beverages',
      subtitle: 'Cold Drinks & Juices',
      imageUrl: imgBeverages,
    ),
    CategoryItem(
      id: 'electronics',
      name: 'Electronics',
      subtitle: 'Audio, Tech & Accessories',
      imageUrl: imgElectronics,
    ),
    CategoryItem(
      id: 'fashion',
      name: 'Fashion',
      subtitle: 'Apparel & Trends',
      imageUrl: imgFashion,
    ),
    CategoryItem(
      id: 'beauty',
      name: 'Personal Care',
      subtitle: 'Beauty & Skincare',
      imageUrl: imgBeauty,
    ),
    CategoryItem(
      id: 'meat',
      name: 'Meat & Seafood',
      subtitle: 'Fresh Cuts & Poultry',
      imageUrl: imgMeat,
    ),
    CategoryItem(
      id: 'home',
      name: 'Home & Kitchen',
      subtitle: 'Cookware & Living',
      imageUrl: imgHome,
    ),
    CategoryItem(
      id: 'baby',
      name: 'Baby Care',
      subtitle: 'Gentle Baby Essentials',
      imageUrl: imgBaby,
    ),
    CategoryItem(
      id: 'pet',
      name: 'Pet Supplies',
      subtitle: 'Pet Food & Treats',
      imageUrl: imgPet,
    ),
    CategoryItem(
      id: 'cleaning',
      name: 'Cleaning',
      subtitle: 'Detergents & Freshness',
      imageUrl: imgCleaning,
    ),
    CategoryItem(
      id: 'stationery',
      name: 'Stationery',
      subtitle: 'Books & Office',
      imageUrl: imgStationery,
    ),
    CategoryItem(
      id: 'toys',
      name: 'Toys & Games',
      subtitle: 'Fun & Educational',
      imageUrl: imgToys,
    ),
    CategoryItem(
      id: 'organic',
      name: 'Organic & Gourmet',
      subtitle: 'Wholesome & Pure',
      imageUrl: imgOrganic,
    ),
  ];

  /// Finds or creates a CategoryItem matching the category name with realistic imagery.
  static CategoryItem find(
    String categoryName, {
    String? customImageUrl,
    String? customAssetPath,
  }) {
    final clean = categoryName.trim();
    final lower = clean.toLowerCase();

    // Check custom overrides first
    final customUrl = customImageUrl ?? customUrlMap[clean] ?? customUrlMap[lower];
    final customAsset = customAssetPath ?? customAssetMap[clean] ?? customAssetMap[lower];

    if (customUrl != null || customAsset != null) {
      return CategoryItem(
        id: lower.replaceAll(RegExp(r'\s+'), '_'),
        name: clean.isEmpty ? 'Category' : clean,
        imageUrl: customUrl ?? imgAll,
        assetPath: customAsset,
        subtitle: 'Specialty Selection',
      );
    }

    if (lower == 'all' || lower == 'all stores' || lower == 'all items') {
      return standardCategories[0];
    }

    if (lower.contains('fruit')) {
      return standardCategories[1].copyWith(name: clean.isEmpty ? 'Fruits' : clean);
    }
    if (lower.contains('veg') || lower.contains('produce') || lower.contains('greens')) {
      return standardCategories[2].copyWith(name: clean.isEmpty ? 'Vegetables' : clean);
    }
    if (lower.contains('dairy') || lower.contains('milk') || lower.contains('egg') || lower.contains('cheese') || lower.contains('butter')) {
      return standardCategories[3].copyWith(name: clean.isEmpty ? 'Dairy & Eggs' : clean);
    }
    if (lower.contains('bake') || lower.contains('bread') || lower.contains('cake') || lower.contains('pastr')) {
      return standardCategories[4].copyWith(name: clean.isEmpty ? 'Bakery' : clean);
    }
    if (lower.contains('grocer') || lower.contains('staple') || lower.contains('atta') || lower.contains('rice') || lower.contains('dal') || lower.contains('oil') || lower.contains('grain')) {
      return standardCategories[5].copyWith(name: clean.isEmpty ? 'Grocery' : clean);
    }
    if (lower.contains('pharm') || lower.contains('med') || lower.contains('health') || lower.contains('wellness') || lower.contains('drug')) {
      return standardCategories[6].copyWith(name: clean.isEmpty ? 'Pharmacy' : clean);
    }
    if (lower.contains('snack') || lower.contains('munch') || lower.contains('biscuit') || lower.contains('chip') || lower.contains('cookie') || lower.contains('namkeen') || lower.contains('sweet')) {
      return standardCategories[7].copyWith(name: clean.isEmpty ? 'Snacks' : clean);
    }
    if (lower.contains('bever') || lower.contains('drink') || lower.contains('juice') || lower.contains('tea') || lower.contains('coffee') || lower.contains('soda') || lower.contains('water')) {
      return standardCategories[8].copyWith(name: clean.isEmpty ? 'Beverages' : clean);
    }
    if (lower.contains('elect') || lower.contains('tech') || lower.contains('gadget') || lower.contains('phone') || lower.contains('headphone') || lower.contains('cable') || lower.contains('cpu')) {
      return standardCategories[9].copyWith(name: clean.isEmpty ? 'Electronics' : clean);
    }
    if (lower.contains('fash') || lower.contains('cloth') || lower.contains('shirt') || lower.contains('apparel') || lower.contains('wear') || lower.contains('dress') || lower.contains('shoe')) {
      return standardCategories[10].copyWith(name: clean.isEmpty ? 'Fashion' : clean);
    }
    if (lower.contains('beauty') || lower.contains('cosmetic') || lower.contains('skincare') || lower.contains('personal') || lower.contains('soap') || lower.contains('shampoo')) {
      return standardCategories[11].copyWith(name: clean.isEmpty ? 'Personal Care' : clean);
    }
    if (lower.contains('meat') || lower.contains('fish') || lower.contains('chicken') || lower.contains('seafood') || lower.contains('prawn') || lower.contains('mutton')) {
      return standardCategories[12].copyWith(name: clean.isEmpty ? 'Meat & Seafood' : clean);
    }
    if (lower.contains('home') || lower.contains('kitchen') || lower.contains('furn') || lower.contains('cookware') || lower.contains('utensil')) {
      return standardCategories[13].copyWith(name: clean.isEmpty ? 'Home & Kitchen' : clean);
    }
    if (lower.contains('baby')) {
      return standardCategories[14].copyWith(name: clean.isEmpty ? 'Baby Care' : clean);
    }
    if (lower.contains('pet') || lower.contains('dog') || lower.contains('cat')) {
      return standardCategories[15].copyWith(name: clean.isEmpty ? 'Pet Supplies' : clean);
    }
    if (lower.contains('clean') || lower.contains('house') || lower.contains('deterg') || lower.contains('wash')) {
      return standardCategories[16].copyWith(name: clean.isEmpty ? 'Cleaning' : clean);
    }
    if (lower.contains('book') || lower.contains('stationery') || lower.contains('office') || lower.contains('pen') || lower.contains('note')) {
      return standardCategories[17].copyWith(name: clean.isEmpty ? 'Stationery' : clean);
    }
    if (lower.contains('toy') || lower.contains('game')) {
      return standardCategories[18].copyWith(name: clean.isEmpty ? 'Toys & Games' : clean);
    }
    if (lower.contains('organic') || lower.contains('gourmet') || lower.contains('honey') || lower.contains('dry fruit') || lower.contains('nut')) {
      return standardCategories[19].copyWith(name: clean.isEmpty ? 'Organic & Gourmet' : clean);
    }

    // Default fallback: Realistic general grocery basket photography
    return CategoryItem(
      id: lower.replaceAll(RegExp(r'\s+'), '_'),
      name: clean.isEmpty ? 'Store' : clean,
      imageUrl: imgAll,
      subtitle: 'Market Selection',
    );
  }

  /// Builds the rich list for the Home page: "All" first, then dynamic active shop categories + popular quick-commerce items
  static List<CategoryItem> getHomeCategories(List<String> dynamicCategories) {
    final list = <CategoryItem>[];
    final seen = <String>{};

    // 1. All
    list.add(standardCategories[0]);
    seen.add('all');

    // 2. Active shop categories from backend
    for (final raw in dynamicCategories) {
      if (raw.trim().isEmpty) continue;
      final item = find(raw);
      if (!seen.contains(item.name.toLowerCase())) {
        list.add(item);
        seen.add(item.name.toLowerCase());
      }
    }

    // 3. Complement with top Blinkit/Zepto quick commerce categories if list is small
    const topPicks = [
      'Fruits',
      'Vegetables',
      'Dairy & Eggs',
      'Bakery',
      'Grocery',
      'Pharmacy',
      'Snacks & Munchies',
      'Beverages',
      'Electronics',
      'Fashion',
    ];

    for (final name in topPicks) {
      final item = find(name);
      if (!seen.contains(item.name.toLowerCase())) {
        list.add(item);
        seen.add(item.name.toLowerCase());
      }
    }

    return list;
  }

  /// Full catalog for the All Categories page
  static List<CategoryItem> getAllCategories(List<String> dynamicCategories) {
    final list = <CategoryItem>[];
    final seen = <String>{};

    // First add active categories from backend
    for (final raw in dynamicCategories) {
      if (raw.trim().isEmpty || raw.trim().toLowerCase() == 'all') continue;
      final item = find(raw);
      if (!seen.contains(item.name.toLowerCase())) {
        list.add(item);
        seen.add(item.name.toLowerCase());
      }
    }

    // Add all standard categories
    for (final item in standardCategories) {
      if (item.id == 'all') continue; // Don't show "All" inside the categories grid
      if (!seen.contains(item.name.toLowerCase())) {
        list.add(item);
        seen.add(item.name.toLowerCase());
      }
    }

    return list;
  }
}
