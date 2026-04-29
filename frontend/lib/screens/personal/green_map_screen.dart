import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class GreenMapScreen extends StatefulWidget {
  const GreenMapScreen({super.key});

  @override
  State<GreenMapScreen> createState() => _GreenMapScreenState();
}

class _GreenMapScreenState extends State<GreenMapScreen> with TickerProviderStateMixin {
  int? _selectedZone;
  late AnimationController _pulseController;
  late AnimationController _infoPanelController;
  late Animation<double> _pulseAnim;
  late Animation<double> _infoPanelAnim;

  static const _zones = [
    _ZoneData('Panaji', 'Low Carbon', AppTheme.emerald, 2.1, Offset(0.42, 0.28)),
    _ZoneData('Mapusa', 'Medium', Color(0xFFEAB308), 4.8, Offset(0.35, 0.18)),
    _ZoneData('Margao', 'Medium', Color(0xFFEAB308), 5.2, Offset(0.48, 0.68)),
    _ZoneData('Vasco', 'High', AppTheme.warning, 7.1, Offset(0.25, 0.55)),
    _ZoneData('Calangute', 'Low Carbon', AppTheme.emerald, 1.9, Offset(0.22, 0.22)),
    _ZoneData('Ponda', 'Low Carbon', AppTheme.emerald, 2.6, Offset(0.62, 0.45)),
    _ZoneData('Colva', 'Low Carbon', AppTheme.emerald, 1.5, Offset(0.38, 0.78)),
    _ZoneData('Canacona', 'Low Carbon', AppTheme.emerald, 1.2, Offset(0.45, 0.92)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _infoPanelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _infoPanelAnim = CurvedAnimation(parent: _infoPanelController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _infoPanelController.dispose();
    super.dispose();
  }

  void _onTap(int? hit) {
    setState(() => _selectedZone = hit);
    if (hit != null) {
      _infoPanelController.forward(from: 0);
    } else {
      _infoPanelController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Green Map', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Carbon intensity by city zone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapDown: (details) {
                              final x = details.localPosition.dx / constraints.maxWidth;
                              final y = details.localPosition.dy / constraints.maxHeight;
                              int? hit;
                              for (int i = 0; i < _zones.length; i++) {
                                final dx = _zones[i].position.dx - x;
                                final dy = _zones[i].position.dy - y;
                                // Use pixel-based distance for better tap accuracy
                                final pxDx = dx * constraints.maxWidth;
                                final pxDy = dy * constraints.maxHeight;
                                if (pxDx * pxDx + pxDy * pxDy < 900) { // 30px radius
                                  hit = i;
                                  break;
                                }
                              }
                              _onTap(hit);
                            },
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) => CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: _GoaMapPainter(_zones, _selectedZone, _pulseAnim.value),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _infoPanelAnim,
                builder: (context, child) {
                  if (_selectedZone == null && _infoPanelController.isDismissed) {
                    return _buildLegend();
                  }
                  if (_selectedZone != null || !_infoPanelController.isDismissed) {
                    final zone = _selectedZone != null ? _zones[_selectedZone!] : _zones[0];
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _infoPanelAnim.value)),
                      child: Opacity(
                        opacity: _infoPanelAnim.value,
                        child: _buildInfoPanel(zone),
                      ),
                    );
                  }
                  return _buildLegend();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(AppTheme.emerald, 'Low Carbon'),
          const SizedBox(width: 16),
          _LegendDot(const Color(0xFFEAB308), 'Medium'),
          const SizedBox(width: 16),
          _LegendDot(AppTheme.warning, 'High'),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(_ZoneData zone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GlassCard(
        borderColor: zone.color.withValues(alpha: 0.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: zone.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_city, color: zone.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: zone.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(zone.label, style: TextStyle(color: zone.color, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${zone.co2PerCap} kg', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const Text('CO₂/person/day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _onTap(null),
              child: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ZoneData {
  final String name;
  final String label;
  final Color color;
  final double co2PerCap;
  final Offset position;

  const _ZoneData(this.name, this.label, this.color, this.co2PerCap, this.position);
}

class _GoaMapPainter extends CustomPainter {
  final List<_ZoneData> zones;
  final int? selected;
  final double pulse;

  _GoaMapPainter(this.zones, this.selected, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.surface,
    );

    // Goa outline path
    final pts = [
      Offset(0.18 * size.width, 0.05 * size.height),
      Offset(0.55 * size.width, 0.02 * size.height),
      Offset(0.82 * size.width, 0.12 * size.height),
      Offset(0.88 * size.width, 0.35 * size.height),
      Offset(0.75 * size.width, 0.62 * size.height),
      Offset(0.65 * size.width, 0.85 * size.height),
      Offset(0.48 * size.width, 0.98 * size.height),
      Offset(0.28 * size.width, 0.88 * size.height),
      Offset(0.14 * size.width, 0.65 * size.height),
      Offset(0.10 * size.width, 0.38 * size.height),
    ];

    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF0D1F0D));
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Grid lines inside Goa for visual texture
    final gridPaint = Paint()
      ..color = AppTheme.emerald.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double x = 0.15; x < 0.9; x += 0.1) {
      canvas.drawLine(Offset(x * size.width, 0), Offset(x * size.width, size.height), gridPaint);
    }
    for (double y = 0.05; y < 0.98; y += 0.1) {
      canvas.drawLine(Offset(0, y * size.height), Offset(size.width, y * size.height), gridPaint);
    }

    // Draw zones
    for (int i = 0; i < zones.length; i++) {
      final z = zones[i];
      final cx = z.position.dx * size.width;
      final cy = z.position.dy * size.height;
      final isSelected = i == selected;

      if (isSelected) {
        // Pulsing outer ring
        final pulseRadius = 28.0 + pulse * 10;
        canvas.drawCircle(
          Offset(cx, cy),
          pulseRadius,
          Paint()..color = z.color.withValues(alpha: 0.15 * pulse),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          22,
          Paint()
            ..color = z.color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Halo
      canvas.drawCircle(
        Offset(cx, cy),
        isSelected ? 18 : 14,
        Paint()..color = z.color.withValues(alpha: isSelected ? 0.4 : 0.2),
      );

      // Core dot
      canvas.drawCircle(Offset(cx, cy), isSelected ? 7 : 5, Paint()..color = z.color);

      // White center
      canvas.drawCircle(Offset(cx, cy), isSelected ? 3 : 2, Paint()..color = Colors.white);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: z.name,
          style: TextStyle(
            color: isSelected ? z.color : z.color.withValues(alpha: 0.8),
            fontSize: isSelected ? 11 : 9,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Label background for readability
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - tp.width / 2 - 4, cy + 12, tp.width + 8, tp.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelRect, Paint()..color = AppTheme.bg1.withValues(alpha: 0.7));
      tp.paint(canvas, Offset(cx - tp.width / 2, cy + 14));
    }

    // Compass rose in corner
    _drawCompass(canvas, Offset(size.width - 28, 28));
  }

  void _drawCompass(Canvas canvas, Offset center) {
    final cx = center.dx;
    final cy = center.dy;
    final paint = Paint()
      ..color = AppTheme.emerald.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 14, paint);
    // N arrow
    canvas.drawLine(center, Offset(cx, cy - 10), Paint()..color = AppTheme.emerald..strokeWidth = 2);
    canvas.drawLine(center, Offset(cx, cy + 8), Paint()..color = AppTheme.textSecondary..strokeWidth = 1.5);
    canvas.drawLine(center, Offset(cx - 8, cy), Paint()..color = AppTheme.textSecondary..strokeWidth = 1.5);
    canvas.drawLine(center, Offset(cx + 8, cy), Paint()..color = AppTheme.textSecondary..strokeWidth = 1.5);

    // N label
    final tp = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(color: AppTheme.emerald, fontSize: 8, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - 22));
  }

  @override
  bool shouldRepaint(_GoaMapPainter old) => old.selected != selected || old.pulse != pulse;
}
