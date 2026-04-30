import 'package:flutter/material.dart';
import '../../data/static_data.dart';
import '../../services/tourism_engine_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../data/subsidy_database.dart';
import 'package:url_launcher/url_launcher.dart';

class SubsidyScreen extends StatelessWidget {
  final TourismEngineController? tourismController;
  const SubsidyScreen({super.key, this.tourismController});

  @override
  Widget build(BuildContext context) {
    if (tourismController != null) {
      return AnimatedBuilder(
        animation: tourismController!,
        builder: (_, __) {
          final matches = tourismController!.subsidyMatches();
          final eligible = matches.where((m) => m.isEligible).toList();
          final total = eligible.fold<int>(0, (sum, item) {
            final number = int.tryParse(item.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return sum + number;
          });
          return Scaffold(
            backgroundColor: AppTheme.bg1,
            body: Container(
              decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Smart Subsidy Engine', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Text(
                        '₹${total.toString()} eligible based on emissions, waste type, and tourism profile',
                        style: const TextStyle(color: AppTheme.emerald, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...matches.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            borderColor: s.isEligible ? AppTheme.emerald.withValues(alpha: 0.4) : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(s.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(s.amount, style: const TextStyle(color: AppTheme.lime, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                GradientButton(
                                  label: s.isEligible ? 'Apply Now' : 'Track Eligibility',
                                  onPressed: () {
                                    if (s.isEligible && tourismController != null) {
                                      _showApplyDialog(context, s.title, tourismController!);
                                    }
                                  },
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Govt Subsidies', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Matched to your profile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.emerald),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2 subsidies eligible', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('Total available: ₹1,70,000', style: TextStyle(color: AppTheme.emerald, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...subsidies.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: s.isEligible ? AppTheme.emerald.withValues(alpha: 0.4) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: s.isEligible ? AppTheme.emerald.withValues(alpha: 0.15) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.isEligible ? '✅ Eligible' : '❌ Not eligible',
                              style: TextStyle(color: s.isEligible ? AppTheme.emerald : AppTheme.textSecondary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(s.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoChip('💰', s.amount),
                          const SizedBox(width: 8),
                          _InfoChip('📅', 'Deadline: ${s.deadline}'),
                        ],
                      ),
                      if (s.isEligible) ...[
                        const SizedBox(height: 12),
                        GradientButton(label: 'Apply Now', onPressed: () {
                          if (tourismController != null) {
                            _showApplyDialog(context, s.title, tourismController!);
                          }
                        }, width: double.infinity),
                      ],
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
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
                const DisclaimerBanner(disclaimerKey: 'subsidy_apply_disclaimer_screen'),
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
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: AppTheme.bg1),
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

class _InfoChip extends StatelessWidget {
  final String emoji;
  final String text;
  const _InfoChip(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
