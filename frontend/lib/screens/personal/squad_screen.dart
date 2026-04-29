import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/app_state.dart';
import '../../data/static_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key});

  static final _squadMembers = leaderboard.take(4).toList();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final squadTotal = _squadMembers.fold(0.0, (sum, u) => sum + u.totalCo2Saved) + user.totalCo2Saved;

    // Member with highest carbon this week gets a dare
    final dareTarget = _squadMembers.reduce((a, b) => a.totalCo2Saved < b.totalCo2Saved ? a : b);

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      appBar: AppBar(
        title: const Text('My Squad'),
        backgroundColor: AppTheme.bg1,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              child: Column(
                children: [
                  const Text('Squad CO₂ Saved', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('${squadTotal.toStringAsFixed(1)} kg', style: const TextStyle(color: AppTheme.emerald, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Combined this month', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekly dare card
            GlassCard(
              borderColor: AppTheme.lime.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text('Weekly Dare', style: TextStyle(color: AppTheme.lime, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dareTarget.name.split(' ').first} has the fewest activities this week.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dare: Try one car-free day this week!',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Share.share('⚡ GoaGreen Dare: ${dareTarget.name.split(' ').first}, try one car-free day this week! Can you beat me? #GoaGreen'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.lime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.lime.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, color: AppTheme.lime, size: 14),
                          SizedBox(width: 6),
                          Text('Send Dare', style: TextStyle(color: AppTheme.lime, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ..._squadMembers.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.emeraldGradient),
                      alignment: Alignment.center,
                      child: Text(u.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('🔥 ${u.streakDays}d  📍 ${u.city}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${u.totalCo2Saved.toStringAsFixed(0)} kg', style: const TextStyle(color: AppTheme.emerald, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            GradientButton(
              label: '+ Invite Friends',
              icon: Icons.person_add,
              width: double.infinity,
              onPressed: () => Share.share('🌿 Join my squad on GoaGreen — we track and cut our carbon footprint together in Goa! Download now: #GoaGreen'),
            ),
          ],
        ),
      ),
    );
  }
}
