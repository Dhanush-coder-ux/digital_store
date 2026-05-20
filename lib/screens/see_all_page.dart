import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';

class SeeAllPage extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isGrid;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const SeeAllPage({
    super.key,
    required this.title,
    required this.items,
    this.isGrid = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(AppTheme.xl),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
        ),
        centerTitle: true,
      ),
      body: isGrid ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: padding,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: 50 * index),
          child: Padding(
            padding: EdgeInsets.only(bottom: isGrid ? 0 : AppTheme.lg),
            child: items[index],
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: padding,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppTheme.lg,
        mainAxisSpacing: AppTheme.lg,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: 50 * index),
          child: items[index],
        );
      },
    );
  }
}
