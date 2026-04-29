import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/api_service.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class BenchmarkScreen extends StatefulWidget {
  final BusinessSector sector;
  const BenchmarkScreen({super.key, required this.sector});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  bool _isLoading = true;
  String _error = '';
  late BusinessModel _biz;
  List<Map<String, dynamic>> _peers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        ApiService.getMyBusiness(),
        ApiService.getBenchmark(),
      ]);
      final biz = futures[0] as BusinessModel;
      final bench = futures[1] as Map<String, dynamic>;
      
      setState(() {
        _biz = biz;
        _peers = List<Map<String, dynamic>>.from(bench['peers'] ?? []);
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
                    _BenchmarkBar('Sector avg', biz.peerAvgKg, avgPct, const Color(0xFFEAB308)),
                    const SizedBox(height: 20),
                    _BenchmarkBar('Best in class', biz.peerAvgKg * 0.6, biz.peerAvgKg * 0.6 / (biz.peerAvgKg * 1.5), AppTheme.lime),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Peer Rankings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._peers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  borderColor: (p['is_you'] as bool? ?? false) ? AppTheme.emerald.withValues(alpha: 0.5) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text('#${p['rank']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p['name'] as String, style: TextStyle(color: (p['is_you'] as bool? ?? false) ? AppTheme.emerald : AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text('${(p['emissions_kg'] as num).toInt()} kg/mo', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
