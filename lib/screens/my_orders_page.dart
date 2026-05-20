import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            'My Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                AppTheme.xl, 0, AppTheme.xl, AppTheme.md,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textTertiary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSmall,
                ),
                labelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Active'),
                  Tab(text: 'Done'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(context),
            _buildOrderList(context, filter: 'ONGOING'),
            _buildOrderList(context, filter: 'DELIVERED'),
            _buildOrderList(context, filter: 'CANCELLED'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, {String? filter}) {
    List<Map<String, dynamic>> orders = [
      {
        "id": "ORD-9921",
        "date": "14 Oct 2023",
        "status": "ONGOING",
        "images": [
          "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=100",
          "https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=100",
        ],
        "moreItems": "+1",
        "title": "Premium Wireless ANC Headphones",
        "total": "342.00",
        "actionText": "Track Order",
        "isPrimary": true,
      },
      {
        "id": "ORD-7721",
        "date": "08 Oct 2023",
        "status": "DELIVERED",
        "images": [
          "https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=100",
        ],
        "title": "Nike Air Zoom Pegasus 38",
        "subtitle": "Crimson Red • Size 42",
        "total": "120.50",
        "actionText": "Buy Again",
        "isPrimary": false,
      },
      {
        "id": "ORD-6540",
        "date": "22 Sep 2023",
        "status": "CANCELLED",
        "images": [
          "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=100",
        ],
        "title": "MacBook Pro M2 - 512GB Space Grey",
        "total": "1,299.00",
        "isRefunded": true,
        "actionText": "View Receipt",
        "isText": true,
      },
    ];

    if (filter != null) {
      orders = orders.where((o) => o['status'] == filter).toList();
    }

    if (orders.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.xl),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) => FadeInUp(
        delay: Duration(milliseconds: 80 * index),
        child: _buildOrderCard(context, orders[index]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shoppingBag,
                size: 36,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'No orders here',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.xs),
            Text(
              'Your orders in this category will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final bool isDelivered = order['status'] == 'DELIVERED';
    final bool isCancelled = order['status'] == 'CANCELLED';
    final bool isOngoing = order['status'] == 'ONGOING';

    Color statusColor;
    Color statusBg;
    String statusText;

    if (isDelivered) {
      statusColor = AppTheme.successGreen;
      statusBg = AppTheme.successGreen.withOpacity(0.1);
      statusText = '✓  Delivered';
    } else if (isCancelled) {
      statusColor = AppTheme.textTertiary;
      statusBg = AppTheme.bgSecondary;
      statusText = 'Cancelled';
    } else {
      statusColor = AppTheme.infoBlue;
      statusBg = AppTheme.infoBlue.withOpacity(0.1);
      statusText = '● In Progress';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.lg),
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order["id"]}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Placed on ${order["date"]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sm,
                  vertical: AppTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          // Images + title
          Row(
            children: [
              SizedBox(
                width: (order['images'] as List).length > 1 ? 80 : 56,
                height: 56,
                child: Stack(
                  children: List.generate(
                    (order['images'] as List).length,
                    (i) => Positioned(
                      left: i * 22.0,
                      child: _buildThumbnail(
                        (order['images'] as List)[i],
                        isCancelled,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['title'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isCancelled
                            ? AppTheme.textTertiary
                            : AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order['subtitle'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        order['subtitle'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          // Divider
          Divider(color: AppTheme.veryLightGray, height: 1),
          const SizedBox(height: AppTheme.md),
          // Total + action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['isRefunded'] == true ? 'REFUNDED' : 'TOTAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${order["total"]}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isCancelled
                          ? AppTheme.textTertiary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              _buildActionButton(context, order),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url, bool isCancelled) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.white, width: 2),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          colorFilter: isCancelled
              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
              : null,
        ),
        boxShadow: AppTheme.shadowSmall,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> order) {
    if (order['isText'] == true) {
      return TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(60, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          order['actionText'],
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    final isPrimary = order['isPrimary'] == true;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg,
          vertical: AppTheme.sm,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryBlue : AppTheme.veryLightGray,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          order['actionText'],
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isPrimary ? AppTheme.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
