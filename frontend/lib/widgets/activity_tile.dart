import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ActivityTile extends StatelessWidget {
  final ActivityModel activity;

  const ActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = activity.isSaving ? AppTheme.emerald : AppTheme.warning;
    final sign = activity.isSaving ? '-' : '+';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(activity.categoryIcon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(activity.analogy, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${activity.co2Kg.toStringAsFixed(2)} kg',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                _timeAgo(activity.timestamp),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
