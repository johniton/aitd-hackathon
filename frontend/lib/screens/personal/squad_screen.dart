import 'package:flutter/material.dart';
import '../../data/static_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key});

  static final _squadMembers = leaderboard.take(4).toList();

  @override
  Widget build(BuildContext context) {
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
                  const Text('588.7 kg', style: TextStyle(color: AppTheme.emerald, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Combined this month', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.emeraldGradient),
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
            GradientButton(label: '+ Invite Friends', onPressed: () {}, icon: Icons.person_add, width: double.infinity),
          ],
        ),
      ),
    );
  }
}
