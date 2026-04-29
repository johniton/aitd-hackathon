import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.emerald;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w700)),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
