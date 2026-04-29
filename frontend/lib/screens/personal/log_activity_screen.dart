import 'package:flutter/material.dart';
import '../../data/emission_factors.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;
  double _co2Result = 0;
  String _analogy = '';

  static const _categories = ['Transport', 'Food', 'Energy', 'Waste'];
  static const _categoryIcons = ['🚲', '🥗', '⚡', '♻️'];

  static const _transportOptions = ['Bike/Walk', 'Bus', 'Auto', 'Car', 'EV'];
  static const _transportCo2 = [0.0, 0.089, 0.095, 0.21, 0.02];
  static const _foodOptions = ['Veg meal', 'Fish meal', 'Meat meal'];
  static const _foodCo2 = [0.5, 1.4, 2.5];
  static const _energyOptions = ['Solar (1kWh)', 'Grid AC (1hr)', 'Fan (1hr)', 'LED light (1hr)'];
  static const _energyCo2 = [0.0, 0.82, 0.08, 0.01];
  static const _wasteOptions = ['Composted 1kg', 'Recycled 1kg', 'Landfill 1kg'];
  static const _wasteCo2 = [0.1, 0.05, 0.7];

  int _selectedOption = 0;

  List<String> get _options {
    switch (_selectedCategory) {
      case 0: return _transportOptions;
      case 1: return _foodOptions;
      case 2: return _energyOptions;
      case 3: return _wasteOptions;
      default: return [];
    }
  }

  List<double> get _co2Values {
    switch (_selectedCategory) {
      case 0: return _transportCo2;
      case 1: return _foodCo2;
      case 2: return _energyCo2;
      case 3: return _wasteCo2;
      default: return [];
    }
  }

  void _calculate() {
    if (_selectedOption < _co2Values.length) {
      final val = _co2Values[_selectedOption];
      setState(() {
        _co2Result = val;
        _analogy = EmissionFactors.analogy(val);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      appBar: AppBar(
        title: const Text('Log Activity'),
        backgroundColor: AppTheme.bg1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'Text'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Receipt'),
            Tab(icon: Icon(Icons.location_on), text: 'Location'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTextTab(),
            _buildPhotoTab(),
            _buildLocationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_categories.length, (i) {
              final selected = _selectedCategory == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = i;
                    _selectedOption = 0;
                    _calculate();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.emerald.withValues(alpha: 0.2) : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppTheme.emerald : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(_categoryIcons[i], style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(_categories[i], style: TextStyle(color: selected ? AppTheme.emerald : AppTheme.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text('Activity', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._options.asMap().entries.map((e) {
            final selected = _selectedOption == e.key;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedOption = e.key;
                _calculate();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.emerald.withValues(alpha: 0.15) : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.emerald : AppTheme.emerald.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value, style: TextStyle(color: selected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 14)),
                    ),
                    Text(
                      '${_co2Values[e.key].toStringAsFixed(3)} kg CO₂',
                      style: TextStyle(
                        color: _co2Values[e.key] == 0 ? AppTheme.emerald : AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          if (_co2Result > 0 || _selectedCategory == 0 && _selectedOption == 0) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('CO₂ Impact', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (_co2Result == 0 ? AppTheme.emerald : AppTheme.warning).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _co2Result == 0 ? '✅ Zero Carbon' : '⚠️ Carbon Added',
                          style: TextStyle(
                            color: _co2Result == 0 ? AppTheme.emerald : AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_co2Result.toStringAsFixed(3)} kg CO₂',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(_analogy, style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Log Activity  +${(_co2Values[_selectedOption] == 0 ? 20 : 5)} coins',
              onPressed: () async {
                try {
                  final categories = ['transport', 'food', 'energy', 'waste'];
                  await ApiService.logActivity(
                    _options[_selectedOption],
                    categories[_selectedCategory],
                    _co2Result,
                    _co2Result == 0, // isSaving
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.emerald,
                        content: Text('Logged! +${_co2Values[_selectedOption] == 0 ? 20 : 5} GreenCoins 🌱'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: Icons.check,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.emerald, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Snap your receipt', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('We\'ll calculate your food & shopping carbon footprint automatically', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GradientButton(label: 'Take Photo', onPressed: () {}, icon: Icons.camera_alt, width: double.infinity),
              const SizedBox(height: 12),
              TextButton(onPressed: () {}, child: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.emerald))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppTheme.emerald, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Auto-detect journey', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Tap to start tracking your route. We\'ll calculate transport emissions when you stop.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GradientButton(label: 'Start Tracking', onPressed: () {}, icon: Icons.play_arrow, width: double.infinity),
            ],
          ),
        ),
      ),
    );
  }
}
