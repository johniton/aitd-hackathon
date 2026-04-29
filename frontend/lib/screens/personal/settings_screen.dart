import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  bool _shareDataConsent = true;
  bool _weeklyDigest = true;
  bool _dareNotifications = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _nameCtrl = TextEditingController(text: user.name);
    _cityCtrl = TextEditingController(text: user.city);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      context.read<AppState>().updateProfile(name: _nameCtrl.text.trim(), city: _cityCtrl.text.trim());
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.emerald, content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg1,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Profile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    _Field(label: 'Display Name', controller: _nameCtrl, icon: Icons.person_outline),
                    const Divider(color: AppTheme.surface, height: 24),
                    _Field(label: 'City', controller: _cityCtrl, icon: Icons.location_city_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Notifications', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    _Toggle(
                      label: 'Weekly Digest',
                      subtitle: 'Your carbon summary every Monday',
                      value: _weeklyDigest,
                      onChanged: (v) => setState(() => _weeklyDigest = v),
                    ),
                    const Divider(color: AppTheme.surface, height: 1),
                    _Toggle(
                      label: 'Squad Dares',
                      subtitle: 'Get notified when a dare is sent your way',
                      value: _dareNotifications,
                      onChanged: (v) => setState(() => _dareNotifications = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Privacy', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 8),
              GlassCard(
                child: _Toggle(
                  label: 'Share anonymised data',
                  subtitle: 'Help improve Goa\'s city-wide carbon insights',
                  value: _shareDataConsent,
                  onChanged: (v) => setState(() => _shareDataConsent = v),
                ),
              ),
              const SizedBox(height: 24),

              GradientButton(
                label: _saving ? 'Saving...' : 'Save Changes',
                icon: Icons.check,
                width: double.infinity,
                onPressed: _saving ? () {} : _save,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showSignOutDialog(context),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Sign Out', style: TextStyle(color: AppTheme.warning, fontSize: 15))),
                      Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _Field({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: AppTheme.emerald,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.emerald,
            activeTrackColor: AppTheme.emerald.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textSecondary,
            inactiveTrackColor: AppTheme.surface,
          ),
        ],
      ),
    );
  }
}
