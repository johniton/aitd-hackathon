import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/static_data.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_tile.dart';

class BusinessDashboard extends StatelessWidget {
  final BusinessSector sector;
  const BusinessDashboard({super.key, required this.sector});

  BusinessModel get _biz => businessProfiles.firstWhere(
    (b) => b.sector == sector,
    orElse: () => businessProfiles.first,
  );

  @override
  Widget build(BuildContext context) {
    final biz = _biz;
    final below = biz.emissionsKg < biz.peerAvgKg;

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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${biz.sectorIcon} ${biz.sectorLabel}', style: const TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(biz.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Emissions', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${biz.emissionsKg.toInt()} kg', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Text('CO₂', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(below ? Icons.trending_down : Icons.trending_up, color: below ? AppTheme.emerald : AppTheme.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              below
                                  ? '${((biz.peerAvgKg - biz.emissionsKg) / biz.peerAvgKg * 100).toStringAsFixed(0)}% below sector average'
                                  : '${((biz.emissionsKg - biz.peerAvgKg) / biz.peerAvgKg * 100).toStringAsFixed(0)}% above sector average',
                              style: TextStyle(color: below ? AppTheme.emerald : AppTheme.warning, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatTile(label: 'Peer Average', value: '${biz.peerAvgKg.toInt()}', unit: 'kg', icon: Icons.group),
                      StatTile(label: 'Badges', value: '${biz.earnedBadges.length}', icon: Icons.military_tech, color: AppTheme.lime),
                      StatTile(label: 'Reduction', value: below ? '${((biz.peerAvgKg - biz.emissionsKg)).toInt()}' : '-', unit: below ? 'kg' : '', icon: Icons.eco),
                      StatTile(label: 'Suggestions', value: '${biz.suggestions.length}', icon: Icons.lightbulb_outline, color: AppTheme.lime),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emission Breakdown', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: SizedBox(
                          height: 140,
                          child: BarChart(
                            BarChartData(
                              backgroundColor: Colors.transparent,
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const labels = ['Energy', 'Transport', 'Waste', 'Water'];
                                      return Text(labels[v.toInt()], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10));
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                _bar(0, biz.emissionsKg * 0.45),
                                _bar(1, biz.emissionsKg * 0.28),
                                _bar(2, biz.emissionsKg * 0.17),
                                _bar(3, biz.emissionsKg * 0.10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: const Text('Suggestions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.lightbulb, color: AppTheme.lime, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(biz.suggestions[i], style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                  childCount: biz.suggestions.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: const Text('Earned Badges', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  child: GlassCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: biz.earnedBadges.map((b) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.lime.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.lime.withValues(alpha: 0.4)),
                        ),
                        child: Text('🏅 $b', style: const TextStyle(color: AppTheme.lime, fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppTheme.emeraldGradient,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
