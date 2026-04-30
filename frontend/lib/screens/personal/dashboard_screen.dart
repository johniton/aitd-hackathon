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

// ── Daily challenge data ──────────────────────────────────────────────────────

const _challenges = [
  (icon: '🚶', title: 'Walk it out', desc: 'Walk or cycle instead of a cab for one trip today.', coins: 20),
  (icon: '🌱', title: 'Plant-based meal', desc: 'Skip meat for one meal and log it.', coins: 15),
  (icon: '💡', title: 'Lights off', desc: 'Turn off all standby devices for 4 hours.', coins: 10),
  (icon: '♻️', title: 'Zero waste lunch', desc: 'Bring a lunchbox — no single-use plastic today.', coins: 18),
  (icon: '🚿', title: 'Short shower', desc: 'Keep your shower under 5 minutes.', coins: 12),
  (icon: '🛒', title: 'Local first', desc: 'Buy groceries from a local kirana store.', coins: 14),
  (icon: '📵', title: 'Screen detox', desc: 'Reduce screen time by 1 hour to cut device energy use.', coins: 10),
];

({String icon, String title, String desc, int coins}) _todaysChallenge() {
  final dayIndex = DateTime.now().difference(DateTime(2025)).inDays % _challenges.length;
  return _challenges[dayIndex];
}

// ── Streak milestones ─────────────────────────────────────────────────────────

const _milestones = [7, 14, 30, 60, 100];

bool _isMilestone(int days) => _milestones.contains(days);

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
  bool _challengeDone = false;
  bool _milestoneShown = false;

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
      if (!_milestoneShown && _isMilestone(_user.streakDays)) {
        _milestoneShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showStreakCelebration());
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showStreakCelebration() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _StreakCelebrationDialog(days: _user.streakDays),
    );
  }

  Widget _buildDailyChallenge() {
    final c = _todaysChallenge();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GlassCard(
        borderColor: AppTheme.lime.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DAILY CHALLENGE',
                    style: TextStyle(color: AppTheme.lime, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ),
                const Spacer(),
                Text('+${c.coins} 🪙', style: const TextStyle(color: AppTheme.lime, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(c.desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _challengeDone
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.emerald, size: 18),
                          SizedBox(width: 6),
                          Text('Challenge completed!', style: TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => setState(() => _challengeDone = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lime,
                        foregroundColor: AppTheme.bg1,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Mark as done'),
                    ),
            ),
          ],
        ),
      ),
    );
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
                            child: const Text('Wrapped ✨', style: TextStyle(color: AppTheme.bg1, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    child: _buildDailyChallenge(),
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
        foregroundColor: AppTheme.bg1,
      ),
    );
  }
}

// ── Streak celebration dialog ─────────────────────────────────────────────────

class _StreakCelebrationDialog extends StatefulWidget {
  final int days;
  const _StreakCelebrationDialog({required this.days});

  @override
  State<_StreakCelebrationDialog> createState() => _StreakCelebrationDialogState();
}

class _StreakCelebrationDialogState extends State<_StreakCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _emoji {
    if (widget.days >= 100) return '🏆';
    if (widget.days >= 60) return '💎';
    if (widget.days >= 30) return '🔥';
    if (widget.days >= 14) return '⚡';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  '${widget.days}-Day Streak!',
                  style: const TextStyle(color: AppTheme.emerald, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve been eco-conscious for\n${widget.days} days in a row. Keep it up!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: AppTheme.bg1,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Keep going!', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info row widget ───────────────────────────────────────────────────────────

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
