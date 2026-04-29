import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class ImpactSimulatorScreen extends StatefulWidget {
  const ImpactSimulatorScreen({super.key});

  @override
  State<ImpactSimulatorScreen> createState() => _ImpactSimulatorScreenState();
}

class _ImpactSimulatorScreenState extends State<ImpactSimulatorScreen> {
  final Set<String> _selected = {};

  static const _scenarios = [
    _Scenario('car_to_bus', '🚌', 'Switch car → bus', 'Save ~1.2 kg per 6 km trip', -1.2),
    _Scenario('meat_free', '🥗', 'One meat-free day/week', 'Save ~2.0 kg per week', -2.0),
    _Scenario('solar', '☀️', 'Solar panel at home', 'Save ~4.0 kg per week', -4.0),
    _Scenario('short_shower', '🚿', 'Shorter showers', 'Save ~0.8 kg per week', -0.8),
    _Scenario('compost', '🍂', 'Compost kitchen waste', 'Save ~1.5 kg per week', -1.5),
    _Scenario('bike', '🚲', 'Cycle for short trips', 'Save ~0.9 kg per 4 km trip', -0.9),
  ];

  double get _weeklyDelta =>
      _selected.fold(0.0, (sum, id) => sum + _scenarios.firstWhere((s) => s.id == id).weeklyDeltaKg);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final weekly = state.weekly;
    final weekTotal = weekly.reduce((a, b) => a + b);
    final projectedTotal = (weekTotal + _weeklyDelta).clamp(0.0, double.infinity);

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('What-If Simulator', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(child: _SummaryCard(label: 'Current Week', value: '${weekTotal.toStringAsFixed(1)} kg', color: AppTheme.textSecondary)),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryCard(label: 'With Changes', value: '${projectedTotal.toStringAsFixed(1)} kg', color: AppTheme.emerald)),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryCard(
                        label: 'You Save',
                        value: '${(-_weeklyDelta).clamp(0, double.infinity).toStringAsFixed(1)} kg',
                        color: AppTheme.lime,
                      )),
                    ],
                  ),
                ),
              ),

              // Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weekly CO₂ Projection', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _Legend(color: AppTheme.textSecondary, label: 'Current'),
                            const SizedBox(width: 16),
                            _Legend(color: AppTheme.lime, label: 'Projected'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              backgroundColor: Colors.transparent,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.textSecondary.withValues(alpha: 0.1), strokeWidth: 1),
                              ),
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
                              lineBarsData: [
                                // Current line
                                LineChartBarData(
                                  spots: List.generate(weekly.length, (i) => FlSpot(i.toDouble(), weekly[i])),
                                  isCurved: true,
                                  color: AppTheme.textSecondary,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.textSecondary.withValues(alpha: 0.05),
                                  ),
                                ),
                                // Projected line
                                LineChartBarData(
                                  spots: List.generate(weekly.length, (i) {
                                    final proj = (weekly[i] + _weeklyDelta / 7).clamp(0.0, double.infinity);
                                    return FlSpot(i.toDouble(), proj);
                                  }),
                                  isCurved: true,
                                  color: AppTheme.lime,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.lime.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scenarios
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: const Text('Select Habit Changes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final s = _scenarios[i];
                      final selected = _selected.contains(s.id);
                      return GestureDetector(
                        onTap: () => setState(() => selected ? _selected.remove(s.id) : _selected.add(s.id)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? AppTheme.emerald : AppTheme.emerald.withValues(alpha: 0.2),
                              width: selected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: selected ? AppTheme.emerald.withValues(alpha: 0.12) : AppTheme.cardBg,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                                  const Spacer(),
                                  if (selected)
                                    const Icon(Icons.check_circle, color: AppTheme.emerald, size: 16),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.weeklyDeltaKg.abs().toStringAsFixed(1)} kg/wk',
                                    style: const TextStyle(color: AppTheme.lime, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _scenarios.length,
                  ),
                ),
              ),

              // Annualised impact
              if (_selected.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GlassCard(
                      borderColor: AppTheme.lime.withValues(alpha: 0.4),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppTheme.lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Text('🌳', style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Annual Impact', style: TextStyle(color: AppTheme.lime, fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Save ${(-_weeklyDelta * 52).clamp(0, double.infinity).toStringAsFixed(0)} kg CO₂/yr — equivalent to planting ${((-_weeklyDelta * 52) / 7.3).clamp(0, double.infinity).round()} trees',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _Scenario {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final double weeklyDeltaKg;
  const _Scenario(this.id, this.emoji, this.title, this.description, this.weeklyDeltaKg);
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
