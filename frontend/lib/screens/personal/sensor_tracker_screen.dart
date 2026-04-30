import 'dart:async';
import 'dart:math' show pi, Random;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../sensors/sensors.dart';
import '../../config/app_config.dart';
import '../../sensors/real_sensors_service.dart';

// ── Sensor state model ───────────────────────────────────────────────────────

class _SensorState {
  // Transport
  TransportMode transportMode = TransportMode.stationary;
  double transportKgToday = 0.0;
  double transportDistanceKm = 0.0;
  double transportSpeedKmh = 0.0;
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

  // Real Sensors
  double accelX = 0.0, accelY = 0.0, accelZ = 0.0;
  double gyroX = 0.0, gyroY = 0.0, gyroZ = 0.0;
  int steps = 0;
  String pedStatus = "Unknown";
  int batteryLevel = 100;

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
  bool _demoMode = false;

  late MotionActivityService _motionService;
  late DeviceFootprintService _deviceService;
  late TransactionSensorService _transactionService;

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  Timer? _gridTicker;
  RealSensorsService? _realSensors;

  void _startPipelines() {
    _motionService = MotionActivityService(
      isDemoMode: _demoMode,
      emitIntervalSeconds: _demoMode ? 5 : 15,
      onCarbonEstimate: (est) {
        if (!mounted) return;
        setState(() {
          _state.transportMode = est.mode;
          _state.transportSpeedKmh = est.speedKmh;
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
      onModeChanged: (mode, speedKmh) {
        if (!mounted) return;
        setState(() {
          _state.transportMode = mode;
          _state.transportSpeedKmh = speedKmh;
        });
      },
    );
    _motionService.start();

    _transactionService = TransactionSensorService(
      isDemoMode: _demoMode,
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
    if (_demoMode) {
      _transactionService.startSimulation(intervalSeconds: 10);
    }

    _deviceService = DeviceFootprintService(
      isDemoMode: _demoMode,
      intervalSeconds: _demoMode ? 8 : 30,
      onFootprintCalculated: (result) {
        if (!mounted) return;
        setState(() {
          _state.batteryDelta = result.batteryEnergyKwh;
          _state.networkGb += result.networkBytes / (1024 * 1024 * 1024);
          _state.digitalKgToday += result.kgCo2e;
          _state.digitalHistory = [
            ..._state.digitalHistory.skip(1),
            result.kgCo2e.clamp(0, 0.5),
          ];
        });
      },
    );
    _deviceService.start();
  }

  void _stopPipelines() {
    _motionService.stop();
    _deviceService.stop();
    _transactionService.stopSimulation();
  }

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
    _ringAnim = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();

    _startPipelines();

    // ── Grid Intensity ───────────────────────────────────────────────────────
    final gridService = GridIntensityService(
      apiKey: AppConfig.electricityMapsApiKey,
    );
    _gridTicker = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final intensity = await gridService.fetchIntensity();
      if (!mounted) return;
      setState(() {
        _state.gridIntensity = intensity;
      });
    });
    // Initial fetch
    gridService.fetchIntensity().then((val) {
      if (mounted) setState(() => _state.gridIntensity = val);
    });

    // ── Real Sensors Service ─────────────────────────────────────────────────
    _realSensors = RealSensorsService(
      onAccelEvent: (e) {
        if (!mounted) return;
        setState(() {
          _state.accelX = e.x;
          _state.accelY = e.y;
          _state.accelZ = e.z;
        });
      },
      onGyroEvent: (e) {
        if (!mounted) return;
        setState(() {
          _state.gyroX = e.x;
          _state.gyroY = e.y;
          _state.gyroZ = e.z;
        });
      },
      onStepCount: (e) {
        if (!mounted) return;
        setState(() => _state.steps = e.steps);
      },
      onPedestrianStatus: (e) {
        if (!mounted) return;
        setState(() => _state.pedStatus = e.status);
      },
      onBatteryState: (s) {},
      onBatteryLevel: (l) {
        if (!mounted) return;
        setState(() => _state.batteryLevel = l);
      },
    );
    if (!kIsWeb) _realSensors!.start();
  }

  @override
  void dispose() {
    _stopPipelines();
    _pulseController.dispose();
    _ringController.dispose();
    _gridTicker?.cancel();
    _realSensors?.stop();
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
              SliverToBoxAdapter(
                child: _buildSectionLabel('03 — DIGITAL DEVICE'),
              ),
              SliverToBoxAdapter(child: _buildDigitalCard()),
              SliverToBoxAdapter(child: _buildGridIntensityCard()),
              SliverToBoxAdapter(
                child: _buildSectionLabel('04 — RAW HARDWARE SENSORS'),
              ),
              SliverToBoxAdapter(child: _buildRawSensorsCard()),
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
                  color: AppTheme.emerald.withValues(
                    alpha: 0.4 + 0.6 * _pulseController.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald.withValues(
                        alpha: 0.6 * _pulseController.value,
                      ),
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
                  color: AppTheme.emerald.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: (_demoMode ? AppTheme.warning : AppTheme.lime)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_demoMode ? AppTheme.warning : AppTheme.lime)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _demoMode ? 'DEMO' : 'REAL',
                style: TextStyle(
                  color: _demoMode ? AppTheme.warning : AppTheme.lime,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: _demoMode,
              onChanged: (v) {
                setState(() => _demoMode = v);
                _stopPipelines();
                _startPipelines();
              },
              activeThumbColor: AppTheme.warning,
              inactiveThumbColor: AppTheme.lime,
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
                        fraction:
                            (_ringAnim.value * (total / budget).clamp(0, 1))
                                .toDouble(),
                        color: total > budget * 0.8
                            ? AppTheme.warning
                            : AppTheme.emerald,
                        trackColor: AppTheme.emerald.withValues(alpha: 0.1),
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
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
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
                  const Text(
                    'Automated Pipelines',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PipelineRow(
                    label: 'Transport',
                    value: _state.transportKgToday,
                    color: AppTheme.emerald,
                    fraction: (_state.transportKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  _PipelineRow(
                    label: 'Financial',
                    value: _state.financialKgToday,
                    color: AppTheme.lime,
                    fraction: (_state.financialKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  _PipelineRow(
                    label: 'Digital',
                    value: _state.digitalKgToday,
                    color: AppTheme.accentIndigo,
                    fraction: (_state.digitalKgToday / budget).clamp(0, 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily budget: ${budget.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
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
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _state.privacyShieldEnabled,
              onChanged: (v) => setState(() => _state.privacyShieldEnabled = v),
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
              thickness: 1,
            ),
          ),
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
        AppTheme.warning,
      ),
      TransportMode.cycling: ('Cycling', Icons.directions_bike, AppTheme.lime),
      TransportMode.walking: (
        'Walking',
        Icons.directions_walk,
        AppTheme.emerald,
      ),
      TransportMode.stationary: (
        'Stationary',
        Icons.pause_circle_outline,
        AppTheme.textSecondary,
      ),
      TransportMode.unknown: (
        'Unknown',
        Icons.device_unknown_outlined,
        AppTheme.textSecondary,
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
                    Text(
                      info.$1,
                      style: TextStyle(
                        color: info.$3,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Current detected mode',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
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
                        alpha: 0.4 + 0.6 * _pulseController.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                  'Distance',
                  '${_state.transportDistanceKm.toStringAsFixed(1)} km',
                  AppTheme.emerald,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  'CO₂ today',
                  '${_state.transportKgToday.toStringAsFixed(3)} kg',
                  AppTheme.lime,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  'Speed',
                  '${_state.transportSpeedKmh.toStringAsFixed(1)} km/h',
                  AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSparkline(_state.transportHistory, AppTheme.emerald),
            const SizedBox(height: 8),
            _SourceBadge(
              label: 'CMMotionActivityManager / Activity Recognition',
            ),
          ],
        ),
      ),
    );
  }

  // ── Demo transactions (Indian market) ────────────────────────────────────

  static const _demoTransactions = [
    (5499, 'Zomato', 320.0),
    (5541, 'IOCL Petrol Pump', 1500.0),
    (4121, 'Ola Cab', 210.0),
    (5411, 'D-Mart', 850.0),
    (4112, 'IRCTC', 450.0),
    (4511, 'IndiGo Airlines', 4200.0),
    (4111, 'Delhi Metro', 40.0),
    (5999, 'Flipkart', 1299.0),
    (5812, 'Chai Point', 180.0),
    (4900, 'BESCOM Electricity', 1200.0),
  ];

  void _simulateTransaction() {
    final rng = Random();
    final demo = _demoTransactions[rng.nextInt(_demoTransactions.length)];
    _transactionService.ingestWebhookPayload(
      PlaidTransaction(
        transactionId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        merchantCategoryCode: demo.$1,
        merchantName: demo.$2,
        amountInr: demo.$3,
        authorizedAt: DateTime.now(),
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
                const Icon(
                  Icons.credit_card_outlined,
                  color: AppTheme.lime,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Transaction',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _state.lastMerchant == '—'
                            ? 'No transactions yet'
                            : _state.lastMerchant,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  color: AppTheme.lime.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _state.lastMcc == 0
                          ? 'Tap "Simulate" to demo a transaction'
                          : 'MCC ${_state.lastMcc} — ${_state.lastCategory}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_state.financialKgToday.toStringAsFixed(2)} kg CO₂',
                    style: const TextStyle(
                      color: AppTheme.lime,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSparkline(_state.financialHistory, AppTheme.lime),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _simulateTransaction,
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Simulate UPI Transaction'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.lime,
                  side: BorderSide(color: AppTheme.lime.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SourceBadge(
              label:
                  'UPI Webhook → MCC → India-calibrated CO₂ factors (MoEFCC/CEEW)',
            ),
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
            Row(
              children: [
                const Icon(
                  Icons.phone_android_outlined,
                  color: AppTheme.accentIndigo,
                  size: 26,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Device Footprint',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox(
                  'Network',
                  '${_state.networkGb.toStringAsFixed(2)} GB',
                  AppTheme.accentIndigo,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  'Battery',
                  '${(_state.batteryDelta * 1000).toStringAsFixed(1)} Wh',
                  AppTheme.lime,
                ),
                const SizedBox(width: 10),
                _MetricBox(
                  'CO₂ today',
                  '${_state.digitalKgToday.toStringAsFixed(4)} kg',
                  AppTheme.accentIndigo,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSparkline(_state.digitalHistory, AppTheme.accentIndigo),
            const SizedBox(height: 8),
            _SourceBadge(
              label:
                  'BatteryManager + NetworkStatsManager → 0.06 kWh/GB (Wi-Fi)',
            ),
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
                  const Text(
                    'Live Grid Carbon Intensity',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${intensity.toStringAsFixed(0)} gCO₂/kWh',
                          style: TextStyle(
                            color: intensityColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                            letterSpacing: 1.2,
                          ),
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

  // ── Raw Sensors Card ──────────────────────────────────────────────────────

  Widget _buildRawSensorsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.developer_board_outlined,
                  color: AppTheme.accentAmber,
                  size: 26,
                ),
                SizedBox(width: 12),
                Text(
                  'Hardware Telemetry',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricBox('Steps', '${_state.steps}', AppTheme.accentAmber),
                const SizedBox(width: 10),
                _MetricBox('Motion', _state.pedStatus, AppTheme.accentAmber),
                const SizedBox(width: 10),
                _MetricBox(
                  'Battery',
                  '${_state.batteryLevel}%',
                  AppTheme.accentAmber,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Accelerometer (m/s²)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'X: ${_state.accelX.toStringAsFixed(2)} | Y: ${_state.accelY.toStringAsFixed(2)} | Z: ${_state.accelZ.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accentAmber,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Live Gyroscope (rad/s)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'X: ${_state.gyroX.toStringAsFixed(2)} | Y: ${_state.gyroY.toStringAsFixed(2)} | Z: ${_state.gyroZ.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accentAmber,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _SourceBadge(
              label:
                  'Android SensorManager (Accelerometer, Gyroscope, Pedometer, Battery)',
            ),
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
                  colors: [color.withValues(alpha: 0.25), Colors.transparent],
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
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
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
  const _PipelineRow({
    required this.label,
    required this.value,
    required this.color,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(3)} kg',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 9.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

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
