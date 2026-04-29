import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/business_model.dart';
import '../../models/tourism_engine_models.dart';
import '../../services/tourism_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/scope_badge.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../data/subsidy_database.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDashboard extends StatefulWidget {
  final BusinessSector sector;
  final TourismEngineController? tourismController;
  const BusinessDashboard({
    super.key,
    required this.sector,
    this.tourismController,
  });

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  // Tourism
  TransportMode _mode = TransportMode.car;
  double _distance = 25;
  double _electricity = 34;
  double _lpg = 5;
  double _organicWaste = 7;
  double _oilWaste = 2;

  // Cashew
  double _roastingHours = 6;
  double _shellWaste = 15;
  double _cnslOil = 3;
  String _fuelType = 'firewood';

  // Farmer
  double _landAcres = 2;
  double _fertilizer = 10;
  double _pesticide = 2;
  double _waterUsage = 500;
  String _cropType = 'paddy';
  String _irrigationType = 'flood';

  // Bakery
  double _ovenHours = 8;
  double _flourKg = 25;
  double _butterKg = 5;
  double _breadWaste = 3;
  String _ovenFuel = 'electric';

  // Other
  String _otherBusiness = '';
  double _otherWater = 500;
  String _otherWaste = 'mixed';
  String _otherEnergy = 'grid';
  bool _otherFormSubmitted = false;

  @override
  void initState() {
    super.initState();
    final c = widget.tourismController;
    if (c != null) {
      _mode = c.selectedMode;
      _distance = c.selectedDistance;
      _electricity = c.electricityKwh;
      _lpg = c.lpgKg;
      _organicWaste = c.organicWasteKg;
      _oilWaste = c.oilWasteKg;
      _roastingHours = c.roastingHours;
      _shellWaste = c.shellWasteKg;
      _cnslOil = c.cnslOilLitres;
      _fuelType = c.fuelType;
      _landAcres = c.landAcres;
      _fertilizer = c.fertilizerKg;
      _pesticide = c.pesticideL;
      _waterUsage = c.waterUsageL;
      _cropType = c.cropType;
      _irrigationType = c.irrigationType;
      _ovenHours = c.ovenHours;
      _flourKg = c.flourKg;
      _butterKg = c.butterKg;
      _breadWaste = c.breadWasteKg;
      _ovenFuel = c.ovenFuel;
      _otherBusiness = c.otherBusinessType;
      _otherWater = c.otherWaterUsageL;
      _otherWaste = c.otherWasteType;
      _otherEnergy = c.otherEnergySource;
    }
  }

  String get _sectorTitle {
    switch (widget.sector) {
      case BusinessSector.tourism:
        return '🏖️ Tourism Sustainability Engine';
      case BusinessSector.cashew:
        return '🌰 Cashew Factory Sustainability';
      case BusinessSector.farmer:
        return '🌾 Farm Sustainability Engine';
      case BusinessSector.bakery:
        return '🍞 Bakery Sustainability Engine';
      case BusinessSector.other:
        return '⚙️ Custom Business Profile';
    }
  }

  String get _sectorSubtitle {
    switch (widget.sector) {
      case BusinessSector.tourism:
        return 'Optimize your tourism business for sustainability';
      case BusinessSector.cashew:
        return 'Reduce emissions from cashew processing in Goa';
      case BusinessSector.farmer:
        return 'Sustainable farming practices for Goan agriculture';
      case BusinessSector.bakery:
        return 'Eco-friendly bakery operations for Goan poder';
      case BusinessSector.other:
        return 'Tailor-made sustainability analysis for your business';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.tourismController;
    if (c == null) return const SizedBox.shrink();

    // For 'Other' sector: show form FIRST, dashboard only after submission
    if (widget.sector == BusinessSector.other && !_otherFormSubmitted) {
      return _buildOtherForm(context, c);
    }

    return AnimatedBuilder(
      animation: c,
      builder: (_, __) => _buildDashboard(context, c),
    );
  }

  Widget _buildDashboard(BuildContext context, TourismEngineController c) {
    final plan = c.latestSustainabilityPlan;
    final down = c.weeklyDeltaPercent < 0;

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            children: [
              Text(_sectorTitle, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_sectorSubtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),

              // ── CO₂ Ring ──
              GlassCard(child: Column(children: [
                SizedBox(height: 130, child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 120, height: 120, child: CircularProgressIndicator(
                    value: (c.dailyTotal / 40).clamp(0.0, 1.0), strokeWidth: 12,
                    backgroundColor: AppTheme.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emerald),
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${c.dailyTotal.toStringAsFixed(1)} kg', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    const Text('CO₂ today', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
                ])),
                const SizedBox(height: 8),
                Text('Daily emissions: ${c.dailyTotal.toStringAsFixed(1)} kg CO₂', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${down ? "↓" : "↑"} ${c.weeklyDeltaPercent.abs().toStringAsFixed(0)}% from last week',
                    style: TextStyle(color: down ? AppTheme.emerald : AppTheme.warning, fontSize: 12)),
              ])),
              const SizedBox(height: 14),

              // ── ACTION ICONS ROW ──
              if (plan != null) GlassCard(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionIcon(Icons.eco, plan.savings.carbonReduction, 'CO₂ Cut'),
                  _actionIcon(Icons.currency_rupee, plan.savings.moneySaved, 'Saved'),
                  _actionIcon(Icons.lightbulb, '${plan.optimizedPlanSteps.length} Steps', 'Plan'),
                  _actionIcon(Icons.local_offer, plan.subsidy.name.isNotEmpty ? plan.subsidy.name : 'Subsidy', 'Subsidy'),
                ],
              )),
              if (plan != null) const SizedBox(height: 14),

              // ── LOADING ──
              if (c.isLoadingPlan)
                GlassCard(child: Row(children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emerald)),
                  const SizedBox(width: 12),
                  const Text('AI is analyzing your sustainability...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ])),
              if (c.isLoadingPlan) const SizedBox(height: 14),

              // ── EXPANDABLE OPTIMIZED PLAN ──
              if (plan != null && plan.optimizedPlanSteps.isNotEmpty)
                GlassCard(child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero, initiallyExpanded: true,
                    title: const Text('🗺️ AI Optimized Plan', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    subtitle: Text('${plan.optimizedPlanSteps.length} eco-steps • ${plan.optimized['carbon'] ?? ''}',
                        style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                    iconColor: AppTheme.emerald, collapsedIconColor: AppTheme.textSecondary,
                    children: plan.optimizedPlanSteps.map<Widget>((step) => ListTile(
                      dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.check_circle, color: AppTheme.lime, size: 18),
                      title: Text(step, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    )).toList(),
                  ),
                )),
              if (plan != null && plan.optimizedPlanSteps.isNotEmpty) const SizedBox(height: 14),

              // ── SUBSIDY CARD ──
              if (plan != null && plan.subsidy.name.isNotEmpty)
                GlassCard(
                  borderColor: AppTheme.lime.withValues(alpha: 0.4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.savings, color: AppTheme.lime, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💰 AI-Matched Subsidy', style: TextStyle(color: AppTheme.lime, fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(plan.subsidy.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      ])),
                      Text(plan.subsidy.amount, style: const TextStyle(color: AppTheme.lime, fontSize: 14, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    Text(plan.subsidy.reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    if (plan.source != 'fallback') ...[
                      const SizedBox(height: 4),
                      Text('Source: ${plan.source.toUpperCase()} AI', style: TextStyle(color: AppTheme.emerald.withValues(alpha: 0.6), fontSize: 10)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Apply Now (AI Guide)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lime.withValues(alpha: 0.2),
                          foregroundColor: AppTheme.lime,
                          elevation: 0,
                        ),
                        onPressed: () => _showApplyDialog(context, plan.subsidy.name, c),
                      ),
                    ),
                  ]),
                ),
              if (plan != null && plan.subsidy.name.isNotEmpty) const SizedBox(height: 14),

              // ── REAL-LIFE ANALYSIS ──
              if (plan != null && plan.analysis.isNotEmpty)
                GlassCard(
                  borderColor: AppTheme.emerald.withValues(alpha: 0.3),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🌴 Real-Life Impact', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('What your savings mean in real Goa terms', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 10),
                    ...plan.analysis.map<Widget>((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 28, height: 28,
                          decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.eco, color: AppTheme.emerald, size: 14)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                      ]),
                    )),
                  ]),
                ),
              if (plan != null && plan.analysis.isNotEmpty) const SizedBox(height: 14),

              // ── AI INSIGHT ──
              if (plan != null && plan.insight.isNotEmpty)
                GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('🤖 AI Insight', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(plan.insight, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  if (plan.emotionalMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(plan.emotionalMessage, style: const TextStyle(color: AppTheme.lime, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ])),
              if (plan != null && plan.insight.isNotEmpty) const SizedBox(height: 14),

              // ── SECTOR-SPECIFIC INPUTS ──
              _buildSectorInputs(c),
              const SizedBox(height: 14),

              // ── WEEKLY TREND ──
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Weekly Trend', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(height: 120, child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [LineChartBarData(
                    spots: [for (int i = 0; i < c.weeklyTotals.length; i++) FlSpot(i.toDouble(), c.weeklyTotals[i])],
                    isCurved: true, barWidth: 3, gradient: AppTheme.emeraldGradient, dotData: const FlDotData(show: false),
                  )],
                ))),
              ])),
              const SizedBox(height: 14),

              // ── SIMULATION ──
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Impact Simulation', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const Text('If you switch to eco option', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Slider(min: 0, max: 70, value: c.simulationPercent, activeColor: AppTheme.lime, onChanged: c.updateSimulation),
                Text('Carbon saved: ${c.simulatedCarbonSaved.toStringAsFixed(1)} kg', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                Text('Money saved: Rs ${c.simulatedMoneySaved.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
                Text('Eco score: ${(c.ecoScore + c.simulationPercent * 0.2).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
              const SizedBox(height: 14),

              // ── REFRESH ──
              ElevatedButton.icon(
                onPressed: c.isLoadingPlan ? null : c.fetchSustainabilityPlan,
                icon: const Icon(Icons.refresh), label: const Text('Refresh AI Analysis'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
              const SizedBox(height: 14),

              // ── PEER + BADGE ──
              Row(children: [
                Expanded(child: StatTile(label: 'Eco Score', value: c.ecoScore.toStringAsFixed(0), unit: '/100', icon: Icons.star)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Badge', value: c.badge, icon: Icons.workspace_premium, color: AppTheme.lime)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  SECTOR-SPECIFIC INPUT SECTIONS
  // ════════════════════════════════════════════════

  Widget _buildSectorInputs(TourismEngineController c) {
    switch (widget.sector) {
      case BusinessSector.tourism:
        return _tourismInputs(c);
      case BusinessSector.cashew:
        return _cashewInputs(c);
      case BusinessSector.farmer:
        return _farmerInputs(c);
      case BusinessSector.bakery:
        return _bakeryInputs(c);
      case BusinessSector.other:
        return _otherInputs(c);
    }
  }

  Widget _tourismInputs(TourismEngineController c) {
    return Column(children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏖️ Tourism Operations', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(children: const [Text('Guest transport mode', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope3)]),
        DropdownButtonFormField<TransportMode>(
          value: _mode, dropdownColor: AppTheme.surface,
          items: TransportMode.values.map((m) => DropdownMenuItem(value: m, child: Text(_modeLabel(m)))).toList(),
          onChanged: (v) { setState(() => _mode = v ?? TransportMode.car); c.onInputChanged(mode: _mode); },
        ),
        const SizedBox(height: 8),
        _slider('Distance (km)', _distance, 1, 30, (v) { setState(() => _distance = v); c.onInputChanged(distance: v); }, scope: EmissionScope.scope3),
        _slider('Electricity kWh', _electricity, 0, 100, (v) { setState(() => _electricity = v); c.onInputChanged(electricity: v); }, scope: EmissionScope.scope2),
        _slider('LPG kg', _lpg, 0, 20, (v) { setState(() => _lpg = v); c.onInputChanged(lpg: v); }, scope: EmissionScope.scope1),
        _slider('Organic waste kg', _organicWaste, 0, 30, (v) { setState(() => _organicWaste = v); c.onInputChanged(organic: v); }, scope: EmissionScope.scope1),
        _slider('Oil waste kg', _oilWaste, 0, 15, (v) { setState(() => _oilWaste = v); c.onInputChanged(oil: v); }, scope: EmissionScope.scope1),
      ])),
      if (c.activeTrip == null) ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () => c.startTrip(mode: _mode, mockDistanceKm: _distance), child: const Text('Start Trip'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: null, child: const Text('End Trip'))),
        ]),
      ] else ...[
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: null, child: const Text('Trip Active...'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: c.endTrip, child: const Text('End Trip'))),
        ]),
      ],
    ]);
  }

  Widget _cashewInputs(TourismEngineController c) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🌰 Cashew Factory Operations', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Row(children: const [Text('Roasting fuel type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope1)]),
      DropdownButtonFormField<String>(
        value: _fuelType, dropdownColor: AppTheme.surface,
        items: ['firewood', 'biomass', 'electric', 'LPG'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _fuelType = v ?? 'firewood'); c.onInputChanged(fuel: _fuelType); },
      ),
      const SizedBox(height: 8),
      _slider('Roasting hours/day', _roastingHours, 1, 16, (v) { setState(() => _roastingHours = v); c.onInputChanged(roasting: v); }, scope: EmissionScope.scope1),
      _slider('Shell waste kg/day', _shellWaste, 0, 50, (v) { setState(() => _shellWaste = v); c.onInputChanged(shellWaste: v); }, scope: EmissionScope.scope1),
      _slider('CNSL oil litres/day', _cnslOil, 0, 15, (v) { setState(() => _cnslOil = v); c.onInputChanged(cnsl: v); }, scope: EmissionScope.scope1),
      _slider('Electricity kWh', _electricity, 0, 200, (v) { setState(() => _electricity = v); c.onInputChanged(electricity: v); }, scope: EmissionScope.scope2),
      _slider('LPG kg', _lpg, 0, 30, (v) { setState(() => _lpg = v); c.onInputChanged(lpg: v); }, scope: EmissionScope.scope1),
    ]));
  }

  Widget _farmerInputs(TourismEngineController c) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🌾 Farm Operations', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _cropType, dropdownColor: AppTheme.surface,
        decoration: const InputDecoration(labelText: 'Crop type'),
        items: ['paddy', 'coconut', 'cashew', 'spices', 'vegetables', 'fruits'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _cropType = v ?? 'paddy'); c.onInputChanged(crop: _cropType); },
      ),
      const SizedBox(height: 8),
      Row(children: const [Text('Irrigation type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope1), ScopeBadge(scope: EmissionScope.scope2)]),
      DropdownButtonFormField<String>(
        value: _irrigationType, dropdownColor: AppTheme.surface,
        items: ['flood', 'drip', 'sprinkler', 'rainfed'].map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _irrigationType = v ?? 'flood'); c.onInputChanged(irrigation: _irrigationType); },
      ),
      const SizedBox(height: 8),
      _slider('Land (acres)', _landAcres, 0.5, 20, (v) { setState(() => _landAcres = v); c.onInputChanged(land: v); }),
      _slider('Chemical fertilizer kg/day', _fertilizer, 0, 50, (v) { setState(() => _fertilizer = v); c.onInputChanged(fertilizer: v); }, scope: EmissionScope.scope1),
      _slider('Pesticide litres/day', _pesticide, 0, 10, (v) { setState(() => _pesticide = v); c.onInputChanged(pesticide: v); }, scope: EmissionScope.scope1),
      _slider('Water usage litres/day', _waterUsage, 0, 2000, (v) { setState(() => _waterUsage = v); c.onInputChanged(water: v); }, scope: EmissionScope.scope2),
      _slider('Electricity kWh (pump)', _electricity, 0, 100, (v) { setState(() => _electricity = v); c.onInputChanged(electricity: v); }, scope: EmissionScope.scope2),
    ]));
  }

  Widget _bakeryInputs(TourismEngineController c) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🍞 Bakery Operations', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Row(children: const [Text('Oven fuel type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope1)]),
      DropdownButtonFormField<String>(
        value: _ovenFuel, dropdownColor: AppTheme.surface,
        items: ['electric', 'gas', 'wood-fired'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _ovenFuel = v ?? 'electric'); c.onInputChanged(ovenFuelType: _ovenFuel); },
      ),
      const SizedBox(height: 8),
      _slider('Oven hours/day', _ovenHours, 1, 16, (v) { setState(() => _ovenHours = v); c.onInputChanged(oven: v); }, scope: EmissionScope.scope1),
      _slider('Flour kg/day', _flourKg, 5, 100, (v) { setState(() => _flourKg = v); c.onInputChanged(flour: v); }, scope: EmissionScope.scope3),
      _slider('Butter/fat kg/day', _butterKg, 0, 20, (v) { setState(() => _butterKg = v); c.onInputChanged(butter: v); }, scope: EmissionScope.scope3),
      _slider('Bread waste kg/day', _breadWaste, 0, 15, (v) { setState(() => _breadWaste = v); c.onInputChanged(breadWaste: v); }, scope: EmissionScope.scope1),
      _slider('Electricity kWh', _electricity, 0, 150, (v) { setState(() => _electricity = v); c.onInputChanged(electricity: v); }, scope: EmissionScope.scope2),
    ]));
  }

  Widget _otherInputs(TourismEngineController c) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('⚙️ Custom Business Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextFormField(
        initialValue: _otherBusiness,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(labelText: 'Business Type (e.g. Retail, Tech)',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary))),
        onChanged: (v) {
          _otherBusiness = v;
          c.onInputChanged(otherBusiness: v);
        },
      ),
      const SizedBox(height: 8),
      Row(children: const [Text('Energy Source', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope2)]),
      DropdownButtonFormField<String>(
        value: _otherEnergy, dropdownColor: AppTheme.surface,
        items: ['grid', 'solar', 'diesel'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _otherEnergy = v ?? 'grid'); c.onInputChanged(otherEnergy: _otherEnergy); },
      ),
      const SizedBox(height: 8),
      Row(children: const [Text('Primary Waste Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)), ScopeBadge(scope: EmissionScope.scope1)]),
      DropdownButtonFormField<String>(
        value: _otherWaste, dropdownColor: AppTheme.surface,
        items: ['mixed', 'organic', 'plastic', 'electronic', 'chemical'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
        onChanged: (v) { setState(() => _otherWaste = v ?? 'mixed'); c.onInputChanged(otherWaste: _otherWaste); },
      ),
      const SizedBox(height: 8),
      _slider('Electricity kWh/day', _electricity, 0, 500, (v) { setState(() => _electricity = v); c.onInputChanged(electricity: v); }, scope: EmissionScope.scope2),
      _slider('Water usage litres/day', _otherWater, 0, 5000, (v) { setState(() => _otherWater = v); c.onInputChanged(otherWater: v); }, scope: EmissionScope.scope2),
      _slider('Organic waste kg/day', _organicWaste, 0, 100, (v) { setState(() => _organicWaste = v); c.onInputChanged(organic: v); }, scope: EmissionScope.scope1),
      _slider('Other waste kg/day', _oilWaste, 0, 100, (v) { setState(() => _oilWaste = v); c.onInputChanged(oil: v); }, scope: EmissionScope.scope1),
    ]));
  }

  // ════════════════════════════════════════════════
  //  "OTHER" SECTOR — INTAKE FORM
  // ════════════════════════════════════════════════

  Widget _buildOtherForm(BuildContext context, TourismEngineController c) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              const Text('CUSTOM BUSINESS', style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('Tell us about\nyour business', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 6),
              const Text('We need these details to generate a custom AI sustainability analysis, carbon credit assessment, and subsidy matches for your specific business.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),

              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('1. What is your business?', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('E.g. Retail Shop, Clinic, Tech Startup, Restaurant, Printing Press', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _otherBusiness,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type your business type...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.emerald.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.emerald), borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: AppTheme.surface,
                  ),
                  onChanged: (v) => setState(() => _otherBusiness = v),
                ),
              ])),
              const SizedBox(height: 12),

              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('2. Energy & Utilities', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _otherEnergy, dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(labelText: 'Primary Energy Source'),
                  items: ['grid', 'solar', 'diesel'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _otherEnergy = v ?? 'grid'),
                ),
                const SizedBox(height: 8),
                _slider('Electricity kWh/day', _electricity, 0, 500, (v) => setState(() => _electricity = v)),
                _slider('Water usage litres/day', _otherWater, 0, 5000, (v) => setState(() => _otherWater = v)),
              ])),
              const SizedBox(height: 12),

              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('3. Waste Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _otherWaste, dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(labelText: 'Primary Waste Type'),
                  items: ['mixed', 'organic', 'plastic', 'electronic', 'chemical'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _otherWaste = v ?? 'mixed'),
                ),
                const SizedBox(height: 8),
                _slider('Organic waste kg/day', _organicWaste, 0, 100, (v) => setState(() => _organicWaste = v)),
                _slider('Other waste kg/day', _oilWaste, 0, 100, (v) => setState(() => _oilWaste = v)),
              ])),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch, size: 20),
                  label: const Text('Generate Sustainability Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _otherBusiness.trim().isEmpty ? null : () {
                    const List<String> blockedBusinessTypes = [
                      "weapons", "arms", "ammunition", "tobacco", "cigarette",
                      "alcohol distillery", "crypto mining", "gambling", "casino",
                    ];
                    final lower = _otherBusiness.trim().toLowerCase();
                    bool isBlocked = blockedBusinessTypes.any((b) => lower.contains(b));
                    
                    if (isBlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Carbon credit analysis is not available for this business type."),
                        backgroundColor: AppTheme.warning,
                      ));
                      return;
                    }

                    c.onInputChanged(otherBusiness: _otherBusiness, otherEnergy: _otherEnergy,
                      otherWaste: _otherWaste, otherWater: _otherWater,
                      electricity: _electricity, organic: _organicWaste, oil: _oilWaste);
                    setState(() => _otherFormSubmitted = true);
                  },
                ),
              ),
              if (_otherBusiness.trim().isEmpty) ...[
                const SizedBox(height: 8),
                const Text('Please enter your business type to continue',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──



  Widget _actionIcon(IconData icon, String label, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.emerald, size: 22)),
      const SizedBox(height: 6),
      Text(label.length > 14 ? '${label.substring(0, 14)}…' : label,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
    ]);
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {EmissionScope? scope}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('$label: ${value.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        if (scope != null) ScopeBadge(scope: scope),
      ]),
      Slider(min: min, max: max, value: value, activeColor: AppTheme.emerald, onChanged: onChanged),
    ]);
  }

  String _modeLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.car: return '🚗 Car';
      case TransportMode.bike: return '🚲 Bike';
      case TransportMode.bus: return '🚌 Bus';
      case TransportMode.walking: return '🚶 Walking';
    }
  }

  void _showApplyDialog(BuildContext context, String title, TourismEngineController c) {
    // Try to find the exact scheme, or use the first one as fallback if not found
    final subsidy = subsidyDatabase[title] ?? subsidyDatabase.values.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppTheme.bgGradient, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppTheme.emerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Apply: ${subsidy.name}', 
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const DisclaimerBanner(disclaimerKey: 'subsidy_apply_disclaimer'),
                const SizedBox(height: 8),
                Text('Basic Eligibility', style: const TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subsidy.basicEligibility, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                Text('Goa Office', style: const TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subsidy.goaOfficeAddress, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                Text('Disclaimer', style: const TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(subsidy.disclaimer, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('⚠️ This app does not provide legal or financial advice. Visit the official portal to confirm your eligibility.', style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                        onPressed: () async {
                          final uri = Uri.parse(subsidy.officialUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Could not open ${subsidy.officialUrl}'),
                              backgroundColor: AppTheme.warning,
                            ));
                          }
                        },
                        child: const Text('Official Portal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close', style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
