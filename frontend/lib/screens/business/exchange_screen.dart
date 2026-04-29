import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/static_data.dart';
import '../../services/tourism_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../data/carbon_action_tracker.dart';

class ExchangeScreen extends StatefulWidget {
  final TourismEngineController? tourismController;
  const ExchangeScreen({super.key, this.tourismController});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final CarbonActionTracker _actionTracker = CarbonActionTracker();
  List<CarbonActionItem> _actionItems = [];
  bool _isLoadingActions = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
    widget.tourismController?.addListener(_loadActions);
  }

  @override
  void dispose() {
    widget.tourismController?.removeListener(_loadActions);
    super.dispose();
  }

  Future<void> _loadActions() async {
    if (widget.tourismController == null) return;
    final cc = widget.tourismController!.carbonCreditAnalysis;
    if (cc == null || cc['action_plan'] == null) {
      if (mounted) setState(() => _isLoadingActions = false);
      return;
    }

    final sector = widget.tourismController!.sector.name;
    final List<dynamic> plan = cc['action_plan'];
    
    // Convert current plan to items
    List<CarbonActionItem> newItems = [];
    for (int i = 0; i < plan.length; i++) {
      String text = plan[i].toString();
      newItems.add(CarbonActionItem(
        id: '${sector}_step_$i',
        businessType: sector,
        actionText: text,
        stepNumber: 'Step ${i + 1} of ${plan.length}',
      ));
    }

    await _actionTracker.saveActions(newItems);
    final savedItems = await _actionTracker.getActionsForSector(sector);
    
    if (mounted) {
      setState(() {
        _actionItems = savedItems;
        _isLoadingActions = false;
      });
      _updateEcoScoreBonus(sector);
    }
  }

  Future<void> _updateEcoScoreBonus(String sector) async {
    double rate = await _actionTracker.calculateCompletionRate(sector);
    widget.tourismController?.updateActionPlanBonus(rate);
  }

  Future<void> _toggleAction(CarbonActionItem item, bool? val) async {
    if (val == true) {
      await _actionTracker.markComplete(item.id);
    } else {
      await _actionTracker.markIncomplete(item.id);
    }
    await _loadActions();
  }

  Future<void> _resetActions() async {
    if (widget.tourismController == null) return;
    await _actionTracker.resetPlan(widget.tourismController!.sector.name);
    await _loadActions();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tourismController != null) {
      return AnimatedBuilder(
        animation: widget.tourismController!,
        builder: (_, __) => _buildExchangeWithCC(context, widget.tourismController!),
      );
    }
    return _buildStaticExchange(context);
  }

  // ════════════════════════════════════════════════
  //  MAIN EXCHANGE + CARBON CREDIT SCREEN
  // ════════════════════════════════════════════════

  Widget _buildExchangeWithCC(BuildContext context, TourismEngineController c) {
    final matches = c.exchangeMatches();
    final cc = c.carbonCreditAnalysis;

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Exchange & Carbon Credits',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                    onPressed: () => _showAboutAnalysis(context),
                  )
                ],
              ),
              const SizedBox(height: 4),
              const Text('Trade waste into value & monetize your carbon footprint',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),

              // ═══════════════════════════════════════
              //  CARBON CREDIT ANALYSIS
              // ═══════════════════════════════════════

              // ── CTA / LOADING / RESULTS ──
              if (cc == null && !c.isLoadingCarbonCredit)
                GlassCard(
                  borderColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on, color: Color(0xFF6366F1), size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Carbon Credit Analysis', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                        'Find out if your business can SELL carbon credits or needs to BUY them. '
                        'Powered by India CCTS, global VCM market data, and real registry pricing.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text('Analyze My Carbon Credit Position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: c.generateCarbonCreditAnalysis,
                      ),
                    ),
                  ]),
                ),

              if (c.isLoadingCarbonCredit)
                GlassCard(
                  borderColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  child: Column(children: [
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Color(0xFF6366F1)),
                    const SizedBox(height: 16),
                    const Text('Analyzing your carbon credit position...',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Checking India CCTS • Verra VCS • Gold Standard • VCM pricing...',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 16),
                  ]),
                ),

              // ── RESULTS ──
              if (cc != null) ...[
                if (cc['analysis_confidence'] != null) _buildConfidenceBanner(cc['analysis_confidence']),
                const DisclaimerBanner(disclaimerKey: 'carbon_credit_disclaimer'),
                _buildVerdictCard(cc, context),
                const SizedBox(height: 12),
                _buildCreditOpportunities(cc),
                const SizedBox(height: 12),
                _buildActionPlan(cc),
                const SizedBox(height: 12),
                _buildIndiaSchemes(cc),
                const SizedBox(height: 12),
                _buildMarketInsight(cc),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-analyze Carbon Credits'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: c.isLoadingCarbonCredit ? null : c.generateCarbonCreditAnalysis,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ═══════════════════════════════════════
              //  CIRCULAR ECONOMY EXCHANGE
              // ═══════════════════════════════════════
              const Divider(color: AppTheme.textSecondary, height: 1),
              const SizedBox(height: 20),
              const Text('Circular Economy Exchange',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Connect with nearby businesses to trade waste into resources',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),

              ...matches.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(m.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${m.nearbyBusinesses} businesses nearby can use your waste',
                        style: const TextStyle(color: AppTheme.emerald, fontSize: 12)),
                    const SizedBox(height: 8),
                    GradientButton(label: 'Connect', onPressed: () {}, width: double.infinity),
                  ]),
                ),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  CARBON CREDIT SUB-WIDGETS
  // ════════════════════════════════════════════════

  Widget _buildVerdictCard(Map<String, dynamic> cc, BuildContext context) {
    final verdict = cc['verdict']?.toString() ?? 'UNKNOWN';
    final color = _verdictColor(verdict);
    final icon = _verdictIcon(verdict);

    return GlassCard(
      borderColor: color.withValues(alpha: 0.5),
      child: Column(children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Text('Carbon Credit: $verdict',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 12),

        // Reason
        Text(cc['verdict_reason']?.toString() ?? '',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center),
        const SizedBox(height: 14),

        // Stats row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _statColumn('Annual CO₂', '${_safeDiv(cc['annual_emissions_kg'], 1000)} t', Icons.cloud, color),
            Container(width: 1, height: 40, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            _statColumn('Position', _trimNetPosition(cc['net_position']?.toString() ?? '—'), Icons.swap_vert, color),
            Container(width: 1, height: 40, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            _statColumn('Offset Cost', _trimOffsetCost(cc['offset_cost']?.toString() ?? '—'), Icons.payments, color),
          ]),
        ),
        const SizedBox(height: 16),
        
        // "Get Verified" CTA
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showGetVerifiedBottomSheet(context),
            child: const Text('Get a Real Assessment →', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCreditOpportunities(Map<String, dynamic> cc) {
    final opps = cc['credit_opportunities'];
    if (opps == null || opps is! List || opps.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      borderColor: AppTheme.lime.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bolt, color: AppTheme.lime, size: 20),
          SizedBox(width: 6),
          Text('Carbon Credit Opportunities', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        const Text('Ways your business can generate or earn carbon credits',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        ...opps.map<Widget>((opp) {
          final o = opp as Map<String, dynamic>;
          final potentialCreditsRaw = o['potential_credits'];
          final num potentialCredits = (potentialCreditsRaw is num) ? potentialCreditsRaw : double.tryParse(potentialCreditsRaw.toString()) ?? 0;
          final isBiochar = o['type']?.toString().toLowerCase().contains('biochar') ?? false;

          Widget warningChip;
          if (potentialCredits < 50) {
            warningChip = _alertChip("⚠️ Too small for any carbon market. Focus on cost savings instead.", Colors.red);
          } else if (potentialCredits < 500) {
            warningChip = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _alertChip("Small project — only viable via aggregator. Solo registration not possible at this scale.", Colors.orange),
              const SizedBox(height: 4),
              const Text("Connect with Varaha (varaha.earth) or Boomitra (boomitra.com) for aggregated farmer/land projects.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10))
            ]);
          } else {
            warningChip = _alertChip("Potentially viable for independent registration. Get a professional assessment.", Colors.green);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lime.withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: AppTheme.lime, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(o['type']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 8),
              warningChip,
              const SizedBox(height: 8),
              Text(o['mechanism']?.toString() ?? '',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _chip(Icons.bar_chart, '$potentialCredits tonnes CO₂e/year'),
                _chip(Icons.currency_rupee, o['estimated_revenue']?.toString() ?? ''),
                _chip(Icons.assignment, o['registry']?.toString() ?? ''),
                _chip(Icons.schedule, o['timeline']?.toString() ?? ''),
                _difficultyChip(o['difficulty']?.toString() ?? ''),
              ]),
              const SizedBox(height: 8),
              const Text("(Estimated. Does not account for ~₹40L–₹4Cr project development and verification costs for independent registration.)",
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
              if (isBiochar) ...[
                const SizedBox(height: 8),
                const Text("Biochar credits (\$100–200/tonne) require a pyrolysis unit (capital cost: ₹15L–₹1Cr), specific temperature-controlled burning, and registration via Puro.earth registry. This is a medium-term opportunity, not immediately actionable.",
                    style: TextStyle(color: AppTheme.warning, fontSize: 11, fontStyle: FontStyle.italic)),
              ]
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildActionPlan(Map<String, dynamic> cc) {
    if (_isLoadingActions) return const SizedBox.shrink();
    if (_actionItems.isEmpty) return const SizedBox.shrink();

    int completedCount = _actionItems.where((i) => i.isCompleted).length;
    double progress = _actionItems.isEmpty ? 0 : completedCount / _actionItems.length;

    Color progressColor;
    if (progress == 1.0) progressColor = Colors.green;
    else if (progress >= 0.33) progressColor = Colors.orange;
    else progressColor = Colors.red;

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.flag, color: Color(0xFF6366F1), size: 20),
            SizedBox(width: 6),
            Text('Carbon Credit Action Plan', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textSecondary),
            tooltip: 'Reset Plan',
            onPressed: _resetActions,
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surface,
                color: progressColor,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('[$completedCount/${_actionItems.length}] completed', style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ..._actionItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: item.isCompleted,
                activeColor: progressColor,
                onChanged: (val) => _toggleAction(item, val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.stepNumber, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.actionText,
                      style: TextStyle(
                        color: item.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary, 
                        fontSize: 13, 
                        height: 1.4,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                  if (item.isCompleted && item.completedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Completed ${item.completedAt!.day}/${item.completedAt!.month}/${item.completedAt!.year}', style: const TextStyle(color: Colors.green, fontSize: 10)),
                    )
                ],
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildIndiaSchemes(Map<String, dynamic> cc) {
    final schemes = cc['india_schemes'];
    if (schemes == null || schemes is! List || schemes.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      borderColor: const Color(0xFFFF9933).withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('\u{1f1ee}\u{1f1f3}', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('Indian Carbon Schemes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        const Text('Government programs relevant to your carbon position',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 12),
        ...(schemes).map<Widget>((s) {
          final scheme = s as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.flag, color: Color(0xFFFF9933), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(scheme['scheme']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(scheme['relevance']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                if (scheme['potential_benefit'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Potential: ${scheme['potential_benefit']}',
                      style: const TextStyle(color: AppTheme.lime, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ])),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildMarketInsight(Map<String, dynamic> cc) {
    final insight = cc['market_insight']?.toString();
    if (insight == null || insight.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.trending_up, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Market Outlook 2025 - 2030',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(insight, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("⚠️ Credit Quality Status", style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Renewable energy (solar/wind) credits are increasingly rejected by ICVCM due to additionality concerns. Focus on nature-based or high-tech removal (like Biochar) for premium pricing.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("Data as of March 2025 • Source: ICVCM & Verra", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════

  Color _verdictColor(String v) {
    switch (v.toUpperCase()) {
      case 'SELLER': return AppTheme.lime;
      case 'BUYER': return const Color(0xFFEF4444);
      case 'BOTH': return const Color(0xFF6366F1);
      default: return AppTheme.textSecondary;
    }
  }

  IconData _verdictIcon(String v) {
    switch (v.toUpperCase()) {
      case 'SELLER': return Icons.trending_up;
      case 'BUYER': return Icons.shopping_cart;
      case 'BOTH': return Icons.swap_horiz;
      default: return Icons.help_outline;
    }
  }

  Widget _statColumn(String label, String value, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]));
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _difficultyChip(String diff) {
    String emoji;
    Color color;
    switch (diff.toLowerCase()) {
      case 'easy': emoji = '🟢'; color = AppTheme.lime; break;
      case 'medium': emoji = '🟡'; color = Colors.amber; break;
      case 'hard': emoji = '🔴'; color = const Color(0xFFEF4444); break;
      default: emoji = '⚪'; color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$emoji $diff', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _alertChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConfidenceBanner(Map<String, dynamic> conf) {
    final score = int.tryParse(conf['score']?.toString() ?? '5') ?? 5;
    final isStandard = conf['is_standard_sector'] == true;
    Color color;
    String title;
    if (score >= 8) { color = Colors.green; title = "High Confidence Analysis"; }
    else if (score >= 5) { color = Colors.orange; title = "Moderate Confidence — Verify with expert"; }
    else { color = Colors.red; title = "Low Confidence — AI has limited data on this business type. Do not rely on these figures."; }
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(conf['reason']?.toString() ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]
          )
        ),
        if (!isStandard)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Text("Your business type is outside common carbon market categories. The estimates below are experimental. Consult a carbon specialist before making any decisions.", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  void _showGetVerifiedBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Next Steps for a Real Carbon Credit Assessment", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _linkRow("Contact BEE (Bureau of Energy Efficiency):", "https://bee.gov.in"),
            const SizedBox(height: 12),
            _linkRow("For voluntary markets: Contact an accredited VVB like SGS, Bureau Veritas, or SCS Global", "https://verra.org/validation-verification"),
            const SizedBox(height: 12),
            _linkRow("For farmer/land projects in India: Varaha Climate or Boomitra aggregate small projects", "https://varaha.earth"),
            const SizedBox(height: 16),
            const Text("• Estimated consultation cost: ₹50,000–₹5,00,000 depending on project size", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            const Text("• Timeline to first credit issuance: 12–24 months", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close", style: TextStyle(color: AppTheme.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("About This Analysis", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("What the AI can and cannot determine:", style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("The AI provides directional estimates based on standard industry averages. It CANNOT certify projects, verify exact footprints, or guarantee carbon credit market access. Real registration requires an accredited third-party audit.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            const Text("How emission factors are sourced:", style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Data is sourced from the India GHG Platform, IPCC AR6, and India BEE PAT Scheme guidelines.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            const Text("MRV (Measurement, Reporting, and Verification):", style: TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("MRV is the rigorous process required by registries (like Verra or Gold Standard) to prove your carbon reduction is real, quantifiable, and permanent. Without MRV, you cannot sell credits.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            _linkRow("BEE India:", "https://beeindia.gov.in"),
            _linkRow("Verra:", "https://verra.org"),
            _linkRow("Gold Standard:", "https://goldstandard.org"),
            _linkRow("ICVCM:", "https://icvcm.org"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close", style: TextStyle(color: AppTheme.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(String text, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: text + " ", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
            TextSpan(text: url, style: const TextStyle(color: Colors.blueAccent, fontSize: 13, decoration: TextDecoration.underline)),
          ]),
        ),
      ),
    );
  }

  String _safeDiv(dynamic val, int divisor) {
    if (val == null) return '—';
    final num = val is int ? val.toDouble() : (val is double ? val : double.tryParse(val.toString()) ?? 0);
    return (num / divisor).toStringAsFixed(1);
  }

  String _trimNetPosition(String s) {
    if (s.contains(':')) return s.split(':').last.trim();
    return s;
  }

  String _trimOffsetCost(String s) {
    final parts = s.split(' ');
    if (parts.length >= 3) return parts.take(3).join(' ');
    return s;
  }

  // ════════════════════════════════════════════════
  //  STATIC FALLBACK (no controller)
  // ════════════════════════════════════════════════

  Widget _buildStaticExchange(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Resource Exchange', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Trade waste into value', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(children: [
                  const Text('🔄', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Cross-sector exchange', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Connect with local businesses\nto share surplus resources', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Text('Available Listings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
                GradientButton(label: '+ Post', onPressed: () {}, width: null),
              ]),
              const SizedBox(height: 12),
              ...exchangeItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(item.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.sector, style: const TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('By ${item.offeredBy}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(item.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.emerald),
                          foregroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Express Interest', style: TextStyle(fontSize: 12)),
                      )),
                    ]),
                  ]),
                ),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
