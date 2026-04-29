import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'settings_screen.dart';
import 'squad_screen.dart';
import 'wrapped_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final badges = state.earnedBadges;

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.emeraldGradient),
                      alignment: Alignment.center,
                      child: Text(user.avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('📍 ${user.city}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('#${user.rank}', style: const TextStyle(color: AppTheme.emerald, fontSize: 20, fontWeight: FontWeight.w800)),
                        const Text('city rank', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatBox('🌿', '${user.totalCo2Saved.toStringAsFixed(0)} kg', 'CO₂ Saved')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox('🪙', '${user.greenCoins.toInt()}', 'GreenCoins')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox('🔥', '${user.streakDays}d', 'Streak')),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Badges', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GlassCard(
                child: badges.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Log activities to earn badges!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: badges.map((b) => _Badge(b.emoji, b.label)).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              const Text('Quick Links', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _NavTile(Icons.group, 'My Squad', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadScreen()))),
              _NavTile(Icons.auto_awesome, 'My Wrapped', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrappedScreen()))),
              _NavTile(Icons.settings, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              _NavTile(Icons.logout, 'Sign Out', () => Navigator.popUntil(context, (r) => r.isFirst), danger: true),
            ],
          ),
        ),
      ),
    );
  }
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
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String emoji;
  final String label;
  const _Badge(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600)),
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
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 15))),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
