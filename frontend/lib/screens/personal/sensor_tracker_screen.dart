import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../sensors/sensors.dart';

// ── Sensor state model ───────────────────────────────────────────────────────

class _SensorState {
  // Transport
  TransportMode transportMode = TransportMode.stationary;
  double transportKgToday = 0.0;
  double transportDistanceKm = 0.0;
  List<double> transportHistory = List.filled(20, 0.0);

  // Financial
  int lastMcc = 0;
  String lastMerchant = '—';
  String lastCategory = '—';
  double financialKgToday = 0.0;
  List<double> financialHistory = List.filled(20, 0.0);

  // Digital
  double batteryDelta = 0.0;
  double networkGb = 0.0;
  double digitalKgToday = 0.0;
  double gridIntensity = 400.0;
  List<double> digitalHistory = List.filled(20, 0.0);

  // Privacy
  bool privacyShieldEnabled = true;
  int eventsBlocked = 0;

  double get totalKgToday =>
      transportKgToday + financialKgToday + digitalKgToday;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SensorTrackerScreen extends StatefulWidget {
  const SensorTrackerScreen({super.key});

  @override
  State<SensorTrackerScreen> createState() => _SensorTrackerScreenState();
}

class _SensorTrackerScreenState extends State<SensorTrackerScreen>
    with TickerProviderStateMixin {
  final _state = _SensorState();
  final _rng = Random();

  late MotionActivityService _motionService;
  late TransactionSensorService _txService;
  late DeviceFootprintService _deviceService;

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  Timer? _digitalTicker;
  Timer? _txTicker;
  Timer? _gridTicker;

  // Simulated transaction feed
  static const _sampleTransactions = [
    (5541, 'Shell Garage', 48.50),
    (5812, 'Nandos', 22.00),
    (4511, 'Ryanair', 189.99),
    (5411, 'Tesco Express', 34.20),
    (4121, 'Uber', 12.80),
    (5999, 'Amazon', 67.00),
    (4900, 'British Gas', 95.00),
    (5814, 'McDonalds', 8.50),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic);
    _ringController.forward();

    // ── Transport service ────────────────────────────────────────────────────
    _motionService = MotionActivityService(
      onCarbonEstimate: (est) {
        if (!mounted) return;
        setState(() {
          _state.transportMode = est.mode;
          _state.transportKgToday += est.kgCo2e;
          _state.transportDistanceKm += est.distanceKm;
          _state.transportHistory = [
            ..._state.transportHistory.skip(1),
            est.kgCo2e.clamp(0, 5),
          ];
        });
        _pulseController.reset();
        _pulseController.repeat(reverse: true);
      },
    );
    _motionService.start();

    // Inject simulated transport ticks every 6 s for demo visibility
    Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final modes = [
        TransportMode.automotive,
        TransportMode.automotive,
        TransportMode.cycling,
        TransportMode.stationary,
      ];
      final mode = modes[_rng.nextInt(modes.length)];
      final dist = 0.3 + _rng.nextDouble() * 1.5;
      const factors = {
        TransportMode.automotive: 0.171,
        TransportMode.cycling: 0.0,
        TransportMode.stationary: 0.0,
        TransportMode.walking: 0.0,
        TransportMode.unknown: 0.0,
      };
      final kg = (factors[mode] ?? 0) * dist;
      setState(() {
        _state.transportMode = mode;
        _state.transportDistanceKm += dist;
        _state.transportKgToday += kg;
        _state.transportHistory = [
          ..._state.transportHistory.skip(1),
          kg.clamp(0, 5),
        ];
      });
    });

    // ── Financial service ────────────────────────────────────────────────────
    _txService = TransactionSensorService(
      onCarbonLogged: (log) {
        if (!mounted) return;
        setState(() {
          _state.lastMcc = log.transaction.merchantCategoryCode;
          _state.lastMerchant = log.transaction.merchantName;
          _state.lastCategory = log.categoryLabel;
          _state.financialKgToday += log.kgCo2e;
          _state.financialHistory = [
            ..._state.financialHistory.skip(1),
            log.kgCo2e.clamp(0, 50),
          ];
          if (_state.privacyShieldEnabled) _state.eventsBlocked++;
        });
      },
    );

    // Fire a random simulated transaction every 9 s
    _txTicker = Timer.periodic(const Duration(seconds: 9), (_) {
      if (!mounted) return;
      final t = _sampleTransactions[_rng.nextInt(_sampleTransactions.length)];
      _txService.ingestWebhookPayload(PlaidTransaction(
        transactionId: 'sim-${DateTime.now().millisecondsSinceEpoch}',
        merchantCategoryCode: t.$1,
        merchantName: t.$2,
        amountUsd: t.$3,
        authorizedAt: DateTime.now(),
      ));
    });

    // ── Digital service ──────────────────────────────────────────────────────
    _deviceService = DeviceFootprintService(
      onFootprintCalculated: (result) {
        if (!mounted) return;
        setState(() {
          _state.batteryDelta = result.batteryEnergyKwh;
          _state.networkGb += _state.networkGb;
          _state.digitalKgToday += result.kgCo2e;
          _state.digitalHistory = [
            ..._state.digitalHistory.skip(1),
            result.kgCo2e.clamp(0, 0.5),
          ];
        });
      },
    );

    // Tick every 8 s with randomised OS readings
    _digitalTicker = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final snap = DeviceUsageSnapshot(
        bytesTransferred: {
          NetworkInterface.wifi:
              (_rng.nextDouble() * 200 * 1024 * 1024).roundToDouble(),
          NetworkInterface.cellular4g:
              (_rng.nextDouble() * 50 * 1024 * 1024).roundToDouble(),
          NetworkInterface.cellular5g: 0,
        },
        batteryDelta: 0.005 + _rng.nextDouble() * 0.015,
        batteryCapacityWh: 16.65,
        gridIntensityGramsPerKwh: _state.gridIntensity,
        windowStart: DateTime.now().subtract(const Duration(seconds: 8)),
        windowEnd: DateTime.now(),
      );
      _deviceService.calculate(snap);
      setState(() {
        _state.networkGb += (snap.bytesTransferred.values
                .fold(0.0, (a, b) => a + b)) /
            (1024 * 1024 * 1024);
      });
    });

    // Drift grid intensity to simulate Electricity Maps live feed
    _gridTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {
        _state.gridIntensity =
            (350 + _rng.nextDouble() * 200).clamp(200, 600);
      });
    });
  }

  @override
  void dispose() {
    _motionService.stop();
    _pulseController.dispose();
    _ringController.dispose();
    _digitalTicker?.cancel();
    _txTicker?.cancel();
    _gridTicker?.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(child: _buildTotalRing()),
              SliverToBoxAdapter(child: _buildPrivacyBanner()),
              SliverToBoxAdapter(child: _buildSectionLabel('01 — TRANSPORT')),
              SliverToBoxAdapter(child: _buildTransportCard()),
              SliverToBoxAdapter(child: _buildSectionLabel('02 — FINANCIAL')),
              SliverToBoxAdapter(child: _buildFinancialCard()),
              SliverToBoxAdapter(child: _buildSectionLabel('03 — DIGITAL DEVICE')),
              SliverToBoxAdapter(child: _buildDigitalCard()),
              SliverToBoxAdapter(child: _buildGridIntensityCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.emerald
                      .withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald
                          .withValues(alpha: 0.6 * _pulseController.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SENSOR TRACKER',
              style: TextStyle(
                color: AppTheme.emerald,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.emerald.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                    color: AppTheme.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Total CO₂ ring ────────────────────────────────────────────────────────

  Widget _buildTotalRing() {
    final total = _state.totalKgToday;
    const budget = 8.0; // kg/day budget
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _ringAnim,
              builder: (context, child) => SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _RingPainter(
                        fraction: (_ringAnim.value *
                                (total / budget).clamp(0, 1))
                            .toDouble(),
                        color: total > budget * 0.8
                            ? AppTheme.warning
                            : AppTheme.emerald,
                        trackColor:
                            AppTheme.emerald.withValues(alpha: 0.1),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'kg CO₂\ntoday',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Automated Pipelines',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 10),
                  _PipelineRow(
                    label: 'Transport',
                    value: _state.transportKgToday,
                    color: AppTheme.emerald,
                    fraction:
                        (_state.transportKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  _PipelineRow(
                    label: 'Financial',
                    value: _state.financialKgToday,
                    color: AppTheme.lime,
                    fraction:
                        (_state.financialKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  _PipelineRow(
                    label: 'Digital',
                    value: _state.digitalKgToday,
                    color: const Color(0xFF818CF8),
                    fraction:
                        (_state.digitalKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily budget: ${budget.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Privacy banner ────────────────────────────────────────────────────────

  Widget _buildPrivacyBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: GlassCard(
        borderColor: _state.privacyShieldEnabled
            ? AppTheme.emerald.withValues(alpha: 0.4)
            : AppTheme.warning.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _state.privacyShieldEnabled
                  ? Icons.shield_outlined
                  : Icons.gpp_bad_outlined,
              color: _state.privacyShieldEnabled
                  ? AppTheme.emerald
                  : AppTheme.warning,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _state.privacyShieldEnabled
                        ? 'Privacy Shield ON — raw data stays on device'
                        : 'Privacy Shield OFF — raw data may be sent',
                    style: TextStyle(
                      color: _state.privacyShieldEnabled
                          ? AppTheme.emerald
                          : AppTheme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Only kg CO₂e figures are transmitted  •  ${_state.eventsBlocked} raw events blocked',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: _state.privacyShieldEnabled,
              onChanged: (v) =>
                  setState(() => _state.privacyShieldEnabled = v),
              activeThumbColor: AppTheme.emerald,
              inactiveThumbColor: AppTheme.warning,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Divider(
                  color: AppTheme.emerald.withValues(alpha: 0.15),
                  thickness: 1)),
        ],
      ),
    );
  }

  // ── Transport card ────────────────────────────────────────────────────────

  Widget _buildTransportCard() {
    final modeData = {
      TransportMode.automotive: (
        'Driving',
        Icons.directions_car,
        AppTheme.warning
      ),
      TransportMode.cycling: (
        'Cycling',
        Icons.directions_bike,
        AppTheme.lime
      ),
      TransportMode.walking: (
        'Walking',
        Icons.directions_walk,
        AppTheme.emerald
      ),
      TransportMode.stationary: (
        'Stationary',
        Icons.pause_circle_outline,
        AppTheme.textSecondary
      ),
      TransportMode.unknown: (
        'Unknown',
        Icons.device_unknown_outlined,
        AppTheme.textSecondary
      ),
    };
    final info = modeData[_state.transportMode]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(info.$2, color: info.$3, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.$1,
                        style: TextStyle(
                            color: info.$3,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Current detected mode',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info.$3.withValues(
                          alpha: 0.4 + 0.6 * _pulseController.value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox('Distance', '${_state.transportDistanceKm.toStringAsFixed(1)} km', AppTheme.emerald),
                const SizedBox(width: 10),
                _MetricBox('CO₂ today', '${_state.transportKgToday.toStringAsFixed(3)} kg', AppTheme.lime),
                const SizedBox(width: 10),
                _MetricBox('Factor', '171 g/km', AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            _buildSparkline(_state.transportHistory, AppTheme.emerald),
            const SizedBox(height: 8),
            _SourceBadge(label: 'CMMotionActivityManager / Activity Recognition'),
          ],
        ),
      ),
    );
  }

  // ── Financial card ────────────────────────────────────────────────────────

  Widget _buildFinancialCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card_outlined,
                    color: AppTheme.lime, size: 26),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Transaction',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lime.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.lime.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state.lastMerchant,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text('MCC ${_state.lastMcc} — ${_state.lastCategory}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${_state.financialKgToday.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                        color: AppTheme.lime,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSparkline(_state.financialHistory, AppTheme.lime),
            const SizedBox(height: 8),
            _SourceBadge(label: 'Plaid Webhook → MCC → Climatiq spend factor'),
          ],
        ),
      ),
    );
  }

  // ── Digital card ──────────────────────────────────────────────────────────

  Widget _buildDigitalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.phone_android_outlined,
                    color: Color(0xFF818CF8), size: 26),
                SizedBox(width: 12),
                Text('Device Footprint',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                    'Network',
                    '${_state.networkGb.toStringAsFixed(2)} GB',
                    const Color(0xFF818CF8)),
                const SizedBox(width: 10),
                _MetricBox(
                    'Battery',
                    '${(_state.batteryDelta * 1000).toStringAsFixed(1)} Wh',
                    AppTheme.lime),
                const SizedBox(width: 10),
                _MetricBox('CO₂ today',
                    '${_state.digitalKgToday.toStringAsFixed(4)} kg',
                    const Color(0xFF818CF8)),
              ],
            ),
            const SizedBox(height: 14),
            _buildSparkline(
                _state.digitalHistory, const Color(0xFF818CF8)),
            const SizedBox(height: 8),
            _SourceBadge(
                label:
                    'BatteryManager + NetworkStatsManager → 0.06 kWh/GB (Wi-Fi)'),
          ],
        ),
      ),
    );
  }

  // ── Grid intensity card ───────────────────────────────────────────────────

  Widget _buildGridIntensityCard() {
    final intensity = _state.gridIntensity;
    final Color intensityColor = intensity < 300
        ? AppTheme.emerald
        : intensity < 450
            ? AppTheme.lime
            : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GlassCard(
        borderColor: intensityColor.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bolt_outlined, color: intensityColor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Grid Carbon Intensity',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${intensity.toStringAsFixed(0)} gCO₂/kWh',
                        style: TextStyle(
                            color: intensityColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: intensityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          intensity < 300
                              ? 'CLEAN'
                              : intensity < 450
                                  ? 'MODERATE'
                                  : 'DIRTY',
                          style: TextStyle(
                              color: intensityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SourceBadge(label: 'Electricity Maps API', compact: true),
          ],
        ),
      ),
    );
  }

  // ── Sparkline ─────────────────────────────────────────────────────────────

  Widget _buildSparkline(List<double> data, Color color) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 50,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          minY: 0,
          maxY: max > 0 ? max * 1.3 : 1,
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double fraction;
  const _PipelineRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11)),
            const Spacer(),
            Text('${value.toStringAsFixed(3)} kg',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  final bool compact;
  const _SourceBadge({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9.5,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  const _RingPainter(
      {required this.fraction,
      required this.color,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
