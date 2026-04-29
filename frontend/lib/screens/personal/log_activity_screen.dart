import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../../data/emission_factors.dart';
import '../../models/activity_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Text tab
  int _selectedCategory = 0;
  int _selectedOption = 0;
  double _co2Result = 0;
  String _analogy = '';

  // Photo tab
  XFile? _pickedImage;
  bool _analyzing = false;
  Map<String, dynamic>? _receiptResult;

  // Location tab
  bool _tracking = false;
  Position? _startPos;
  Position? _endPos;
  double _distanceKm = 0;
  String _selectedTransport = 'bus';
  StreamSubscription<Position>? _posStream;
  DateTime? _trackStart;

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

  List<String> get _options {
    switch (_selectedCategory) {
      case 0: return _transportOptions;
      case 1: return _foodOptions;
      case 2: return _energyOptions;
      default: return _wasteOptions;
    }
  }

  List<double> get _co2Values {
    switch (_selectedCategory) {
      case 0: return _transportCo2;
      case 1: return _foodCo2;
      case 2: return _energyCo2;
      default: return _wasteCo2;
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
    _posStream?.cancel();
    super.dispose();
  }

  // ── Photo tab ──────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() {
      _pickedImage = file;
      _analyzing = true;
      _receiptResult = null;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    // Simulate receipt OCR — in production this hits a backend endpoint
    setState(() {
      _analyzing = false;
      _receiptResult = {
        'title': 'Grocery purchase',
        'category': ActivityCategory.food,
        'co2Kg': 1.2,
        'analogy': EmissionFactors.analogy(1.2),
        'items': ['Vegetables 0.3kg', 'Dairy 0.5kg', 'Packaged snacks 0.4kg'],
      };
    });
  }

  void _logReceiptActivity() {
    if (_receiptResult == null) return;
    context.read<AppState>().logActivity(
      title: _receiptResult!['title'],
      category: _receiptResult!['category'],
      co2Kg: _receiptResult!['co2Kg'],
      isSaving: false,
    );
    _showConfirmation(context, _receiptResult!['co2Kg'] == 0.0 ? 20 : 5);
  }

  // ── Location tab ───────────────────────────────────────────────────────────

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return false;
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _startTracking() async {
    if (!await _ensureLocationPermission()) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _tracking = true;
      _startPos = pos;
      _endPos = null;
      _distanceKm = 0;
      _trackStart = DateTime.now();
    });
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      if (_startPos != null) {
        final d = Geolocator.distanceBetween(
          _startPos!.latitude, _startPos!.longitude,
          pos.latitude, pos.longitude,
        );
        setState(() => _distanceKm = d / 1000.0);
      }
    });
  }

  Future<void> _stopTracking() async {
    await _posStream?.cancel();
    _posStream = null;
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _tracking = false;
      _endPos = pos;
    });
  }

  void _logLocationActivity() {
    if (_distanceKm <= 0) return;
    final factor = EmissionFactors.transportKgPerKm[_selectedTransport] ?? 0.089;
    final co2 = factor * _distanceKm;
    final title = '${_selectedTransport[0].toUpperCase()}${_selectedTransport.substring(1)} journey ${_distanceKm.toStringAsFixed(1)} km';
    context.read<AppState>().logActivity(
      title: title,
      category: ActivityCategory.transport,
      co2Kg: co2,
      isSaving: co2 == 0,
    );
    _showConfirmation(context, co2 == 0 ? 20 : 5);
    setState(() {
      _startPos = null;
      _endPos = null;
      _distanceKm = 0;
    });
  }

  void _showConfirmation(BuildContext ctx, int coins) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: AppTheme.emerald,
      content: Text('Logged! +$coins GreenCoins 🌱'),
      duration: const Duration(seconds: 2),
    ));
    Navigator.pop(ctx);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
            Tab(icon: Icon(Icons.text_fields), text: 'Manual'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Receipt'),
            Tab(icon: Icon(Icons.location_on), text: 'Track'),
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
                    Expanded(child: Text(e.value, style: TextStyle(color: selected ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 14))),
                    Text(
                      '${_co2Values[e.key].toStringAsFixed(3)} kg',
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
                        style: TextStyle(color: _co2Result == 0 ? AppTheme.emerald : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${_co2Result.toStringAsFixed(3)} kg CO₂', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_analogy, style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Log  +${_co2Result == 0 ? 20 : 5} coins',
            onPressed: () {
              final cat = [ActivityCategory.transport, ActivityCategory.food, ActivityCategory.energy, ActivityCategory.waste][_selectedCategory];
              context.read<AppState>().logActivity(
                title: _options[_selectedOption],
                category: cat,
                co2Kg: _co2Result,
                isSaving: _co2Result == 0 || [0, 1].contains(_selectedCategory) && _co2Result < 1.0,
              );
              _showConfirmation(context, _co2Result == 0 ? 20 : 5);
            },
            icon: Icons.check,
            width: double.infinity,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_pickedImage == null) ...[
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long, color: AppTheme.emerald, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Snap your receipt', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('We\'ll calculate your food & shopping carbon footprint automatically', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GradientButton(label: 'Take Photo', onPressed: () => _pickImage(ImageSource.camera), icon: Icons.camera_alt, width: double.infinity),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: AppTheme.emerald),
                      label: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.emerald)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.emerald.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_analyzing) ...[
            GlassCard(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_pickedImage!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppTheme.emerald),
                  const SizedBox(height: 16),
                  const Text('Analysing receipt…', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const Text('Calculating carbon footprint', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ] else if (_receiptResult != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_pickedImage!.path), height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  const Text('Receipt Scanned ✅', style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...(_receiptResult!['items'] as List<String>).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  )),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    children: [
                      const Expanded(child: Text('Total CO₂', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                      Text('${(_receiptResult!['co2Kg'] as double).toStringAsFixed(2)} kg', style: const TextStyle(color: AppTheme.warning, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_receiptResult!['analogy'], style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                  const SizedBox(height: 16),
                  GradientButton(label: 'Log Activity  +5 coins', onPressed: _logReceiptActivity, icon: Icons.check, width: double.infinity),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => setState(() { _pickedImage = null; _receiptResult = null; }),
                      child: const Text('Scan another', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    final elapsed = _tracking && _trackStart != null
        ? DateTime.now().difference(_trackStart!)
        : Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: (_tracking ? AppTheme.emerald : AppTheme.cardBg).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tracking ? Icons.location_searching : Icons.location_on,
                    color: _tracking ? AppTheme.emerald : AppTheme.textSecondary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _tracking ? 'Tracking your journey…' : _endPos != null ? 'Journey complete!' : 'Auto-detect journey',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_tracking) ...[
                  Text(
                    '${_distanceKm.toStringAsFixed(2)} km  •  ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s',
                    style: const TextStyle(color: AppTheme.emerald, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Stop Tracking',
                    onPressed: _stopTracking,
                    icon: Icons.stop,
                    width: double.infinity,
                  ),
                ] else if (_endPos != null) ...[
                  Text('${_distanceKm.toStringAsFixed(2)} km recorded', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  const Text('Transport mode', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['bike', 'bus', 'auto', 'car'].map((t) {
                      final icons = {'bike': '🚲', 'bus': '🚌', 'auto': '🛺', 'car': '🚗'};
                      final sel = _selectedTransport == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTransport = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.emerald.withValues(alpha: 0.2) : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppTheme.emerald : Colors.transparent),
                          ),
                          child: Text('${icons[t]} $t', style: TextStyle(color: sel ? AppTheme.emerald : AppTheme.textSecondary, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  () {
                    final factor = EmissionFactors.transportKgPerKm[_selectedTransport] ?? 0.089;
                    final co2 = factor * _distanceKm;
                    return Text('≈ ${co2.toStringAsFixed(3)} kg CO₂  ${EmissionFactors.analogy(co2)}', style: const TextStyle(color: AppTheme.emerald, fontSize: 12));
                  }(),
                  const SizedBox(height: 16),
                  GradientButton(label: 'Log Journey  +5 coins', onPressed: _logLocationActivity, icon: Icons.check, width: double.infinity),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() { _endPos = null; _distanceKm = 0; }),
                    child: const Text('Discard', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ] else ...[
                  const Text('Tap to start tracking your route. We\'ll calculate transport emissions when you stop.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GradientButton(label: 'Start Tracking', onPressed: _startTracking, icon: Icons.play_arrow, width: double.infinity),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
