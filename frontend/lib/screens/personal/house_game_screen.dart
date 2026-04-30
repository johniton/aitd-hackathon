import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../models/house_item_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

final List<HouseItemModel> shopItems = [
  const HouseItemModel(
    id: 'h1',
    name: 'Solar Roof',
    icon: '☀️',
    cost: 200,
    description: '-30% energy emissions',
  ),
  const HouseItemModel(
    id: 'h2',
    name: 'Rain Garden',
    icon: '🌿',
    cost: 150,
    description: 'Absorbs 5kg CO₂/month',
  ),
  const HouseItemModel(
    id: 'h3',
    name: 'EV Charger',
    icon: '⚡',
    cost: 300,
    description: 'Unlock EV transport logging',
  ),
  const HouseItemModel(
    id: 'h4',
    name: 'Rainwater Tank',
    icon: '💧',
    cost: 180,
    description: 'Save 500L water/month',
  ),
  const HouseItemModel(
    id: 'h5',
    name: 'Compost Bin',
    icon: '♻️',
    cost: 80,
    description: 'Double waste points',
    purchased: true,
  ),
  const HouseItemModel(
    id: 'h6',
    name: 'Terrace Farm',
    icon: '🥦',
    cost: 220,
    description: 'Grow your own food',
  ),
];

class HouseGameScreen extends StatefulWidget {
  const HouseGameScreen({super.key});

  @override
  State<HouseGameScreen> createState() => _HouseGameScreenState();
}

class _HouseGameScreenState extends State<HouseGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<HouseItemModel> _items = [];
  int _coins = 0;
  bool _isLoading = true;
  bool _isSharing = false;
  String _error = '';
  final GlobalKey _houseShareKey = GlobalKey();
  Timer? _houseSyncTimer;

  late AnimationController _celebrationController;
  late AnimationController _houseEntranceController;
  late Animation<double> _houseEntrance;
  String? _lastPurchasedIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _houseSyncTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshHouseDataSilently();
    });

    _houseEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _houseEntrance = CurvedAnimation(
      parent: _houseEntranceController,
      curve: Curves.easeOutBack,
    );
    _houseEntranceController.forward();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHouseDataSilently();
    }
  }

  Future<void> _loadData() async {
    try {
      final houseData = await ApiService.getHouse();
      final purchasedList = (houseData['items'] as List)
          .map((item) => HouseItemModel.fromJson(item))
          .toList();

      setState(() {
        _coins = (houseData['coins'] as num).toInt();
        _items = shopItems.map((staticItem) {
          final isPurchased = purchasedList.any((p) => p.id == staticItem.id);
          return staticItem.copyWith(purchased: isPurchased);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _houseSyncTimer?.cancel();
    _celebrationController.dispose();
    _houseEntranceController.dispose();
    super.dispose();
  }

  Future<void> _refreshHouseDataSilently() async {
    try {
      final houseData = await ApiService.getHouse();
      if (!mounted) return;
      final purchasedList = (houseData['items'] as List)
          .map((item) => HouseItemModel.fromJson(item))
          .toList();
      setState(() {
        _coins = (houseData['coins'] as num).toInt();
        _items = shopItems.map((staticItem) {
          final isPurchased = purchasedList.any((p) => p.id == staticItem.id);
          return staticItem.copyWith(purchased: isPurchased);
        }).toList();
      });
    } catch (_) {
      // Keep current UI if silent sync fails.
    }
  }

  Future<void> _buy(int index) async {
    final item = _items[index];
    if (item.purchased || _coins < item.cost) return;

    try {
      await ApiService.buyHouseItem(item.id);
      if (!mounted) return;
      setState(() {
        _items[index] = item.copyWith(purchased: true);
        _coins -= item.cost;
        _lastPurchasedIcon = item.icon;
      });
      _celebrationController.forward(from: 0);
      _refreshHouseDataSilently();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.emerald,
          content: Text('${item.icon} ${item.name} added to your eco home!'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.accentRed,
          content: Text('Purchase failed: $e'),
        ),
      );
    }
  }

  bool _has(String id) => _items.any((i) => i.id == id && i.purchased);
  int get _purchasedCount => _items.where((i) => i.purchased).length;
  double get _completion =>
      _items.isEmpty ? 0 : _purchasedCount / _items.length;

  String get _stageLabel {
    final count = _purchasedCount;
    if (count <= 1) return 'Foundation';
    if (count <= 3) return 'Framing';
    if (count <= 5) return 'Eco Systems';
    return 'Net-Zero Home';
  }

  HouseItemModel? get _nextUpgrade {
    for (final item in _items) {
      if (!item.purchased) return item;
    }
    return null;
  }

  Future<void> _shareHouse() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          _houseShareKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/green_house_progress.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'I just built my $_stageLabel eco-home ($_purchasedCount/${_items.length} upgrades)! 🌿🏡',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg1,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emerald)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bg1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: AppTheme.accentRed)),
              TextButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Green House',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Upgrade your eco home',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                color: AppTheme.lime,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RepaintBoundary(
                    key: _houseShareKey,
                    child: AnimatedBuilder(
                      animation: _houseEntrance,
                      builder: (context, child) => Transform.scale(
                        scale: _houseEntrance.value,
                        child: child,
                      ),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: AnimatedBuilder(
                              animation: _celebrationController,
                              builder: (context, child) => CustomPaint(
                                painter: _HousePainter(
                                  hasSolar: _has('h1'),
                                  hasGarden: _has('h2'),
                                  hasEV: _has('h3'),
                                  hasWater: _has('h4'),
                                  hasBike: _items.any(
                                    (i) => i.id == 'h5' && i.purchased,
                                  ),
                                  celebrationProgress:
                                      _celebrationController.value,
                                  lastIcon: _lastPurchasedIcon,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Build Stage: $_stageLabel',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_completion * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppTheme.lime,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _completion,
                            minHeight: 8,
                            backgroundColor: AppTheme.surface,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _nextUpgrade == null
                              ? 'All upgrades complete. Your eco-home is showcase ready.'
                              : 'Next objective: Build ${_nextUpgrade!.name} (${_nextUpgrade!.cost} coins).',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Shop',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GradientButton(
                        label: _isSharing ? 'Sharing...' : '📤 Share',
                        onPressed: () {
                          if (_isSharing) return;
                          _shareHouse();
                        },
                        width: null,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ShopCard(
                      item: _items[i],
                      canAfford: _coins >= _items[i].cost,
                      onBuy: () => _buy(i),
                    ),
                    childCount: _items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HousePainter extends CustomPainter {
  final bool hasSolar;
  final bool hasGarden;
  final bool hasEV;
  final bool hasWater;
  final bool hasBike;
  final double celebrationProgress;
  final String? lastIcon;

  _HousePainter({
    required this.hasSolar,
    required this.hasGarden,
    required this.hasEV,
    required this.hasWater,
    required this.hasBike,
    required this.celebrationProgress,
    this.lastIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky background
    final skyGradient = LinearGradient(
      colors: [const Color(0xFF0D1F0D), const Color(0xFF0A2A1A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = skyGradient);

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final rng = Random(42);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.45),
        rng.nextDouble() * 1.5,
        starPaint,
      );
    }

    // Ground
    final groundY = h * 0.72;
    final groundGradient = LinearGradient(
      colors: [
        hasGarden ? const Color(0xFF14532D) : const Color(0xFF1A2E1A),
        const Color(0xFF0D1A0D),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, groundY, w, h - groundY));
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..shader = groundGradient,
    );

    // Garden grass tufts
    if (hasGarden) {
      final grassPaint = Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (double gx = w * 0.05; gx < w * 0.95; gx += 14) {
        canvas.drawLine(
          Offset(gx, groundY),
          Offset(gx - 3, groundY - 8),
          grassPaint,
        );
        canvas.drawLine(
          Offset(gx + 4, groundY),
          Offset(gx + 4, groundY - 10),
          grassPaint,
        );
        canvas.drawLine(
          Offset(gx + 8, groundY),
          Offset(gx + 11, groundY - 7),
          grassPaint,
        );
      }
      // Flower
      _drawFlower(canvas, Offset(w * 0.12, groundY - 2));
      _drawFlower(canvas, Offset(w * 0.88, groundY - 2));
    }

    // House body
    final houseLeft = w * 0.25;
    final houseRight = w * 0.75;
    final houseTop = h * 0.38;
    final houseBottom = groundY;
    final houseWidth = houseRight - houseLeft;

    final wallGradient =
        LinearGradient(
          colors: [const Color(0xFF1A3A2A), const Color(0xFF122A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          Rect.fromLTWH(
            houseLeft,
            houseTop,
            houseWidth,
            houseBottom - houseTop,
          ),
        );

    final wallPaint = Paint()..shader = wallGradient;
    canvas.drawRect(
      Rect.fromLTWH(houseLeft, houseTop, houseWidth, houseBottom - houseTop),
      wallPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(houseLeft, houseTop, houseWidth, houseBottom - houseTop),
      Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Roof
    final roofPath = Path();
    roofPath.moveTo(houseLeft - w * 0.03, houseTop);
    roofPath.lineTo(w / 2, h * 0.12);
    roofPath.lineTo(houseRight + w * 0.03, houseTop);
    roofPath.close();

    final roofGradient =
        LinearGradient(
          colors: [const Color(0xFF0F3D20), const Color(0xFF0A2A14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
          Rect.fromLTWH(houseLeft, h * 0.12, houseWidth, houseTop - h * 0.12),
        );

    canvas.drawPath(roofPath, Paint()..shader = roofGradient);
    canvas.drawPath(
      roofPath,
      Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Solar panels on roof
    if (hasSolar) {
      _drawSolarPanels(canvas, size, houseLeft, h * 0.12, houseTop);
    }

    // Windows
    _drawWindow(
      canvas,
      Offset(
        houseLeft + houseWidth * 0.2,
        houseTop + (houseBottom - houseTop) * 0.2,
      ),
      22,
      18,
    );
    _drawWindow(
      canvas,
      Offset(
        houseLeft + houseWidth * 0.7,
        houseTop + (houseBottom - houseTop) * 0.2,
      ),
      22,
      18,
    );

    // Door
    final doorLeft = w / 2 - 15;
    final doorTop = houseBottom - 55;
    final doorPaint = Paint()..color = const Color(0xFF0D2B1A);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(doorLeft, doorTop, 30, 55),
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(15),
      ),
      doorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(doorLeft, doorTop, 30, 55),
        topLeft: const Radius.circular(15),
        topRight: const Radius.circular(15),
      ),
      Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Doorknob
    canvas.drawCircle(
      Offset(doorLeft + 24, doorTop + 30),
      3,
      Paint()..color = AppTheme.lime,
    );

    // EV Charger on right side
    if (hasEV) {
      _drawEVCharger(canvas, Offset(houseRight + 8, houseBottom - 40), groundY);
    }

    // Water tank on roof left
    if (hasWater) {
      _drawWaterTank(canvas, Offset(houseLeft + 14, houseTop - 20));
    }

    // Bike near house
    if (hasBike) {
      _drawBike(canvas, Offset(houseLeft - 35, groundY - 5));
    }

    // Tree on right (always present, greener with garden)
    _drawTree(canvas, Offset(w * 0.88, groundY), hasGarden);

    // Celebration particles
    if (celebrationProgress > 0 && celebrationProgress < 1) {
      _drawCelebration(canvas, size, celebrationProgress);
    }

    // Level badge
    final purchasedCount = [
      hasSolar,
      hasGarden,
      hasEV,
      hasWater,
      hasBike,
    ].where((b) => b).length;
    _drawLevelBadge(canvas, Offset(w - 20, 16), purchasedCount);
  }

  void _drawSolarPanels(
    Canvas canvas,
    Size size,
    double houseLeft,
    double roofTop,
    double houseTop,
  ) {
    final panelPaint = Paint()
      ..color = const Color(0xFF1E40AF).withValues(alpha: 0.9);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    final glowPaint = Paint()..color = AppTheme.lime.withValues(alpha: 0.8);

    // Left side of roof
    final panels = [
      Rect.fromLTWH(
        size.width * 0.34,
        roofTop + (houseTop - roofTop) * 0.45,
        24,
        14,
      ),
      Rect.fromLTWH(
        size.width * 0.34 + 26,
        roofTop + (houseTop - roofTop) * 0.4,
        24,
        14,
      ),
    ];
    for (final r in panels) {
      canvas.drawRect(r, panelPaint);
      canvas.drawRect(
        r,
        Paint()
          ..color = Colors.blue.shade300.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
      // Grid lines
      canvas.drawLine(
        Offset(r.left + r.width / 2, r.top),
        Offset(r.left + r.width / 2, r.bottom),
        linePaint,
      );
      canvas.drawLine(
        Offset(r.left, r.top + r.height / 2),
        Offset(r.right, r.top + r.height / 2),
        linePaint,
      );
    }
    // Glow dot
    canvas.drawCircle(
      Offset(panels[0].right + 1, panels[0].top - 2),
      3,
      glowPaint,
    );
  }

  void _drawWindow(Canvas canvas, Offset topLeft, double w, double h) {
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF84CC16).withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = AppTheme.lime.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Cross
    final cross = Paint()
      ..color = AppTheme.lime.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(topLeft.dx + w / 2, topLeft.dy),
      Offset(topLeft.dx + w / 2, topLeft.dy + h),
      cross,
    );
    canvas.drawLine(
      Offset(topLeft.dx, topLeft.dy + h / 2),
      Offset(topLeft.dx + w, topLeft.dy + h / 2),
      cross,
    );
  }

  void _drawEVCharger(Canvas canvas, Offset pos, double groundY) {
    // Post
    canvas.drawRect(
      Rect.fromLTWH(pos.dx, pos.dy, 6, groundY - pos.dy),
      Paint()..color = const Color(0xFF374151),
    );
    // Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 8, pos.dy, 22, 28),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF1F2937),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 8, pos.dy, 22, 28),
        const Radius.circular(4),
      ),
      Paint()
        ..color = AppTheme.lime.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Lightning bolt
    final boltPath = Path();
    boltPath.moveTo(pos.dx + 3, pos.dy + 6);
    boltPath.lineTo(pos.dx - 1, pos.dy + 14);
    boltPath.lineTo(pos.dx + 2, pos.dy + 14);
    boltPath.lineTo(pos.dx - 1, pos.dy + 22);
    boltPath.lineTo(pos.dx + 5, pos.dy + 13);
    boltPath.lineTo(pos.dx + 2, pos.dy + 13);
    boltPath.close();
    canvas.drawPath(boltPath, Paint()..color = AppTheme.lime);
    // Cable
    final cablePath = Path();
    cablePath.moveTo(pos.dx - 8, pos.dy + 20);
    cablePath.quadraticBezierTo(
      pos.dx - 20,
      pos.dy + 35,
      pos.dx - 15,
      groundY - 3,
    );
    canvas.drawPath(
      cablePath,
      Paint()
        ..color = AppTheme.lime.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawWaterTank(Canvas canvas, Offset pos) {
    // Tank body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, 28, 22),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF1E3A5F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, 28, 22),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Colors.blue.shade300.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Water level
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + 2, pos.dy + 10, 24, 10),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.blue.shade400.withValues(alpha: 0.4),
    );
    // Pipe
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + 11, pos.dy + 22, 6, 8),
      Paint()..color = const Color(0xFF374151),
    );
    // Droplet
    final dropPath = Path();
    dropPath.moveTo(pos.dx + 14, pos.dy + 32);
    dropPath.quadraticBezierTo(
      pos.dx + 10,
      pos.dy + 38,
      pos.dx + 14,
      pos.dy + 40,
    );
    dropPath.quadraticBezierTo(
      pos.dx + 18,
      pos.dy + 38,
      pos.dx + 14,
      pos.dy + 32,
    );
    canvas.drawPath(
      dropPath,
      Paint()..color = Colors.blue.shade300.withValues(alpha: 0.8),
    );
  }

  void _drawBike(Canvas canvas, Offset pos) {
    final bikePaint = Paint()
      ..color = AppTheme.emerald
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Wheels
    canvas.drawCircle(Offset(pos.dx - 12, pos.dy - 8), 10, bikePaint);
    canvas.drawCircle(Offset(pos.dx + 12, pos.dy - 8), 10, bikePaint);
    // Frame
    canvas.drawLine(
      Offset(pos.dx - 12, pos.dy - 8),
      Offset(pos.dx, pos.dy - 20),
      bikePaint,
    );
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 20),
      Offset(pos.dx + 12, pos.dy - 8),
      bikePaint,
    );
    canvas.drawLine(
      Offset(pos.dx - 12, pos.dy - 8),
      Offset(pos.dx + 12, pos.dy - 8),
      bikePaint,
    );
    canvas.drawLine(
      Offset(pos.dx - 2, pos.dy - 20),
      Offset(pos.dx + 2, pos.dy - 20),
      bikePaint..strokeWidth = 1.5,
    );
    // Handlebar
    canvas.drawLine(
      Offset(pos.dx + 9, pos.dy - 20),
      Offset(pos.dx + 15, pos.dy - 20),
      bikePaint
        ..color = AppTheme.lime
        ..strokeWidth = 2,
    );
    // Seat
    canvas.drawLine(
      Offset(pos.dx - 5, pos.dy - 22),
      Offset(pos.dx + 2, pos.dy - 22),
      bikePaint
        ..color = AppTheme.lime
        ..strokeWidth = 2.5,
    );
  }

  void _drawTree(Canvas canvas, Offset base, bool lush) {
    final trunkPaint = Paint()..color = const Color(0xFF4A2C0A);
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 5, base.dy - 30, 10, 30),
      trunkPaint,
    );
    final leafColor = lush ? AppTheme.emerald : const Color(0xFF166534);
    final leafPaint = Paint()..color = leafColor.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(base.dx, base.dy - 40), 22, leafPaint);
    canvas.drawCircle(Offset(base.dx - 12, base.dy - 30), 14, leafPaint);
    canvas.drawCircle(Offset(base.dx + 12, base.dy - 30), 14, leafPaint);
    if (lush) {
      canvas.drawCircle(
        Offset(base.dx, base.dy - 52),
        12,
        Paint()..color = AppTheme.lime.withValues(alpha: 0.6),
      );
    }
  }

  void _drawFlower(Canvas canvas, Offset base) {
    final petalPaint = Paint()..color = AppTheme.lime.withValues(alpha: 0.8);
    final centerPaint = Paint()..color = AppTheme.accentAmber;
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi;
      canvas.drawCircle(
        Offset(base.dx + cos(angle) * 5, base.dy + sin(angle) * 5 - 8),
        4,
        petalPaint,
      );
    }
    canvas.drawCircle(Offset(base.dx, base.dy - 8), 4, centerPaint);
    canvas.drawLine(
      Offset(base.dx, base.dy - 4),
      Offset(base.dx, base.dy),
      Paint()
        ..color = const Color(0xFF166534)
        ..strokeWidth = 1.5,
    );
  }

  void _drawCelebration(Canvas canvas, Size size, double progress) {
    final rng = Random(12);
    final colors = [
      AppTheme.emerald,
      AppTheme.lime,
      AppTheme.accentAmber,
      AppTheme.cardBg,
    ];
    for (int i = 0; i < 18; i++) {
      final startX = size.width / 2;
      final startY = size.height * 0.4;
      final angle = (i / 18) * 2 * pi + rng.nextDouble();
      final dist = 60 + rng.nextDouble() * 40;
      final px = startX + cos(angle) * dist * progress;
      final py = startY + sin(angle) * dist * progress - 20 * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(px, py),
        3 + rng.nextDouble() * 3,
        Paint()..color = colors[i % colors.length].withValues(alpha: opacity),
      );
    }
  }

  void _drawLevelBadge(Canvas canvas, Offset pos, int count) {
    final stars = count;
    final color = stars >= 4
        ? AppTheme.lime
        : stars >= 2
        ? AppTheme.emerald
        : AppTheme.textSecondary;
    canvas.drawCircle(pos, 16, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'Lv$stars',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.hasSolar != hasSolar ||
      old.hasGarden != hasGarden ||
      old.hasEV != hasEV ||
      old.hasWater != hasWater ||
      old.hasBike != hasBike ||
      old.celebrationProgress != celebrationProgress;
}

class _ShopCard extends StatefulWidget {
  final HouseItemModel item;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.item,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.canAfford && !widget.item.purchased
          ? _tapController.forward()
          : null,
      onTapUp: (_) {
        _tapController.reverse();
        if (widget.canAfford && !widget.item.purchased) widget.onBuy();
      },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GlassCard(
          borderColor: widget.item.purchased
              ? AppTheme.emerald.withValues(alpha: 0.5)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.item.icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                widget.item.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 2,
              ),
              const Spacer(),
              if (widget.item.purchased)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: AppTheme.emerald, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Owned',
                        style: TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.canAfford
                        ? AppTheme.emerald.withValues(alpha: 0.2)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.canAfford
                          ? AppTheme.emerald
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.item.cost}',
                        style: TextStyle(
                          color: widget.canAfford
                              ? AppTheme.emerald
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
