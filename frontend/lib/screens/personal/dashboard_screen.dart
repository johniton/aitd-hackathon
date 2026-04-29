import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/static_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_ring.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/activity_tile.dart';
import 'log_activity_screen.dart';
import 'wrapped_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weekTotal = weeklyData.reduce((a, b) => a + b);
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, ${currentUser.name.split(' ').first} 👋',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Your Green Journey', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WrappedScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.emeraldGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Wrapped ✨', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlassCard(
                    child: Row(
                      children: [
                        CarbonRing(
                          value: weekTotal,
                          maxValue: 30,
                          centerLabel: '${weekTotal.toStringAsFixed(1)}kg',
                          centerSub: 'CO₂\nthis week',
                          size: 140,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow('🪙', 'GreenCoins', '${currentUser.greenCoins.toInt()}'),
                              const SizedBox(height: 12),
                              _InfoRow('🔥', 'Streak', '${currentUser.streakDays} days'),
                              const SizedBox(height: 12),
                              _InfoRow('🏆', 'Rank', '#${currentUser.rank}'),
                            ],
                          ),
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
                      StatTile(label: 'Total Saved', value: currentUser.totalCo2Saved.toStringAsFixed(0), unit: 'kg CO₂', icon: Icons.eco),
                      StatTile(label: 'Best Week', value: '12.4', unit: 'kg', icon: Icons.star, color: AppTheme.lime),
                      StatTile(label: 'Activities', value: '147', icon: Icons.check_circle_outline),
                      StatTile(label: 'City Rank', value: '#4', icon: Icons.location_city, color: AppTheme.lime),
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
                      const Text('This Week', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                        child: SizedBox(
                          height: 120,
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
                                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      return Text(days[v.toInt()], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11));
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(weeklyData.length, (i) {
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: weeklyData[i],
                                      gradient: AppTheme.emeraldGradient,
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }),
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
                  child: const Text('Recent Activities', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: ActivityTile(activity: recentActivities[i]),
                  ),
                  childCount: recentActivities.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogActivityScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log Activity'),
        backgroundColor: AppTheme.emerald,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _InfoRow(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
