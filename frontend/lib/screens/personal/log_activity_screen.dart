import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../config/app_env.dart';
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

  // Receipt photo tab state
  XFile? _receiptImage;
  bool _scanningReceipt = false;
  Map<String, dynamic>? _receiptResult;

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
                      SnackBar(backgroundColor: AppTheme.accentRed, content: Text('Error: $e')),
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

  Future<void> _pickAndScanReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;

    setState(() {
      _receiptImage = file;
      _scanningReceipt = true;
      _receiptResult = null;
    });

    try {
      final bytes = await File(file.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = '''You are a carbon footprint analyser for an Indian eco app called GoaGreen.
Analyse this receipt/bill image and return ONLY a valid JSON object with these exact keys:
{
  "merchant": "<shop or restaurant name>",
  "category": "<one of: food, transport, energy, shopping, groceries>",
  "items": ["<item1>", "<item2>"],
  "total_inr": <number>,
  "co2_kg": <estimated kg CO2e as a number>,
  "is_eco": <true if this purchase is eco-friendly, false otherwise>,
  "coins": <GreenCoins to award: 20 if eco, 5 if not>,
  "insight": "<one sentence eco insight about this purchase in Indian context>"
}
Base your CO2 estimate on typical Indian emission factors. Be concise and accurate.
Return ONLY the JSON, no markdown, no explanation.''';

      final response = await http.post(
        Uri.parse('${AppEnv.sneakyApiUrl}/api/analyze/base64'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'imageBase64': base64Image,
          'imageName': 'receipt.jpg',
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawText = (body['response'] as String).trim();
        // Strip markdown fences if present
        final jsonText = rawText.replaceAll(RegExp(r'^```json?\s*', multiLine: true), '').replaceAll(RegExp(r'```$', multiLine: true), '').trim();
        final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
        setState(() {
          _receiptResult = parsed;
          _scanningReceipt = false;
        });
      } else {
        throw Exception('Sneaky API error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _scanningReceipt = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRed, content: Text('Scan failed: $e')),
        );
      }
    }
  }

  Future<void> _logReceiptActivity() async {
    final r = _receiptResult;
    if (r == null) return;
    try {
      await ApiService.logActivity(
        r['merchant'] as String? ?? 'Receipt scan',
        r['category'] as String? ?? 'shopping',
        (r['co2_kg'] as num?)?.toDouble() ?? 0.0,
        r['is_eco'] as bool? ?? false,
      );
      if (mounted) {
        final coins = r['coins'] as int? ?? 5;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emerald,
            content: Text('Logged! +$coins GreenCoins 🌱'),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _receiptImage = null;
          _receiptResult = null;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.accentRed, content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildPhotoTab() {
    final result = _receiptResult;

    if (_scanningReceipt) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.emerald),
            const SizedBox(height: 20),
            Text('Analysing receipt with AI...', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            if (_receiptImage != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_receiptImage!.path), height: 160, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      );
    }

    if (result != null) {
      final co2 = (result['co2_kg'] as num?)?.toDouble() ?? 0.0;
      final isEco = result['is_eco'] as bool? ?? false;
      final coins = result['coins'] as int? ?? 5;
      final items = (result['items'] as List?)?.cast<String>() ?? [];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_receiptImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_receiptImage!.path), height: 80, width: 80, fit: BoxFit.cover),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result['merchant'] as String? ?? 'Receipt', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(result['category'] as String? ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
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
                          color: (isEco ? AppTheme.emerald : AppTheme.warning).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isEco ? '✅ Eco Purchase' : '⚠️ Carbon Added',
                          style: TextStyle(color: isEco ? AppTheme.emerald : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${co2.toStringAsFixed(3)} kg CO₂', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(EmissionFactors.analogy(co2), style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items Detected', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.emerald)),
                          Expanded(child: Text(item, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (result['insight'] != null)
              GlassCard(
                child: Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(result['insight'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Log Activity  +$coins GreenCoins',
              onPressed: _logReceiptActivity,
              icon: Icons.check,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() { _receiptImage = null; _receiptResult = null; }),
              child: const Text('Scan another receipt', style: TextStyle(color: AppTheme.emerald)),
            ),
          ],
        ),
      );
    }

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
                decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long, color: AppTheme.emerald, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Snap your receipt', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('AI will read your bill and calculate your carbon footprint + award GreenCoins automatically', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GradientButton(label: 'Take Photo', onPressed: () => _pickAndScanReceipt(ImageSource.camera), icon: Icons.camera_alt, width: double.infinity),
              const SizedBox(height: 12),
              TextButton(onPressed: () => _pickAndScanReceipt(ImageSource.gallery), child: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.emerald))),
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
