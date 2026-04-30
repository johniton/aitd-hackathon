import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/activity_model.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../config/app_env.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../auth_screen.dart';
import 'squad_screen.dart';
import 'wrapped_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _error = '';
  late UserModel _currentUser;
  List<ActivityModel> _activities = const [];
  String _aiSummary = '';
  List<String> _aiSuggestions = const [];
  final PageController _whatIfController = PageController(
    viewportFraction: 0.9,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getActivities(limit: 100),
      ]);
      final user = results[0] as UserModel;
      final activities = results[1] as List<ActivityModel>;
      setState(() {
        _currentUser = user;
        _activities = activities;
        _isLoading = false;
      });
      _loadAiInsights();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _co2Generated => _activities
      .where((a) => !a.isSaving)
      .fold(0.0, (sum, a) => sum + a.co2Kg);

  double get _co2Saved =>
      _activities.where((a) => a.isSaving).fold(0.0, (sum, a) => sum + a.co2Kg);

  String get _topEmissionCategory {
    final totals = <ActivityCategory, double>{};
    for (final a in _activities.where((a) => !a.isSaving)) {
      totals[a.category] = (totals[a.category] ?? 0) + a.co2Kg;
    }
    if (totals.isEmpty) return 'None';
    final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return switch (top) {
      ActivityCategory.transport => 'Transport',
      ActivityCategory.food => 'Food',
      ActivityCategory.energy => 'Energy',
      ActivityCategory.waste => 'Waste',
    };
  }

  Future<void> _loadAiInsights() async {
    final apiKey = AppEnv.groqApiKey;
    if (apiKey.isEmpty) {
      setState(() {
        _aiSummary =
            'Add GROQ_API_KEY in .env to unlock personalized AI analysis.';
        _aiSuggestions = _fallbackSuggestions();
      });
      return;
    }

    setState(() => _isAnalyzing = true);
    final prompt =
        '''
You are an eco coach for an Indian user.
Given:
- emitted_co2_kg: ${_co2Generated.toStringAsFixed(3)}
- saved_co2_kg: ${_co2Saved.toStringAsFixed(3)}
- top_emission_category: $_topEmissionCategory
- city: ${_currentUser.city}

Return ONLY JSON:
{
  "summary": "2 short sentences personalized to this user",
  "suggestions": [
    "specific action 1 with impact",
    "specific action 2 with impact",
    "specific action 3 with impact"
  ]
}
Keep suggestions practical for Goa/India.
''';

    try {
      final res = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'temperature': 0.3,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final content =
            (((body['choices'] as List).first
                        as Map<String, dynamic>)['message']
                    as Map<String, dynamic>)['content']
                as String;
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        final suggestions = (parsed['suggestions'] as List? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(3)
            .toList();
        if (!mounted) return;
        setState(() {
          _aiSummary = (parsed['summary'] as String?)?.trim() ?? '';
          _aiSuggestions = suggestions.isEmpty
              ? _fallbackSuggestions()
              : suggestions;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _aiSummary = 'AI analysis is temporarily unavailable.';
          _aiSuggestions = _fallbackSuggestions();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiSummary = 'AI analysis is temporarily unavailable.';
        _aiSuggestions = _fallbackSuggestions();
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  List<String> _fallbackSuggestions() {
    return [
      'Replace 2 short car trips each week with walking or bus to reduce transport emissions.',
      'Switch one meat-heavy meal to a veg meal daily to cut food footprint significantly.',
      'Run AC at 24-26°C and use fans first to reduce home electricity carbon impact.',
    ];
  }

  List<_WhatIfCardData> _buildWhatIfCards() {
    final generated = _co2Generated;
    return [
      _WhatIfCardData(
        title: 'What If: 3 Car Trips to Bus',
        impactKg: generated * 0.12,
        detail:
            'Switching just 3 weekly short car rides to bus lowers transport emissions significantly.',
      ),
      _WhatIfCardData(
        title: 'What If: 4 Meat Meals to Veg',
        impactKg: generated * 0.10,
        detail:
            'Replacing 4 meat-heavy meals per week cuts food footprint while staying practical.',
      ),
      _WhatIfCardData(
        title: 'What If: AC +1°C + Fan First',
        impactKg: generated * 0.08,
        detail:
            'Raising AC setpoint and using fan-first habit can reduce daily electricity emissions.',
      ),
    ];
  }

  @override
  void dispose() {
    _whatIfController.dispose();
    super.dispose();
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
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppTheme.accentRed),
              ),
              TextButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final currentUser = _currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.emeraldGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentUser.avatarInitials,
                        style: const TextStyle(
                          color: AppTheme.bg1,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '📍 ${currentUser.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '#${currentUser.rank}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.emerald,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'city rank',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      '🌿',
                      '${currentUser.totalCo2Saved.toStringAsFixed(0)} kg',
                      'CO₂ Saved',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      '🪙',
                      '${currentUser.greenCoins.toInt()}',
                      'GreenCoins',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      '🔥',
                      '${currentUser.streakDays}d',
                      'Streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      '🫁',
                      '${_co2Generated.toStringAsFixed(2)} kg',
                      'CO₂ Generated',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      '🌍',
                      _co2Generated < 1
                          ? '≈ ${(_co2Generated * 10).toStringAsFixed(1)} AC hrs'
                          : _co2Generated < 20
                          ? '≈ ${(_co2Generated / 8).toStringAsFixed(1)} ferry trips'
                          : '≈ ${(_co2Generated / 21).toStringAsFixed(1)} home-days',
                      'Real-life Equivalent',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'AI Carbon Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: _isAnalyzing
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.emerald,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Generating personalized insights...',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _aiSummary.isEmpty
                                ? 'Your emissions are led by $_topEmissionCategory. Focused daily changes can lower your footprint.'
                                : _aiSummary,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._aiSuggestions.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(color: AppTheme.emerald),
                                  ),
                                  Expanded(
                                    child: Text(
                                      s,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What-If Simulator',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: PageView(
                  controller: _whatIfController,
                  children: _buildWhatIfCards()
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GlassCard(
                            borderColor: AppTheme.emerald.withValues(
                              alpha: 0.35,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.title,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Potential cut: ${w.impactKg.toStringAsFixed(2)} kg CO₂/week',
                                  style: const TextStyle(
                                    color: AppTheme.emerald,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  w.detail,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Links',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _NavTile(
                Icons.group,
                'My Squad',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SquadScreen()),
                ),
              ),
              _NavTile(
                Icons.auto_awesome,
                'My Wrapped',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WrappedScreen()),
                ),
              ),
              _NavTile(Icons.settings, 'Settings', () {}),
              _NavTile(Icons.logout, 'Sign Out', () async {
                await ApiService.clearUserId();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
                  );
                }
              }, danger: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatIfCardData {
  final String title;
  final double impactKg;
  final String detail;
  const _WhatIfCardData({
    required this.title,
    required this.impactKg,
    required this.detail,
  });
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatBox(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _NavTile(this.icon, this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.warning : AppTheme.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
