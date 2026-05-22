import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';

import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class LiveTrackingPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const LiveTrackingPage({super.key, required this.order});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> with TickerProviderStateMixin {
  late AnimationController _riderController;
  late Animation<double> _riderAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Simulated route points
  final List<Offset> _routePoints = [
    const Offset(0.2, 0.8), // Start (Restaurant)
    const Offset(0.3, 0.7),
    const Offset(0.3, 0.5),
    const Offset(0.5, 0.5),
    const Offset(0.6, 0.3),
    const Offset(0.8, 0.2), // End (User Home)
  ];
  
  int _currentStage = 2; // 0: Confirmed, 1: Preparing, 2: Picked Up, 3: On The Way, 4: Delivered
  double _etaMinutes = 15;
  
  // Interactive Viewer controller for auto-follow
  final TransformationController _transformationController = TransformationController();

  final List<Map<String, dynamic>> _stages = [
    {'title': 'Order Confirmed', 'icon': LucideIcons.checkCircle},
    {'title': 'Preparing your food', 'icon': LucideIcons.chefHat},
    {'title': 'Picked up by rider', 'icon': LucideIcons.packageCheck},
    {'title': 'On the way', 'icon': LucideIcons.navigation},
    {'title': 'Delivered', 'icon': LucideIcons.home},
  ];

  @override
  void initState() {
    super.initState();
    
    // Rider movement animation (simulate 30s trip for demo)
    _riderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    
    _riderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _riderController, curve: Curves.easeInOut),
    );
    
    // Pulsing effect for rider marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _riderController.addListener(() {
      setState(() {
        // Update ETA dynamically
        _etaMinutes = 15 * (1.0 - _riderAnimation.value);
        
        // Update stages based on progress
        if (_riderAnimation.value > 0.95) {
          _currentStage = 4;
        } else if (_riderAnimation.value > 0.3) {
          _currentStage = 3;
        }
      });
      _updateCameraPosition();
    });
    
    // Start trip
    _riderController.forward();
    
    // Initial camera position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCameraPosition();
    });
  }
  
  void _updateCameraPosition() {
    if (!mounted) return;
    
    final size = MediaQuery.of(context).size;
    final currentPos = _getCurrentRiderPosition(size);
    
    // Center camera on rider
    final matrix = Matrix4.identity()
      ..translate(
        -currentPos.dx + size.width / 2,
        -currentPos.dy + size.height * 0.3, // Offset slightly up to account for bottom sheet
      );
      
    _transformationController.value = matrix;
  }

  Offset _getCurrentRiderPosition(Size size) {
    if (_routePoints.isEmpty) return Offset.zero;
    if (_riderAnimation.value >= 1.0) return _getScaledPoint(_routePoints.last, size);
    if (_riderAnimation.value <= 0.0) return _getScaledPoint(_routePoints.first, size);
    
    // Calculate total path length
    double totalLength = 0;
    List<double> segmentLengths = [];
    for (int i = 0; i < _routePoints.length - 1; i++) {
      double len = (_routePoints[i + 1] - _routePoints[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }
    
    double targetDistance = totalLength * _riderAnimation.value;
    double currentDistance = 0;
    
    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDistance + segmentLengths[i] >= targetDistance) {
        // We are on this segment
        double t = (targetDistance - currentDistance) / segmentLengths[i];
        Offset p1 = _getScaledPoint(_routePoints[i], size);
        Offset p2 = _getScaledPoint(_routePoints[i + 1], size);
        return Offset.lerp(p1, p2, t)!;
      }
      currentDistance += segmentLengths[i];
    }
    
    return _getScaledPoint(_routePoints.last, size);
  }
  
  Offset _getScaledPoint(Offset normalized, Size size) {
    // Map bounds are slightly larger than screen
    return Offset(normalized.dx * size.width * 2, normalized.dy * size.height * 2);
  }

  @override
  void dispose() {
    _riderController.dispose();
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final riderPos = _getCurrentRiderPosition(size);
    
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      body: Stack(
        children: [
          // 1. Simulated Map Layer
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 2.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: SizedBox(
                width: size.width * 2,
                height: size.height * 2,
                child: CustomPaint(
                  painter: _MapPainter(
                    routePoints: _routePoints.map((p) => _getScaledPoint(p, size)).toList(),
                    progress: _riderAnimation.value,
                  ),
                  child: Stack(
                    children: [
                      // Restaurant Marker
                      Positioned(
                        left: _getScaledPoint(_routePoints.first, size).dx - 20,
                        top: _getScaledPoint(_routePoints.first, size).dy - 40,
                        child: _buildLocationPin(LucideIcons.store, AppTheme.infoBlue),
                      ),
                      
                      // Home Marker
                      Positioned(
                        left: _getScaledPoint(_routePoints.last, size).dx - 20,
                        top: _getScaledPoint(_routePoints.last, size).dy - 40,
                        child: _buildLocationPin(LucideIcons.home, AppTheme.successGreen),
                      ),
                      
                      // Rider Marker (Animated)
                      Positioned(
                        left: riderPos.dx - 24,
                        top: riderPos.dy - 24,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.white, width: 3),
                                  boxShadow: AppTheme.shadowSmall,
                                ),
                                child: const Icon(LucideIcons.bike, size: 12, color: AppTheme.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 2. Top App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: AppTheme.xl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppTheme.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          
          // 3. Bottom Sheet (Glassmorphism)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationPin(IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.white, width: 3),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Icon(icon, color: AppTheme.white, size: 20),
        ),
        Container(
          width: 4,
          height: 8,
          color: color,
        ),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.darkGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXxl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppTheme.xl, AppTheme.md, AppTheme.xl, AppTheme.xxl),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(color: AppTheme.white.withOpacity(0.5), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkGray.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              
              // ETA & Status header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stages[_currentStage]['title'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStage == 4 
                            ? 'Your order has arrived!' 
                            : 'Arriving in ${_etaMinutes.ceil()} mins',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.sm),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _stages[_currentStage]['icon'],
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.xl),
              const Divider(color: AppTheme.veryLightGray),
              const SizedBox(height: AppTheme.lg),
              
              // Rider Info
              if (_currentStage > 1 && _currentStage < 4)
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=200'),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: AppTheme.veryLightGray, width: 2),
                        ),
                      ),
                      const SizedBox(width: AppTheme.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alex Johnson',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.star, color: AppTheme.warningOrange, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9 • Honda Activa (TN 38 AZ 1234)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.phone, color: AppTheme.white, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                
              if (_currentStage > 1 && _currentStage < 4) ...[
                const SizedBox(height: AppTheme.lg),
                const Divider(color: AppTheme.veryLightGray),
              ],
              
              const SizedBox(height: AppTheme.lg),
              
              // Timeline
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final isCompleted = index <= _currentStage;
                    final isCurrent = index == _currentStage;
                    
                    return SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: index == 0 ? Colors.transparent : (isCompleted ? AppTheme.primaryBlue : AppTheme.veryLightGray),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted ? AppTheme.primaryBlue : AppTheme.white,
                                  border: Border.all(
                                    color: isCompleted ? AppTheme.primaryBlue : AppTheme.veryLightGray,
                                    width: 2,
                                  ),
                                  boxShadow: isCurrent ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ] : null,
                                ),
                                child: isCompleted 
                                    ? const Icon(LucideIcons.check, color: AppTheme.white, size: 12)
                                    : null,
                              ),
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: index == _stages.length - 1 ? Colors.transparent : (index < _currentStage ? AppTheme.primaryBlue : AppTheme.veryLightGray),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              _stages[index]['title'],
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                color: isCompleted ? AppTheme.textPrimary : AppTheme.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to draw a beautiful simulated map grid and route polyline
class _MapPainter extends CustomPainter {
  final List<Offset> routePoints;
  final double progress;

  _MapPainter({required this.routePoints, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Grid (Simulated Roads)
    final gridPaint = Paint()
      ..color = AppTheme.veryLightGray.withOpacity(0.5)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw some decorative map roads
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(0, size.height * (i / 10)),
        Offset(size.width, size.height * (i / 10)),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.width * (i / 10), 0),
        Offset(size.width * (i / 10), size.height),
        gridPaint,
      );
    }
    
    // Draw some parks/buildings
    final parkPaint = Paint()
      ..color = AppTheme.successGreen.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.1, size.height * 0.1, size.width * 0.3, size.height * 0.3, const Radius.circular(20)), parkPaint);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.6, size.height * 0.6, size.width * 0.9, size.height * 0.8, const Radius.circular(20)), parkPaint);

    // 2. Draw Base Route (Inactive)
    final baseRoutePaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (routePoints.isNotEmpty) {
      path.moveTo(routePoints.first.dx, routePoints.first.dy);
      for (int i = 1; i < routePoints.length; i++) {
        path.lineTo(routePoints[i].dx, routePoints[i].dy);
      }
    }
    canvas.drawPath(path, baseRoutePaint);

    // 3. Draw Active Route (Completed portion)
    if (progress > 0) {
      final activeRoutePaint = Paint()
        ..color = AppTheme.primaryBlue
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      // Extract the sub-path based on progress
      PathMetrics pathMetrics = path.computeMetrics();
      if (pathMetrics.isNotEmpty) {
        PathMetric metric = pathMetrics.first;
        Path activePath = metric.extractPath(0, metric.length * progress);
        canvas.drawPath(activePath, activeRoutePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
