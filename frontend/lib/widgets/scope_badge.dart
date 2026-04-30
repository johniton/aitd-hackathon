import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EmissionScope { scope1, scope2, scope3 }

class ScopeBadge extends StatelessWidget {
  final EmissionScope scope;

  const ScopeBadge({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (scope) {
      case EmissionScope.scope1:
        bgColor = AppTheme.surface;
        textColor = AppTheme.textSecondary;
        text = "S1 Direct";
        break;
      case EmissionScope.scope2:
        bgColor = AppTheme.accentIndigo.withValues(alpha: 0.12);
        textColor = AppTheme.accentIndigo;
        text = "S2 Energy";
        break;
      case EmissionScope.scope3:
        bgColor = AppTheme.warning.withValues(alpha: 0.12);
        textColor = AppTheme.warning;
        text = "S3 Value Chain ⚠️";
        break;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );

    if (scope == EmissionScope.scope3) {
      return Tooltip(
        message: "Scope 3 emissions are from activities outside your direct control. You generally CANNOT generate carbon credits from Scope 3 reductions. These are included for your awareness only.",
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        textStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
        child: badge,
      );
    }

    return badge;
  }
}
