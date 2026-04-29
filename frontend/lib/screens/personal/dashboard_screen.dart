import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/activity_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_ring.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/activity_tile.dart';
import 'log_activity_screen.dart';
import 'wrapped_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _error = '';
  late UserModel _user;
  late List<double> _weeklyData;
  late List<ActivityModel> _recentActivities;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        ApiService.getMe(),
        ApiService.getWeekly(),
        ApiService.getActivities(limit: 5),
      ]);
      setState(() {
        _user = futures[0] as UserModel;
        _weeklyData = futures[1] as List<double>;
        _recentActivities = futures[2] as List<ActivityModel>;
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
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final weekTotal = _weeklyData.isEmpty ? 0.0 : _weeklyData.reduce((a, b) => a + b);
    final bestWeek = _weeklyData.isEmpty ? 0.0 : _weeklyData.reduce((a, b) => a > b ? a : b);
    
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.emerald,
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
                              Text('Hey, ${_user.name.split(' ').first} 👋',
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
                                _InfoRow('🪙', 'GreenCoins', '${_user.greenCoins.toInt()}'),
                                const SizedBox(height: 12),
                                _InfoRow('🔥', 'Streak', '${_user.streakDays} days'),
                                const SizedBox(height: 12),
                                _InfoRow('🏆', 'Rank', '#${_user.rank}'),
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
                        StatTile(label: 'Total Saved', value: _user.totalCo2Saved.toStringAsFixed(0), unit: 'kg CO₂', icon: Icons.eco),
                        StatTile(label: 'Best Day', value: bestWeek.toStringAsFixed(1), unit: 'kg', icon: Icons.star, color: AppTheme.lime),
                        StatTile(label: 'Activities', value: '${_recentActivities.length}', icon: Icons.check_circle_outline),
                        StatTile(label: 'City Rank', value: '#${_user.rank}', icon: Icons.location_city, color: AppTheme.lime),
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
                                barGroups: List.generate(_weeklyData.length, (i) {
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _weeklyData[i],
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
                if (_recentActivities.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No activities logged yet.', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: ActivityTile(activity: _recentActivities[i]),
                      ),
                      childCount: _recentActivities.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogActivityScreen()));
          _loadData(); // Refresh after logging
        },
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
