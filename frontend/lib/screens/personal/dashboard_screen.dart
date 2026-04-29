import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_ring.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/activity_tile.dart';
import 'log_activity_screen.dart';
import 'wrapped_screen.dart';
import 'impact_simulator_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final weekly = state.weekly;
    final activities = state.activities;
    final weekTotal = weekly.reduce((a, b) => a + b);

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, ${user.name.split(' ').first} 👋', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Your Green Journey', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WrappedScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(gradient: AppTheme.emeraldGradient, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Wrapped ✨', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Ring + stats
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
                              _InfoRow('🪙', 'GreenCoins', '${user.greenCoins.toInt()}'),
                              const SizedBox(height: 12),
                              _InfoRow('🔥', 'Streak', '${user.streakDays} days'),
                              const SizedBox(height: 12),
                              _InfoRow('🏆', 'Rank', '#${user.rank}'),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => Share.share('🌿 I saved ${user.totalCo2Saved.toStringAsFixed(0)} kg CO₂ and earned ${user.greenCoins.toInt()} GreenCoins on GoaGreen! Join me: #GoaGreen #ActNow'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.4)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.share, color: AppTheme.emerald, size: 14),
                                      SizedBox(width: 4),
                                      Text('Share', style: TextStyle(color: AppTheme.emerald, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stat grid
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
                      StatTile(label: 'Total Saved', value: user.totalCo2Saved.toStringAsFixed(0), unit: 'kg CO₂', icon: Icons.eco),
                      StatTile(label: 'Activities', value: '${activities.length}', icon: Icons.check_circle_outline),
                      StatTile(label: 'City Rank', value: '#${user.rank}', icon: Icons.location_city, color: AppTheme.lime),
                      StatTile(label: 'Trees equiv.', value: '${(user.totalCo2Saved / 7.3).round()}', unit: 'trees', icon: Icons.park, color: AppTheme.lime),
                    ],
                  ),
                ),
              ),

              // AI Smart Tip
              if (state.smartTip != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactSimulatorScreen())),
                      child: GlassCard(
                        borderColor: AppTheme.lime.withValues(alpha: 0.4),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppTheme.lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Smart Tip', style: TextStyle(color: AppTheme.lime, fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(state.smartTip!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Backend suggestions
              if (state.lastSuggestions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GlassCard(
                      borderColor: AppTheme.emerald.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text('AI Suggestions', style: TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...state.lastSuggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.message, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                      Text('Save ~${s.estimatedSavingsKg.toStringAsFixed(2)} kg CO₂', style: const TextStyle(color: AppTheme.emerald, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),

              // Weekly chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('This Week', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactSimulatorScreen())),
                            child: const Text('What-if →', style: TextStyle(color: AppTheme.emerald, fontSize: 13)),
                          ),
                        ],
                      ),
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
                              barGroups: List.generate(weekly.length, (i) {
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: weekly[i],
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

              // Recent activities
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
                    child: ActivityTile(activity: activities[i]),
                  ),
                  childCount: activities.length > 5 ? 5 : activities.length,
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
