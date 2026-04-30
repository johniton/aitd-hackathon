import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../data/static_data.dart';
import '../../models/business_model.dart';
import '../../services/tourism_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class BenchmarkScreen extends StatelessWidget {
  final BusinessSector sector;
  final TourismEngineController? tourismController;
  const BenchmarkScreen({
    super.key,
    required this.sector,
    this.tourismController,
  });

  BusinessModel get _biz => businessProfiles.firstWhere(
    (b) => b.sector == sector,
    orElse: () => businessProfiles.first,
  );

  @override
  Widget build(BuildContext context) {
    if (sector == BusinessSector.tourism && tourismController != null) {
      return AnimatedBuilder(
        animation: tourismController!,
        builder: (_, __) {
          final c = tourismController!;
          final peers = [
            ('North Goa Green Trails', c.peerAverage * 0.7),
            ('Eco Stay Collective', c.peerAverage * 0.82),
            ('You', c.dailyTotal),
            ('Legacy Tours', c.peerAverage * 1.1),
          ];
          return Scaffold(
            backgroundColor: AppTheme.bg1,
            body: Container(
              decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Dynamic Benchmark', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'You are ${c.peerAdvantagePercent.toStringAsFixed(0)}% better than similar tourism operators in North Goa this week',
                      style: const TextStyle(color: AppTheme.emerald, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ...peers.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final value = p.$2;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('#${i + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(p.$1, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                                  Text('${value.toStringAsFixed(1)} kg', style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearPercentIndicator(
                                lineHeight: 8,
                                percent: (value / 30).clamp(0.05, 1.0),
                                backgroundColor: AppTheme.surface,
                                progressColor: p.$1 == 'You' ? AppTheme.lime : AppTheme.emerald,
                                barRadius: const Radius.circular(4),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final biz = _biz;
    final myPct = (biz.emissionsKg / (biz.peerAvgKg * 1.5)).clamp(0.0, 1.0);
    final avgPct = (biz.peerAvgKg / (biz.peerAvgKg * 1.5)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Benchmark', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('How ${biz.name} compares', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  children: [
                    _BenchmarkBar('You', biz.emissionsKg, myPct, AppTheme.emerald),
                    const SizedBox(height: 20),
                    _BenchmarkBar('Sector avg', biz.peerAvgKg, avgPct, AppTheme.accentAmber),
                    const SizedBox(height: 20),
                    _BenchmarkBar('Best in class', biz.peerAvgKg * 0.6, biz.peerAvgKg * 0.6 / (biz.peerAvgKg * 1.5), AppTheme.lime),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Peer Rankings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._peerList(biz).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  borderColor: p['isYou'] as bool ? AppTheme.emerald.withValues(alpha: 0.5) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text('#${p['rank']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p['name'] as String, style: TextStyle(color: (p['isYou'] as bool) ? AppTheme.emerald : AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text('${(p['kg'] as double).toInt()} kg/mo', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To reach best-in-class', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 10,
                      percent: myPct * 0.6,
                      backgroundColor: AppTheme.surface,
                      progressColor: AppTheme.emerald,
                      barRadius: const Radius.circular(5),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reduce by ${(biz.emissionsKg - biz.peerAvgKg * 0.6).toStringAsFixed(0)} kg more',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
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

  List<Map<String, dynamic>> _peerList(BusinessModel biz) {
    return [
      {'rank': 1, 'name': 'Green Leaf ${biz.sectorLabel}', 'kg': biz.peerAvgKg * 0.6, 'isYou': false},
      {'rank': 2, 'name': 'Eco ${biz.sectorLabel} Co.', 'kg': biz.peerAvgKg * 0.75, 'isYou': false},
      {'rank': 3, 'name': biz.name, 'kg': biz.emissionsKg, 'isYou': true},
      {'rank': 4, 'name': 'Standard ${biz.sectorLabel}', 'kg': biz.peerAvgKg, 'isYou': false},
      {'rank': 5, 'name': 'Old-school ${biz.sectorLabel}', 'kg': biz.peerAvgKg * 1.3, 'isYou': false},
    ];
  }
}

class _BenchmarkBar extends StatelessWidget {
  final String label;
  final double value;
  final double percent;
  final Color color;
  const _BenchmarkBar(this.label, this.value, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            Text('${value.toInt()} kg', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 12,
          percent: percent,
          backgroundColor: AppTheme.surface,
          progressColor: color,
          barRadius: const Radius.circular(6),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
